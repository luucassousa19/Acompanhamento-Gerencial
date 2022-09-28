libname RMBACNF "/install/SASConfig/Lev1/AppData/SASIRM/pa/fas/fa.sbrlus/landing_area/configurations/rmbalm5.1.2_eba_281_201906/rd_conf";
libname rmbarslt "/install/SASConfig/Lev1/AppData/SASIRM/pa/data/1232114868/rmbarslt";
libname rmbastg "/install/SASConfig/Lev1/AppData/SASIRM/pa/fas/fa.sbrlus/input_area/07312019/";
/*=-=-=-=-=-=-=-=-=-=-=-=-==-=--=-=-=-= Part 1 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/
/*************CÓDIGO CROSSCLASS LUANA******************/
/* Start - Cross Classification variable list */
data crossclass;
set rmbastg.nevscen_analysis_option;
where CONFIG_NAME='CCV_LIST';
keep CONFIG_VALUE;
run;

data custom_crossclass(keep=n new rename=new=config_value);
length n 8.;
length new $32.;
set crossclass;
do i=1 by 1 while(scan(config_value,i,' ') ^=' ');
n=i;
new=scan(config_value,i,' ');
output;
end;
run;

proc sql noprint;
select max(n) into :qtyVariables from custom_crossclass;
run;

data allprice_imported;
set rmbarslt.ALLPRICE;
run;

%macro filter_crossclass;

%let i=0;
%do i = 1 %to &qtyVariables;

proc sql;
select config_value into: config_value
from custom_crossclass
where n=&i;
quit;

data allprice_imported;
set allprice_imported;
where &config_value <>'+';
run;

%end;

%mend filter_crossclass;

%filter_crossclass;

/* End - Cross Classification variable list; */

/*-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=- Tabela 1-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
/* data tabela1(keep= InstID PRIMITIVE_RF  AnalysisName VALUE); */
/* set rmbarslt.ALLPRICE; */
/* run; */
/*  */
/* data tabela2(keep= TIME_GRID_ID TIME_BUCKET_SEQ_NBR TIME_BUCKET_END_UOM_NO); */
/* set rmbacnf.time_grid_bucket; */
/* where TIME_GRID_ID='BACEN'; */
/* run; */

/*-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=- Tabela vazia-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */
data allprice_inicial;
format BaseDate NLDATE20.
vertex 10.
ResultName $32. 
VALUE 8.
PRIMITIVE_RF $32.
x_br_cfdisc NLNUM16.2
product_type $32. 
altype $32.;
stop;
run;
/* ****************Fim************ */

data nevscen_analysis_option;
set rmbastg.nevscen_analysis_option(where=(CONFIG_NAME = 'TIMEGRID'));
call symputx('CONFIG_VALUE',CONFIG_VALUE);
run;

/* proc sql noprint; */
/* select max(time_bucket_seq_nbr) into :max from rmbacnf.time_grid_bucket where TIME_GRID_ID="&CONFIG_VALUE."; */
/* quit; */

proc sql;
select max(time_bucket_seq_nbr) into :max from rmbacnf.time_grid_bucket where TIME_GRID_ID="&CONFIG_VALUE.";
quit;

%put &CONFIG_VALUE.;
%put &max.;

%macro vertices;

%let i=0;
%do i = 1 %to &max.;

proc sql;
select time_bucket_end_uom_no into: time_bucket_end_uom_no
from rmbacnf.time_grid_bucket
where time_bucket_seq_nbr=&i and TIME_GRID_ID='BACEN';
quit;

data custom_ALLPRICE(keep= BaseDate ResultName vertex InstID PRIMITIVE_RF VALUE x_br_cfdisc product_type altype);
set allprice_imported;
vertex=&time_bucket_end_uom_no;
x_br_cfdisc=X_BR_CFDISC_&i;
rename AnalysisName = ResultName;
rename _date_ = BaseDate;
run;

proc  append base=allprice_inicial  data=custom_ALLPRICE force nowarn;
run;

%end;

%mend vertices;

%vertices;

/*=-=-=-=-=-=-=-=-=-=-=-=-==-=--=-=-=-= SEGREGACAO =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/
proc sql;
	create table allprice_inicial_V2 as
	select t1.*,
	CASE when ResultName contains 'rel_' then 'Multiplicativo'
	     else 'Aditivo'
	     end as FatorMA	
	from allprice_inicial as t1
	where ResultName contains '_up_' or ResultName contains 'BASECASE'
;quit;

data allprice_inicial_V3;
set allprice_inicial_V2;
Taxa1 = 'Taxa x';
Taxa2 = 'Taxa +';
/* Resultname2= scan(compress(ResultName,'','kd'),1,''); */
if Resultname = 'BASECASE' then Resultname2 = Resultname;
else Resultname2= scan(compress(ResultName,'','kd'),1,'');
/* drop ResultName; */
run;

data allprice_inicial_V4;
set allprice_inicial_V3;
if Resultname2 = '25' then Resultname2 = 25/10;
run;

data allprice_inicial_V5;
set allprice_inicial_V4;
TipoFator = input(ResultName2,4.);
if FatorMA = 'Multiplicativo' then ResultName = cats(catx(' ',Taxa1,ResultName2),'%');
else ResultName = cats(catx(' ',Taxa2,ResultName2),'%');
VariavelTex = 'Var. MtM R$ mil';
drop ResultName2 Taxa1 Taxa2;
run;

data allprice_inicial_V6;
set allprice_inicial_V5;
if Resultname = 'Taxa + BASECASE%' then Resultname = 'BASECASE';
else Resultname = Resultname;
drop InstID;
run;

DATA allprice_final;
SET allprice_inicial_V6;
IF vertex <= 252 THEN ZONA = 'ZONA1'; ELSE
IF vertex >= 378 AND vertex <= 756 THEN ZONA = 'ZONA2'; ELSE
IF vertex >= 1008 AND vertex <= 1260 THEN ZONA = 'ZONA3'; ELSE
IF vertex >= 2520 AND vertex <= 7560 THEN ZONA = 'ZONA4';
RUN;





















































/* -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=   parte 2 -=---=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-= */
/* ****************Campos necessários*********** */
/* data camposallprice (keep= InstID ResultName BaseDate VALUE); */
/* set alpha.allprice1; */
/* rename  _date_ = BaseDate; */
/* rename AnalysisName = ResultName; */
/* run; */
/*  */
/* proc sql; */
/* 	create table camposallpricefim as */
/* 	select distinct ResultName, sum(VALUE) AS Valor, BaseDate */
/* 	from camposallprice */
/* 	group by 1 */
/* ;quit; */
/*  */
/*  */
/* data camporvertices (keep=TIME_BUCKET_SEQ_NBR TIME_BUCKET_END_UOM_NO BaseDate); */
/* set rmbacnf.time_grid_bucket; */
/* BaseDate = "31JUL19"d; */
/* Format BaseDate Date9.; */
/* where */
/* TIME_GRID_ID = "RPTVERTEX"; */
/* run; */
/*  */
/* *******************UNIÃO TABELAS*************** */
/* proc sql; */
/* 	create table uniao_table2 as */
/* 	select distinct t1.*,t2.TIME_BUCKET_SEQ_NBR, t2.TIME_BUCKET_END_UOM_NO as vertex */
/* 	from camposallpricefim as t1 */
/* 	inner join camporvertices as t2 */
/* 	on t1.BaseDate = t2.BaseDate */
/* 	where t1.ResultName contains '_up_' or t1.ResultName contains 'BASECASE'	 */
/* ;quit; */
/*  */
/* *****Calculo valor - basecase******* */
/* ******basecase***** */
/* data teste234; */
/* set uniao_table2; */
/* where ResultName = "BASECASE"; */
/* run; */
/*  */
/* ******rel_*****tabela1  */
/* proc sql; */
/* 	create table teste2345 as */
/* 	select * */
/* 	from uniao_table2 as t1 */
/*    	where t1.ResultName contains '_up_' */
/* ;quit; */
/*  */
/* proc sql; */
/* create table uniao123 as */
/* select t1.*, t2.Valor as BASECASE */
/* from teste2345 as t1 */
/* left join teste234 as t2 */
/* on t1.TIME_BUCKET_SEQ_NBR = t2.TIME_BUCKET_SEQ_NBR and t1.BaseDate = t2.BaseDate */
/* and T1.vertex = t2.vertex */
/* ;quit; */
/*  */
/*  */
/* data teste23456; */
/* set uniao123; */
/* VariavelTex = 'Var. MtM R$ mil'; */
/* x_br_cfdisc = Valor-BASECASE; */
/* run; */
/*  */
/* proc sql; */
/* 	create table tabela1 as */
/* 	select t1.*,  */
/* 	case when t1.ResultName contains 'rel_' then 'Multiplicativo' */
/* 	     else 'Aditivo' */
/* 	end as FatorMA	 */
/* 	from teste23456 as t1 */
/* 	group by 1,2 */
/* ;quit; */
/*  */
/* data compress_string_cal2; */
/* set tabela1 ; */
/* Taxa1 = 'Taxa x'; */
/* Taxa2 = 'Taxa +'; */
/* Resultname2= scan(compress(ResultName,'','kd'),1,''); */
/* drop ResultName; */
/* run; */
/*  */
/* data taxasnovo_cal2 (KEEP= BaseDate FatorMA ResultName TIME_BUCKET_SEQ_NBR vertex Valor  */
/* VariavelTex BASECASE x_br_cfdisc); */
/* set compress_string_cal2; */
/* TipoFator = input(ResultName2,4.); */
/* if FatorMA = 'Multiplicativo' then ResultName = cats(catx(' ',Taxa1,ResultName2),'%'); */
/* else ResultName = cats(catx(' ',Taxa2,ResultName2),'%'); */
/* VariavelTex = 'Var. MtM R$ mil'; */
/* drop ResultName2 Taxa1 Taxa2; */
/* run; */
/*  */
/* DATA TABELA2GRP19; */
/* SET taxasnovo_cal2; */
/* IF vertex <= 252 THEN ZONA = 'ZONA1'; ELSE */
/* IF vertex >= 378 AND vertex <= 756 THEN ZONA = 'ZONA2'; ELSE */
/* IF vertex >= 1008 AND vertex <= 1260 THEN ZONA = 'ZONA3'; ELSE */
/* IF vertex >= 2520 AND vertex <= 7560 THEN ZONA = 'ZONA4'; */
/* RUN; */
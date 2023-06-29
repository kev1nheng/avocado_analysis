/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Sunday, 18 April 2021     TIME: 7:37:10 pm
PROJECT: avocado
PROJECT PATH: C:\Users\galax\Desktop\avocado\avocado.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=PNG;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///D:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: Avocado_Month   */
%LET _CLIENTTASKLABEL='Avocado_Month';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='C:\Users\galax\Desktop\avocado\avocado.egp';
%LET _CLIENTPROJECTPATHHOST='DESKTOP-IC1MEGN';
%LET _CLIENTPROJECTNAME='avocado.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;

/* Code needed to monthly aggregation */

proc sql;
create table avocado_t as
select Date, mean(Total_Volume) as Total_Volume,
mean(_4046) as small_size, mean(_4225) as large_size,
mean(_4770) as xlarge_size,
mean(Total_Bags) as Total_Bags, 
mean(Small_Bags) as Small_Bags,
mean(Large_Bags) as Large_Bags, mean(XLarge_Bags) as XLarge_Bags
from work.avocado
group by Date;
quit;

data work.avocado_t;
set work.avocado_t;
Q = qtr(Date);
Y = year(Date);
M = month(Date);
D = day(Date);
quarter = Date;
week = Date;
format Date date9.;
format week weekw.;
format quarter yyq.;
run;


/* SQL code to aggregate in month, I had to export manually in excel to combime them */
proc sql;
create table avocado_t01 as
select M, mean(Total_Volume) as Total_Volume,
mean(small_size) as small_size, mean(large_size) as large_size,
mean(xlarge_size) as xlarge_size,
mean(Total_Bags) as Total_Bags, 
mean(Small_Bags) as Small_Bags,
mean(Large_Bags) as Large_Bags, mean(XLarge_Bags) as XLarge_Bags
from work.avocado_t  
where Y = 2015
group by M;
quit;

proc sql;
create table avocado_t02 as
select M, mean(Total_Volume) as Total_Volume,
mean(small_size) as small_size, mean(large_size) as large_size,
mean(xlarge_size) as xlarge_size,
mean(Total_Bags) as Total_Bags, 
mean(Small_Bags) as Small_Bags,
mean(Large_Bags) as Large_Bags, mean(XLarge_Bags) as XLarge_Bags
from work.avocado_t  
where Y = 2016
group by M;
quit;

proc sql;
create table avocado_t03 as
select M, mean(Total_Volume) as Total_Volume,
mean(small_size) as small_size, mean(large_size) as large_size,
mean(xlarge_size) as xlarge_size,
mean(Total_Bags) as Total_Bags, 
mean(Small_Bags) as Small_Bags,
mean(Large_Bags) as Large_Bags, mean(XLarge_Bags) as XLarge_Bags
from work.avocado_t  
where Y = 2017
group by M;
quit;

proc sql;
create table avocado_t04 as
select M, mean(Total_Volume) as Total_Volume,
mean(small_size) as small_size, mean(large_size) as large_size,
mean(xlarge_size) as xlarge_size,
mean(Total_Bags) as Total_Bags, 
mean(Small_Bags) as Small_Bags,
mean(Large_Bags) as Large_Bags, mean(XLarge_Bags) as XLarge_Bags
from work.avocado_t  
where Y = 2018
group by M;
quit;

proc sql;
create table avocado_2018 as
select 2018 as Year,M as Month,small_size, large_size, xlarge_size,Total_Bags, Small_Bags,XLarge_Bags
from work.avocado_t04;
quit;

proc sql;
create table avocado_2017 as
select 2017 as Year,M as Month,small_size, large_size, xlarge_size,Total_Bags, Small_Bags,XLarge_Bags
from work.avocado_t03;
quit;


proc sql;
create table avocado_2016 as
select 2016 as Year,M as Month,small_size, large_size, xlarge_size,Total_Bags, Small_Bags,XLarge_Bags
from work.avocado_t02;
quit;

proc sql;
create table avocado_2015 as
select 2015 as Year,M as Month,small_size, large_size, xlarge_size,Total_Bags, Small_Bags,XLarge_Bags
from work.avocado_t01;
quit;

proc sort data=work.avocado_2015;
 by Year;
 run;

 proc sort data=work.avocado_2016;
 by Year;
 run;

 proc sort data=work.avocado_2017;
 by Year;
 run;

  proc sort data=work.avocado_2018;
 by Year;
 run;

 proc print data=avocado_2015;
 run;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;

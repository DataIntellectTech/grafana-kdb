//forming table of requests from Grafana to parse, evaluate, reformat and push to Grafana

.t.tab:([] time:.z.p; qry:enlist "starting table");					/ initialiase table

 // takes in Grafana HTTP POST request
.z.pp:{
  rqt:.j.k 6_first x;									/ convert request from json
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];				/ avoid type error for zero length query
  rqtype:raze rqt[`targets]`type;							/ type of request			
  `.t.tab upsert (.z.p;raze rqt[`targets]`target);					/ insert request into table
  .t.rsp:$[rqtype like "timeserie";tsfunc[rqt];
           rqtype like "table";[tabname:value last .t.tab `qry;tbfunc[tabname]];
          `NA];										/ conditional for format of json given query type
  :.h.hy[`json] .t.rsp;									/ send response
 };

 // make requested table data in json format
tbfunc:{[tablename]
  types:(10;5;6;7;8;9)!`string,5#`number;						/ basic dict of kdb to json datatypes
  colName:key flip tablename;								/ get column headers
  colType:types[`long$type each tablename[colName]];					/ get column json datatypes
  rowNum:count tablename;								/ get number of rows
  dict:flip `text`type!(();());								/ initialise column name,type table
  finalDict:enlist[`columns]!{x,:y;x}\[dict;enlist colName,'colType];			/ form general column data needed for response
  finalDict:finalDict,enlist[`rows]!enlist {value x z}[tablename]\[();til rowNum];	/ append general row data needed for response
  :.j.j enlist finalDict,enlist[`type]!enlist `table;					/ add data type and convert to json
 };

 // make requested timeseries data in json format
tsfunc:{[x]
  epo:floor abs(`long$1970.01.01D00:00:00.000)%1000000;					/ find milliseconds between 1970 and 2000
  f:floor epo+(`long$"P"$-1_x[`range]`from)%1000000;					/ start time in ms
  t:floor epo+(`long$"P"$-1_x[`range]`to)%1000000;					/ end time in ms
  tablename:first`$"." vs raze last .t.tab `qry;					/ extract queried tablename
  sym:(`$"."vs raze last .t.tab `qry) 1;						/ extract queried sym
  if[12h<>type exec time from tablename;tablename:update time:.z.D+time from tablename]; / if no date then use todays date 
  update msec:floor epo +(`long$time)%1000000 from tablename;				/ join timestamp in ms 
  colName:(2_raze`$"." vs raze last .t.tab `qry) cross `msec;				/ extract queried columns
  :.j.j {[f;t;s;d;y] d,:enlist[`target]!enlist y 0;					/ form general json response
    d,enlist[`datapoints]!enlist value each 
    ?[tablename;enlist((within;`msec;(enlist;f;t));(=;`sym;enlist[s]));0b;y!y]}
    [f;t;sym]\[();colName];
 };

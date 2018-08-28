//forming table of requests from Grafana to parse, evaluate, reformat and push to Grafana
.grafana.tab:([] time:.z.p; qry:enlist "starting table");					/ initialiase table

 // takes in Grafana HTTP POST request
.z.pp:{
  rqt:.j.k 6_first x;									/ convert request from json
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];				/ avoid type error for zero length query
  rqtype:raze rqt[`targets]`type;							/ type of request			
  `.grafana.tab upsert (.z.p;raze rqt[`targets]`target);					/ insert request into table
  if[rqtype~"timeserie";.grafana.rsp:tsfunc rqt];
  if[rqtype~"table";.grafana.rsp:tbfunc value last .grafana.tab`qry];	/ conditional for format of json given query type
  :.h.hy[`json] .grafana.rsp;									/ send response
 };

 // make requested table data in json format
tbfunc:{[rqt]
  types:10 5 6 7 8 9h!`string,5#`number;						/ basic dict of kdb to json datatypes
  colName:cols rqt;								/ get column headers
  colType:types type each rqt colName;					/ get column json datatypes
  finalDict:enlist[`columns]!{x,:y;x}\[flip`text`type!();enlist colName,'colType];	/ form general column data needed for response
  finalDict,:enlist[`rows]!enlist {value x z}[rqt]\[();til count rqt];	/ append general row data needed for response
  :.j.j enlist finalDict,enlist[`type]!enlist `table;					/ add data type and convert to json
 };

 // make requested timeseries data in json format
tsfunc:{[rqt]
  epo:946684800000;					/ find milliseconds between 1970 and 2000
  mil:{floor epo+(`long$"P"$-1_x[`range]y)%1000000}[rqt];
  qy:`$"." vs raze last .grafana.tab `qry;
  tab:qy 0; sym:qy 1;					/ extract queried tablename
  if[12h<>type exec time from tab; tab:update time:.z.D+time from tab]; / if no date then use todays date 
  update msec:floor epo +(`long$time)%1000000 from `tab;				/ join timestamp in ms 
  colName:(2_raze qy) cross `msec;
  build:{[s;d;y]
    d,:enlist[`target]!enlist y 0;
    d,enlist[`datapoints]!enlist value each 
      ?[tablename;enlist((within;`msec;(enlist;mil`from;mil`to));(=;`sym;enlist[s]));0b;y!y]
   };
  :.j.j build[f;t;sym]\[();colName];
 };

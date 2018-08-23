//forming table of requests from Grafana to parse, evaluate, reformat and push to Grafana

.t.tab:([] time:.z.p; qry:enlist "starting table");						/ initialiase table

 // takes in Grafana HTTP POST request
.z.pp:{
  rqt:.j.k 6_first x;										/ convert request from json
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];					/ avoid type error for zero length query
  rqtype:raze rqt[`targets]`type;								/ type of request			
  `.t.tab upsert (.z.p;raze rqt[`targets]`target);						/ insert request into table
  tabname:value last .t.tab `qry;								/ retreive table name
  .t.rsp:$[rqtype like "timeserie";tsfunc[tabname];rqtype like "table";tbfunc[tabname];`nO];	/ conditional for format of json given query type
  :.h.hy[`json] .t.rsp;										/ send response
 };

 // make requested table data in json format
tbfunc:{[tablename]
  types:(10;5;6;7;8;9)!`string,5#`number;							/ basic dict of kdb to json datatypes
  colName:key flip tablename;									/ get column headers
  colType:types[`long$type each tablename[colName]];						/ get column json datatypes
  rowNum:count tablename;									/ get number of rows
  dict:flip `text`type!(();());									/ initialise column name,type table
  finalDict:enlist[`columns]!{x,:y;x}\[dict;enlist colName,'colType];				/ form general column data needed for response
  finalDict:finalDict,enlist[`rows]!enlist {value x z}[tablename]\[();til rowNum];		/ append general row data needed for response
  :.j.j enlist finalDict,enlist[`type]!enlist `table;						/ add data type and convert to json
 };

tsfunc:{[tablename]  										/Place holder for time series funct
  
  /:.j.j enlist
 };


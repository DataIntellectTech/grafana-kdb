//forming table of requests from Grafana to parse, evaluate, reformat and push to Grafana
.grafana.tab:([] time:.z.p; qry:enlist "starting table");					/initialiase table

// takes in Grafana HTTP POST request
.z.pp:{
  rqt:.j.k 6_first x;										/convert request from json,6_ removes API url type WILL DEVELOP IN LATER CODE
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];					/avoid type error for zero length query
  rqtype:raze rqt[`targets]`type;								/type of request, timeseries or table
  `.grafana.tab upsert (.z.p;raze rqt[`targets]`target);					/insert request into table
  if[rqtype~"timeserie";rsp:tsfunc rqt];							/conditional for format of json given query type
  //if[rqtype~"table";rsp:tbfunc value last .grafana.tab`qry];
  if[rqtype~"table";rsp:tbfunc rqt];

  :.h.hy[`json] rsp;										/send response
 };

// make requested table data in json format
tbfunc:{[rqt]
  types:10 5 6 7 8 9h!`string,5#`number;							/basic dict of kdb to json datatypes
  f:"P"$-1_rqt[`range]`from;t:"P"$-1_rqt[`range]`to;
  rqt:value last .grafana.tab`qry;
  if[12h<>type exec time from rqt;rqt:update time:.z.D+time from rqt];
  rqt:select from rqt where time within (f;t);
  colName:cols rqt;										/get column headers
  colType:types type each rqt colName;								/get column json datatypes
  :.j.j enlist `columns`rows`type!								/format into json
    (flip`text`type!(colName;colType);value'[rqt]til count rqt;`table);				/build contents of json responsee
 };

// make requested timeseries data in json format
tsfunc:{[rqt]
  mil:{floor 946684800000+(`long$"P"$-1_x[`range]y)%1000000}[rqt];				/function to change to milliseconds since 1970
  qy:`$"." vs raze last .grafana.tab `qry;							/seperate elements of query by . delimeter
  tab:qy 0;											/extract queried tablename
  if[12h<>type exec time from tab; tab:update time:.z.D+time from tab]; 			/if no date then use todays date
  update msec:floor 946684800000+(`long$time)%1000000 from tab;					/join timestamp in ms
  colName:(2_raze qy) cross `msec;								/json response column formatting
  tab:select from tab where msec within (mil`from;mil`to),sym=qy[1];				/reduce table to specified sym and time range
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};					/build contents of json response
  :.j.j build[tab]\[();colName];								/format back into json
 };

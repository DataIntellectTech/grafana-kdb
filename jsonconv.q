.gkdb.tab:([] time:.z.p; qry:enlist "starting table");
.gkdb.timeCol:`time;
.gkdb.types:types:10 5 6 7 8 9h!`string,5#`number;
.gkdb.epoch:946684800000;

// wrapper if user has custom .z.pp
.old.zpp:@[{.z.pp};" ";{".z.pp not defined"}];
.z.pp:{$["X-Grafana-Org-Id"~string last key last x; zpp x;.old.zpp x]};

// return alive response for GET requests
.z.ph:{.h.hy[`json] .j.j "200 OK"};

// retrieve Grafana HTTP POST request,store in table and process as either timeseries or table
zpp:{
  // get query type from request
  r:" " vs first x;
  rqt:.j.k r 1;
  $["query"~r 0;query rqt;"search"~r 0;search rqt;`NO]
 };

query:{[rqt]  
  // ignore requests while typing
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  `.gkdb.tab upsert (.z.p;raze rqt[`targets]`target);
  //if[rqtype~"timeserie";rsp:tsfunc rqt];
  if[rqtype~"table";rsp:tbfunc value last .gkdb.tab`qry];
  :.h.hy[`json] rsp;
 };

search:{[rqt] :.h.hy[`json] .j.j tables[];};

// process a table request and return in Json format
tbfunc:{[rqt]
  // get column names and associated types to fit format
  colName:cols rqt;
  colType:.gkdb.types type each rqt colName;
  // build body of response in Json adaptor schema
  :.j.j enlist `columns`rows`type!(flip`text`type!(colName;colType);value'[rqt]til count rqt;`table);
 };

//WILL BE REBUILT IN DROP DOWN FORMAT
/
// process a timeseries request and output the respose in valid Json format
tsfunc:{[rqt]
  // conversion to milliseconds since 1970 (to allign with grafana)
  mil:{floor .gkdb.epoch+(`long$"P"$-1_x[`range]y)%1000000}[rqt];
  // elements seperated in format: tableName.sym.columns
  qy:`$"." vs raze last .gkdb.tab `qry;
  tab:qy 0;
  // default to todays date if one not in table  //DONT FORGET TO DO ERROR TRAP AND FS
  if[12h<>type exec time from tab; tab:update time:.z.D+time from tab];
  update msec:floor .gkdb.epoch+(`long$time)%1000000 from tab;
  // Form json format with columns and rows seperated
  colName:(2_raze qy) cross `msec;
  tab:select from tab where msec within (mil`from;mil`to),sym=qy[1];
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[tab]\[();colName];
 };
\

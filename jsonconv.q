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
zpp:{.tmp.x:x;
  // get API url from request
  r:" " vs first x;
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`NO]
 };

query:{[rqt]
  // ignore requests while typing
  if[not `targets in key rqt;-1 " "sv string key rqt;:()];
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  `.gkdb.tab upsert (.z.p;raze rqt[`targets]`target);
  if[rqtype~"timeserie";rsp:tsfunc[rqt;last .gkdb.tab`qry]];
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

tsfunc:{[x;rqt]
  args:`$"."vs rqt;
  rqt:value first args 1;
  colN:cols rqt;
  mil:{floor .gkdb.epoch+(`long$"P"$-1_x[`range]y)%1000000}[x];
  if[12h<>type exec time from rqt;rqt:![rqt;();0b;enlist[.gkdb.timeCol]!enlist (+;.z.D;.gkdb.timeCol)]];
  rqt:![rqt;();0b;enlist[`msec]!enlist(_:;(+;946684800000;(%;($;enlist[`long];.gkdb.timeCol);1000000)))];
  rqt:?[rqt;enlist (within;`msec;(enlist;mil`from;mil`to));0b;()];  
  
  $[(2<count args) and `g~first args 0;[show 0; graphsym[x;colN;rqt]];
      (2<count args) and `t~first args 0; [show 1;tablesym[x;colN;rqt]];
      (2=count args) and `g~first args 0; [show 2;graphnosym[x;colN;rqt]];
      (2=count args) and `t~first args 0; [show 3;tablenosym[x;colN;rqt]];
     `Wronginput
     ]
 };

graphnosym:{[x;colN;rqt]
  colName:colN cross `msec;
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

tablenosym:{[x;colN;rqt]
  colType:.gkdb.types type each rqt colN;
  :.j.j enlist `columns`rows`type!(flip`text`type!(colN;colType);value'[rqt]til count rqt;`table);
  };

graphsym:{[x;colN;rqt]

 };

tablesym:{[x;colN;rqt]

 };

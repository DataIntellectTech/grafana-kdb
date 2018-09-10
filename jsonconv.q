.gkdb.tab:([] time:.z.p; qry:enlist "starting table");
.gkdb.timeCol:`time;
.gkdb.types:types:10 5 6 7 8 9h!`string,5#`number;
.gkdb.epoch:946684800000;

// wrapper if user has custom .z.pp
.old.zpp:@[{.z.pp};" ";{".z.pp not defined"}];
.z.pp:{$[(`$"X-Grafana-Org-Id")in key last x;zpp;.old.zpp]x};

// return alive response for GET requests
.old.zph:.z.ph;
.z.ph:{$[(`$"X-Grafana-Org-Id")in key last x;"HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n";.old.zph x]};

// retrieve Grafana HTTP POST request,store in table and process as either timeseries or table
zpp:{.tmp.x:x;
  // get API url from request
  r:" " vs first x;
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`NO]
 };

query:{[rqt]
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  `.gkdb.tab upsert (.z.p;raze rqt[`targets]`target);
  :.h.hy[`json]$[rqtype~"timeserie";tsfunc[rqt;last .gkdb.tab`qry];tbfunc value last .gkdb.tab`qry];
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
  
  $[(2<count args) and `g~first args 0; graphsym[x;colN;rqt];
      (2<count args) and `t~first args 0; tablesym[x;colN;rqt];
      (2=count args) and `g~first args 0; graphnosym[x;colN;rqt];
      (2=count args) and `t~first args 0; tablenosym[x;colN;rqt];
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

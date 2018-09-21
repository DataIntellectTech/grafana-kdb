//////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// GRAFANA-KDB CONNECTER ////////////////////////////////
///////////////////////////////    AQUAQ ANALYTICS    ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////// USER DEFINED VARIABLES ///////////////////////////////

// table of all queries made
.gkdb.tab:([]time:.z.p;qry:enlist "starting table");
// user defined column name of time column
.gkdb.timeCol:`time;
// json types of kdb datatypes
.gkdb.types:(`short$til[20])!`array`boolean,#[3;`null],#[5;`number],#[10;`string];
// milliseconds between 1970 and 2000
.gkdb.epoch:946684800000;
// user defined column name of sym column
.gkdb.sym:`sym

/////////////////////////////// HTTP MESSAGE HANDLING ///////////////////////////////

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
  // convert grafana mesage to q
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`$"Annotation url nyi"]
 };

/////////////////////////////// URL HANDLING (query,search) ///////////////////////////////

query:{[rqt]
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  `.gkdb.tab upsert(.z.p;raze rqt[`targets]`target);
  :.h.hy[`json]$[rqtype~"timeserie";tsfunc[rqt;last .gkdb.tab`qry];tbfunc value last .gkdb.tab`};
erch:{[rqt]
  // build drop down case options from tables in port
  tables:tables[];
  rsp:string tables;
  rsp,:s1:string` sv/:`t,/:tables;
  rsp,:s2:string` sv/:`g,/:tables;
  rsp,:raze(s2,'"."),/:'string {(cols x) where`number=.gkdb.types abs value type each x 0}each tables;
  rsp,:raze(s1,'"."),/:'string each {distinct x .gkdb.sym}'[tables];
  :.h.hy[`json].j.j rsp;
 };

/////////////////////////////// REQUEST HANDLING ///////////////////////////////

// process a table request and return in Json format
tbfunc:{[rqt]
  // get column names and associated types to fit format
  colName:cols rqt;
  colType:.gkdb.types type each rqt colName;
  // build body of response in Json adaptor schema
  :.j.j enlist`columns`rows`type!(flip`text`type!(colName;colType);value'[rqt]til count rqt;`table);
 };

// process a timeseries request and return in Json format, takes in query and information dictionary
tsfunc:{[x;rqt]
  / split arguments
  numArgs:count args:`$"."vs rqt;tyArgs:first args 0;
  // manipulate queried table
  rqt:value first args 1;
  colN:cols rqt;
  // function to convert time to milliseconds, takes timestamp
  mil:{floor .gkdb.epoch+(`long$x)%1000000};
  // ensure time column is a timestamp
  if[12h<>type exec time from rqt;rqt:@[rqt;.gkdb.timeCol;+;.z.D]];
  // form milliseconds since epoch column
  rqt:@[rqt;`msec;:;mil rqt .gkdb.timeCol];
  // select desired time period only
  rqt:?[rqt;enlist(within;`msec;mil"P"$-1_'x[`range]`from`to);0b;()];  

  // cases for graph/table and sym arguments
  $[(2<numArgs)and`g~tyArgs;graphsym[first args 2;rqt];
    (2<numArgs)and`t~tyArgs;tablesym[colN;rqt;first args 2];
    (2=numArgs)and`g~tyArgs;graphnosym[colN;rqt];
    (2=numArgs)and`t~tyArgs;tablenosym[colN;rqt];
     `$"Wrong input"]
 };

/////////////////////////////// CASES FOR TSFUNC ///////////////////////////////

// timeserie request on graph panel w/ no preference on sym seperation
graphnosym:{[colN;rqt]
  // return columns with json number type only
  colN:-1_colN where`number=.gkdb.types abs value type each rqt 0;
  colName:colN cross`msec;
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

// timeserie request on table panel w/ no preference on sym seperation
tablenosym:{[colN;rqt]
  colType:.gkdb.types type each rqt colN;
  :.j.j enlist`columns`rows`type!(flip`text`type!(colN;colType);value'[rqt]til count rqt;`table);
 };

// timeserie request on graph panel w/ data for each sym returned
graphsym:{[colname;rqt]
  // return columns with json number type only
  syms:?[rqt;();1b;enlist[.gkdb.sym]!enlist .gkdb.sym].gkdb.sym;
  // specify what columns data to return, taken from drop down input
  outCol:(colname,`msec);
  build:{[outCol;rqt;x;y]data:flip value flip?[rqt;enlist(=;.gkdb.sym;enlist y);0b;outCol!outCol];x,`target`datapoints!(y;data)};
  :.j.j build[outCol;rqt]\[();syms];
 };

// timeserie request on table panel w/ single sym specified
tablesym:{[colN;rqt;symname]
  colType:.gkdb.types type each rqt colN;
  // select data for requested sym only
  rqt:?[rqt;enlist(=;.gkdb.sym;enlist symname);0b;()];
  :.j.j enlist`columns`rows`type!(flip`text`type!(colN;colType);value'[rqt]til count rqt;`table);
 };

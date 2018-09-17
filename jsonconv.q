//////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// GRAFANA-KDB CONNECTER ////////////////////////////////
///////////////////////////////    AQUAQ ANALYTICS    ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////// USER DEFINED VARIABLES ///////////////////////////////

// table of all queries made
.gkdb.tab:([] time:.z.p; qry:enlist "starting table");
// user defined column name of time column
.gkdb.timeCol:`time;
// json types of kdb datatypes NEEDS COMPLETING
.gkdb.types:10 5 6 7 8 9h!`string,5#`number;
// milliseconds between 1970 and 2000
.gkdb.epoch:946684800000;
// user defined column name of sym column
.gkdb.sym:`sym

/////////////////////////////// HTTP MESSAGE HANDLING ///////////////////////////////

// wrapper if user has custom .z.pp
.old.zpp:@[{.z.pp};" ";{".z.pp not defined"}];
.z.pp:{$["X-Grafana-Org-Id"~string last key last x; zpp x;.old.zpp x]};

// return alive response for GET requests
.z.ph:{.h.hy[`json] .j.j "200 OK"};

// retrieve Grafana HTTP POST request,store in table and process as either timeseries or table
zpp:{.tmp.x:x;
  // get API url from request
  r:" " vs first x;
  // convert grafana mesage to q
  rqt:.j.k r 1;
  $["query"~r 0;query[rqt];"search"~r 0;search rqt;`PLACEHOLDER]
 };

/////////////////////////////// URL HANDLING (query,search) ///////////////////////////////

query:{[rqt]
  // retrieve final query and append to table to log
  rqtype:raze rqt[`targets]`type;
  `.gkdb.tab upsert (.z.p;raze rqt[`targets]`target);
  if[rqtype~"timeserie";rsp:tsfunc[rqt;last .gkdb.tab`qry]];
  if[rqtype~"table";rsp:tbfunc value last .gkdb.tab`qry];
  :.h.hy[`json] rsp;
 };

search:{[rqt]
  rsp:string tables[];
  rsp,:"t.",/:string tables[];
  rsp,:"g.",/:string tables[];
  rsp,:("g.",/:string tables[]),\:".allsyms"
  rsp,:raze (("t.",/:string tables[]),'"."),/:' raze each string each {exec distinct sym from x} each tables[];
  :.h.hy[`json] .j.j rsp;
 };

/////////////////////////////// REQUEST HANDLING ///////////////////////////////

// process a table request and return in Json format
tbfunc:{[rqt]
  // get column names and associated types to fit format
  colName:cols rqt;
  colType:.gkdb.types type each rqt colName;
  // build body of response in Json adaptor schema
  :.j.j enlist `columns`rows`type!(flip`text`type!(colName;colType);value'[rqt]til count rqt;`table);
 };

// process a timeseries request and return in Json format, takes in query and information dictionary
tsfunc:{[x;rqt]
  // split arguments
  args:`$"."vs rqt; numArgs:count args; tyArgs:first args 0;
  // manipulate queried table
  rqt:value first args 1;
  colN:cols rqt;
  // function to convert time to milliseconds, takes info dictionary and key
  mil:{floor .gkdb.epoch+(`long$"P"$-1_x[`range]y)%1000000}[x];
  // ensure time column is a timestamp
  if[12h<>type exec time from rqt;rqt:@[rqt;.gkdb.timeCol;+;.z.D]];
  // form milliseconds since epoch column
  rqt:![rqt;();0b;enlist[`msec]!enlist(_:;(+;.gkdb.epoch;(%;($;enlist[`long];.gkdb.timeCol);1000000)))];
  // select desired time period only
  rqt:?[rqt;enlist (within;`msec;(enlist;mil`from;mil`to));0b;()];  
  
  // cases for graph/table and sym arguments
  $[(2<numArgs) and `g~tyArgs;graphsym[x;colN;rqt;first args 2];
    (2<numArgs) and `t~tyArgs;tablesym[x;colN;rqt;first args 2];
    (2=numArgs) and `g~tyArgs;graphnosym[x;colN;rqt];
    (2=numArgs) and `t~tyArgs;tablenosym[x;colN;rqt];
    `Wronginput
     ]
 };

/////////////////////////////// CASES FOR TSFUNC ///////////////////////////////

// timeserie request on graph panel w/ no preference on sym seperation
graphnosym:{[x;colN;rqt]
  // columns to be returned UPDATE THIS TO ONLY HAVE COLS OF TYPE NUMBER
  colName:colN cross `msec;
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

// timeserie request on table panel w/ no preference on sym seperation
tablenosym:{[x;colN;rqt]
  colType:.gkdb.types type each rqt colN;
  :.j.j enlist `columns`rows`type!(flip`text`type!(colN;colType);value'[rqt]til count rqt;`table);
 };

// timeserie request on graph panel w/ data for each sym returned
graphsym:{[x;colN;rqt]
  colName:colN cross `msec;
  //TO DO:Make table with syms as headers with a column name specified to go under it
  build:{y,`target`datapoints!(z 0;value each ?[x;();0b;z!z])};
  :.j.j build[rqt]\[();colName];
 };

// timeserie request on table panel w/ single sym specified
tablesym:{[x;colN;rqt;symname]
  colType:.gkdb.types type each rqt colN;
  // select data for requested sym only
  rqt:?[rqt;enlist (=;.gkdb.sym;enlist symname);0b;()];
  :.j.j enlist `columns`rows`type!(flip`text`type!(colN;colType);value'[rqt]til count rqt;`table);
 };

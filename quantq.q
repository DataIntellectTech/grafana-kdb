// Load utility file
\l utility.q
// Providers and Symbols to choose from
srcs:`BARX`GETGO`DB`SUN
syms:`APPL`GOOG`CAT`NYSE!(100;200;250.;50.)
// Create 10 random acccount ids between 1 and 100
acctid:10?100i
n:100000

// Creating table schemas
trade:([]time:`time$();sym:`symbol$();src:`symbol$();price:`float$();amount:`float$();side:`symbol$())
quote:([]time:`time$();sym:`symbol$();src:`symbol$();bid:`float$();ask:`float$();bsize:`float$();asize:`float$())
positions:([]time:`time$();sym:`symbol$();src:`symbol$();price:`float$();amount:`float$();side:`symbol$();acct:`int$();id:`long$())

initsym:{[n;x;y;z]
   /Create quote table
   tms:asc n?23:59:59.999;
   mds:y[z]+0.01*sums n?{[x] asc neg[x],x}1 2 3 4 5 6;
   bids:mds+ 0.01*n? neg {[x] asc x}0 1 2 3 4 5 6;
   asks:mds+ 0.01*n?    {[x] asc x}0 1 2 3 4 5 6;
   `quote insert flip `time`sym`src`bid`ask`asize`bsize!(tms;z;n? x;bids;asks;n? 50 100 200.;n?50 100 300 200.);
   /Create trade table
   `trade insert select time,sym,src,price:?[side=`buy;bid;ask], amount:?[side=`buy;bsize;asize],side from update side:count[i]?`buy`sell from (`int$n%10)?quote;
   /Create customer positions
   `positions insert update id:i from  update acct:count[i]?acctid from (`int$n%10)?trade;
   
   /Sort data by time for now
   `time xasc `quote;
   `time xasc `trade;
   `time xasc `positions;
   }
init:{[] initsym[n;srcs;syms;] each key syms;}
 \
init[] 

//Some utility functions

getsyms:{[syms]
	$[syms ~ `; exec distinct sym from quote; (),syms]
 };

getlps:{[lps]
	$[lps ~ `; exec distinct src from quote; (),lps]
 };


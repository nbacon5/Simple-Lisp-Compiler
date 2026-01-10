%{
    #include "types.h"
    #include "parser.tab.h"
    int lineno = 1;
%}
%%
array {return(ARRAY);}
define {return(DEFINE);}
if {return(IF);}
while {return(WHILE);}
write {return(WRITE);}
writeln {return(WRITELN);}
read {return(READ);}
and {return(AND);}
or {return(OR);}
not {return(NOT);}
seq {return(SEQ);}
set {return(SET);}
let {return(LET);}
true {return(TRUE);}
false {return(FALSE);}

\( {return('(');}
\) {return(')');}
"\[" {return('[');}
\] {return(']');}
\+ {return(PLUS);}
\- {return(MINUS);}
\* {return(MULT);}
\/ {return(DIV);}
\< {return(LT);}
\<\= {return(LTE);}
\> {return(GT);}
\>\= {return(GTE);}
\<\> {return(NE);}
\= {return(E);}

[a-z]([a-zA-Z0-9]|_)* {yylval.name = strdup(yytext); return(ID);}

[0-9]+ {yylval.val = atoi(yytext); return(NUM);}

!.* ;

[ \t] ;

[\n] {lineno++;}

%%

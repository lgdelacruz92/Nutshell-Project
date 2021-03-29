%{
#include "y.tab.h"
void yyerror (char *s);
int yylex();
%}
%%
"ls"                    { return list_directory; }
[a-zA-Z\-;]             { return yytext[0];}
\n                      { return RETURN; }

%%
int yywrap (void) {return 1;}

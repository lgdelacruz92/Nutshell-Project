%{
#include "y.tab.h"
void yyerror (char *s);
int yylex();
%}
%%
"print"             { return print; }
[0-9]+              {
                            yylval.num = atoi(yytext);
                            return number;
                         }
[ \t\n]                 ;
[;]                     { return yytext[0];}
%%
int yywrap (void) {return 1;}

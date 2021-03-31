%{
#include "y.tab.h"
void yyerror (char *s);
int yylex();
%}
%%
"ls"                             { return LIST_DIRECTORY; }
(-[a-zA-Z]+)                     { yylval.arg=strdup(yytext); return ARG; }
([a-zA-Z_][a-zA-Z0-9]*)          { yylval.arg=strdup(yytext); return FILE_ITEM; }
[ \t\n]                          ; 


%%
int yywrap (void) {return 1;}
void set_input_string(const char* in) {
  yy_scan_string(in);
}

void end_lexical_scan(void) {
  yy_delete_buffer(YY_CURRENT_BUFFER);
}

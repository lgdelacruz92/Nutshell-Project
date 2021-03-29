%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
void yyerror (char *s);
int yylex();
%}

%union {int num;}
%start line
%token print
%token <num> number;
%type <num> line exp

%%

line : print exp ';'               {printf("printing %d\n", $2);}
     | line print exp ';'          {printf("printing %d\n", $3);}
     ;
exp  : number                       {$$ = $1;}
     ;

%%

int main (void) {
    return yyparse();
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}

%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and how to use Flex start conditions
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run. 
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <stdbool.h>
void yyerror(char *);

//#define unput(c) {yytchar= (c); if(yytchar=='\n') {yylineno--; *yysptr++=yytchar;}
char* subAliases(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return aliasTable.word[i];
        }
    }
    return name;
}

bool ifAlias(char* name){
    for (int i = 0; i < aliasIndex; i++) {
        if(strcmp(aliasTable.name[i], name) == 0) {
            return true;
        }
    }
    return false;
}

int findVar(char *name) {
    //remove brackets from string
    char cleanNameArray[sizeof(varTable.var[0])];
    char *cleanName = cleanNameArray;
    int currIndex = 0;
    int i = 2;
    for (i = 2; i < strlen(name) - 1; i++) {
        cleanName[i-2] = name[i];
    }
    cleanName[i] = '\0';
    //return index for variable or -1
    for ( ; currIndex < varIndex; currIndex++) {
        if(strcmp(varTable.var[currIndex], cleanName) == 0) {
            return currIndex;
        }
    }

    return -1;
}

%}
%array
%option noyywrap

CHAR            [.A-Za-z0-9!\/_-][.A-Za-z0-9!\/_-]*
ANYCHAR            [}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*

%x string_condition
%%

<string_condition>{ANYCHAR}+     { yylval.string = strdup(yytext); return STRING;}
<string_condition>[\"]          {BEGIN(INITIAL);}

[ ]		              { }
bye                   { return BYE; }
cd		              { return CD;}
alias		          { return ALIAS; }
\|                    { return PIPE; }
"\n"		          { return END; }
printenv              { return PRINTENV; }
setenv                { return SETENV; }
unsetenv              { return UNSETENV; }
[\"]                  { BEGIN(string_condition); }
">"                   { return GREATER; }
"<"                   { return LESSER; }
">>"                  { return GREATGREAT; }
">&"                  { return GREATAMPERSAND; }
"${"{CHAR}+"}"        { int varI = findVar(yytext);
                        if (varI != -1) {
                            printf("yytext before sub: %s\n", yytext);
                            yylval.string = strdup(varTable.word[varI]);
                            return STRING;
                        }
                        else {
                            yyerror("Variable not found");
                            return ERROR;
                        } 
                      }
{CHAR}+               {if(ifAlias(yytext)) {
                        printf("yytext before sub: %s\n", yytext);
                        // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                      } else {
                        printf("yytext: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                     };
                     }
%%

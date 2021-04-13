%{
#include "nutshparser.tab.h"
#include <string.h>
#include "global.h"
#include <stdbool.h>
void yyerror(char *);
int call_count = 0;

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
    
    char cleanNameArray[sizeof(varTable.var[0])];
    char *cleanName = cleanNameArray;
    int currIndex = 0;

    //remove brackets from string
    if (name[0] == '$') {
        int i = 2;
        for (i = 2; i < strlen(name) - 1; i++) {
            cleanName[i-2] = name[i];
        }
        cleanName[i-2] = '\0';
    }
    else {
        cleanName = strcpy(cleanName, name);
    }
    //return index for variable or -1
    for ( ; currIndex < varIndex; currIndex++) {
        if(strcmp(varTable.var[currIndex], cleanName) == 0) {
            return currIndex;
        }
    }

    return -1;
}

char* checkForEnv(char* input) {
    char varNamearr[100];
    char* output = malloc(sizeof(char) * 100);
    char* varName = varNamearr;
    int foundVar = -1;
    int outIndex = 0;
    int newIndex = 0;
    for (int i = 0; i < strlen(input); i++) {
        if (input[i] == '$' && input[i+1] == '{') {
            i += 2;
            for ( ; i < strlen(input); i++) {
                if (input[i] == '}') {
                    foundVar = 1;
                    break;
                }
                else {
                    varName[newIndex] = input[i];
                    newIndex++;
                }
            }
            if (foundVar == -1) {
                strcpy(output, input);
                return output;
            }
            varName[newIndex] = '\0';
            
            foundVar = findVar(varName);
            if (foundVar == -1) {
                printf("Error: Variable not found\n");
                strcpy(output, "");
                return output;
            }
        }
        if (foundVar != -1) {
            for (int j = 0; j < strlen(varTable.word[foundVar]); j++) {
                output[outIndex++] = varTable.word[foundVar][j];
            }
            newIndex = 0;
            foundVar = -1;
        }
        else {
            output[outIndex++] = input[i];
        }
    }
    output[outIndex] = '\0';
    return output;
}

%}
%array
%option noyywrap

CHAR            [*?.A-Za-z0-9!~\/_-][*?:.A-Za-z0-9!\/_-]*
ANYCHAR            [}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -][)(*&%$#@!`;,\.a-zA-Z0-9'/*_=~ -]*
%x string_condition 
%s alias_condition
%%
    call_count++;

<string_condition>{ANYCHAR}+    {   
                                    char* newString = checkForEnv(yytext);
                                    yylval.string = strdup(newString);
                                    free(newString);
                                    return STRING;
                                }
<string_condition>[\"]          {BEGIN(INITIAL);}


    
[ ]		              { }
bye                   { return BYE; }
cd		              { return CD;}
alias		          { return ALIAS; }
unalias               { return UNALIAS; }
\|                    { return PIPE; }
"\n"		          { call_count = 0; return END; }
printenv              { return PRINTENV; }
setenv                { return SETENV; }
unsetenv              { return UNSETENV; }
[\"]                  { BEGIN(string_condition); }
">>"                  { return GREATGREAT; }
">"                   { return GREATER; }
"<"                   { return LESSER; }
"2>"                  { return ERR_TO_FILE; }
"2>&1"                { return ERR_TO_STDOUT; }
"&"                   { return BACKGROUND_RUN; }
"${"{CHAR}+"}"        { int varI = findVar(yytext);
                        if (varI != -1) {
                            char *yycopy = strdup( varTable.word[varI] );
                            for ( int i = strlen(varTable.word[varI]) - 1; i >= 0; --i ) {
                                unput( yycopy[i] );
                            }
                            free( yycopy );
                        }
                        else {
                            yyerror("Error: Variable not found\n");
                            return 1;
                        } 
                      }
{CHAR}+               {
                        if(call_count == 1 && ifAlias(yytext)) {
                            //printf("yytext before sub: %s\n", yytext);
                            // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                            char *yycopy = strdup( subAliases(yytext) );
                            for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i ) {
                                unput( yycopy[i] );
                            }
                            free( yycopy );
                        } else {
                            BEGIN(INITIAL);
                            //printf("yytext: %s\n", yytext);
                            yylval.string = strdup(yytext);
                            return STRING;
                        };
                       }

%%

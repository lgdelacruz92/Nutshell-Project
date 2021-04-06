%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run. 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"
#include "methods.h"

int yylex();
int yyerror(char *s);
int runCD(char* arg);
int runSetAlias(char *name, char *word);
int runCmdList(struct basic_cmd_linkedlist* top);
%}

%union {
    char *string;
    struct basic_cmd_linkedlist* cmd_list;
    struct basic_cmd_struct* bcs;
    struct linked_list* ll;
    int single_token;
}

%start cmd_line
%token <string> BYE CD STRING ALIAS LIST_DIR ARG FILE_ARG END
%token <single_token> PIPE
%type <cmd_list> pipe_list 
%type <bcs> basic_cmd
%type <ll> arguments

%%
cmd_line    :
	BYE END 		                {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
    | pipe_list END                  {runCmdList($1); return 1;}

pipe_list : basic_cmd               {$$ = make_basic_cmd_linkedlist($1);}  
          | basic_cmd PIPE pipe_list  { 
                                        struct basic_cmd_linkedlist* top = make_basic_cmd_linkedlist($1);
                                        top->next = $3;
                                        $$ = top;
                                    }

basic_cmd :                         { $$ = NULL; }
          | STRING arguments        { $$ = make_basic_cmd($1, $2); }

arguments   :                       { $$ = NULL; }
            | STRING arguments      { 
                                        struct linked_list* top = make_linkedlist($1);
                                        top->next = $2;
                                        $$ = top;
                                    } 

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
		strcat(varTable.word[0], "/");
		strcat(varTable.word[0], arg);

		if(chdir(varTable.word[0]) == 0) {
			strcpy(aliasTable.word[0], varTable.word[0]);
			strcpy(aliasTable.word[1], varTable.word[0]);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
				*pointer ='\0';
				pointer++;
			}
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
	}
	else { // arg is absolute path
		if(chdir(arg) == 0){
			strcpy(aliasTable.word[0], arg);
			strcpy(aliasTable.word[1], arg);
			strcpy(varTable.word[0], arg);
			char *pointer = strrchr(aliasTable.word[1], '/');
			while(*pointer != '\0') {
			*pointer ='\0';
			pointer++;
			}
		}
		else {
			printf("Directory not found\n");
                       	return 1;
		}
	}
	return 1;
}

int runSetAlias(char *name, char *word) {
	for (int i = 0; i < aliasIndex; i++) {
		if(strcmp(name, word) == 0){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if((strcmp(aliasTable.name[i], name) == 0) && (strcmp(aliasTable.word[i], word) == 0)){
			printf("Error, expansion of \"%s\" would create a loop.\n", name);
			return 1;
		}
		else if(strcmp(aliasTable.name[i], name) == 0) {
			strcpy(aliasTable.word[i], word);
			return 1;
		}
	}
	strcpy(aliasTable.name[aliasIndex], name);
	strcpy(aliasTable.word[aliasIndex], word);
	aliasIndex++;

	return 1;
}


int runCmdList(struct basic_cmd_linkedlist* top) {
    int num_nodes = count_bcll_nodes(top);
    struct cmd_struct cmds[num_nodes];
    struct basic_cmd_linkedlist * c = top;
    int i = 0;
    while (c != NULL) {
        char **cmd = format_to_char_ptrptr(c);
        cmds[i].num_args = c->bcs->num_cmd_args;
        cmds[i].val = cmd;
        i++;
        c = c->next;
    }
        
    execute(cmds, num_nodes);
    
    for (int i = 0; i < num_nodes; i++) {
        for (int j = 0; j < cmds[i].num_args; j++) {
            free(cmds[i].val[j]);
        }
    } 
    return 0;
}

%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "global.h"
#include "methods.h"

int yylex();
int yyerror(char *s);
char* get_path();
int get_var_index(const char* var);
int get_alias_index(const char* var);
int check_loop(const char *var, char **visited, int visited_index);
int runCD(char* arg);
int runPrintEnv(struct fileout_struct* fileout);
int runSetEnv(const char* var, const char* val);
int runUnSetEnv(const char* name);
int runPrintAlias(struct fileout_struct* fileout);
int runSetAlias(char* name, char* word);
int runUnAlias(const char* name);
int runCmdList(struct basic_cmd_linkedlist* top, char* filein, struct fileout_struct* fileout, char* err_file, int background);
%}

%union {
    char *string;
    struct basic_cmd_linkedlist* cmd_list;
    struct basic_cmd_struct* bcs;
    struct linked_list* ll;
    struct fileout_struct* fs;
    int single_token;
}

%start cmd_line
%token <string> BYE CD STRING ALIAS UNALIAS LIST_DIR ARG FILE_ARG PRINTENV UNSETENV END
%token <single_token> PIPE SETENV LESSER GREATER GREATGREAT GREATAMPERSAND ERR_TO_FILE ERR_TO_STDOUT BACKGROUND_RUN
%type <cmd_list> pipe_list 
%type <bcs> basic_cmd
%type <ll> arguments
%type<string> filein fileerr
%type<fs> fileout
%type<single_token> background

%%
cmd_line    :
	| BYE END 		                                           {exit(1); return 1; }
    | PRINTENV fileout END                                     {runPrintEnv($2); return 1;}
    | SETENV STRING STRING END                                 {runSetEnv($2, $3); return 1;}
    | UNSETENV STRING END                                      {runUnSetEnv($2); return 1;}
	| UNALIAS STRING END                                       {runUnAlias($2); return 1;}
    | CD                                                       {runCD(varTable.word[1]); return 1;}
    | CD STRING END        			                           {runCD($2); return 1;}
    | ALIAS fileout END                                        {runPrintAlias($2); return 1;}
    | ALIAS STRING STRING END		                           {runSetAlias($2, $3); return 1;}
    | pipe_list filein fileout fileerr background END          {runCmdList($1, $2, $3, $4, $5); return 1;}

background :                        { $$ = BACKGROUND_OFF; }
           | BACKGROUND_RUN         { $$ = BACKGROUND_ON; }

filein :                            { $$ = NULL; }
       | LESSER STRING              { $$ = $2; } 

fileout :                           { $$ = NULL; }
        | GREATGREAT STRING         { $$ = make_fileout($2, APPEND); }
        | GREATER STRING            { $$ = make_fileout($2, CREATE); }

fileerr :                           { $$ = NULL; }
        | ERR_TO_FILE STRING        { $$ = $2; }
        | ERR_TO_STDOUT             { $$ = "1"; }

pipe_list : basic_cmd               {$$ = make_basic_cmd_linkedlist($1);}  
          | basic_cmd PIPE pipe_list  { 
                                        struct basic_cmd_linkedlist* top = make_basic_cmd_linkedlist($1);
                                        top->next = $3;
                                        $$ = top;
                                    }

basic_cmd :                         { $$ = NULL; }
          | STRING arguments         { 
                                        $$ = make_basic_cmd($1, $2); 
                                    }

arguments   :                       { $$ = NULL; }
            | STRING arguments      { 
                                        struct linked_list* top = make_linkedlist($1);
                                        if (top == NULL) {
                                            $$ = NULL;
                                        }
                                        else {
                                            struct linked_list* c = top;
                                            while (c->next != NULL) {
                                                c = c->next;   
                                            }
                                            c->next = $2;
                                        }
                                        $$ = top;
                                    } 
%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

int runCD(char* arg) {
	if (arg[0] != '/') { // arg is relative path
        char newPathArr[100];
        char* newPath = newPathArr;
        newPath = strdup(varTable.word[0]);
		//strcat(varTable.word[0], "/");
		//strcat(varTable.word[0], arg);
        strcat(newPath, "/");
        strcat(newPath, arg);

		//if(chdir(varTable.word[0]) == 0) {
        if(chdir(newPath) == 0) {
            strcat(varTable.word[0], "/");
            strcat(varTable.word[0], arg);
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
    int index = get_alias_index(name);
    char prev[100];
    if (index == -1) {
    	strcpy(aliasTable.name[aliasIndex], name);
    	strcpy(aliasTable.word[aliasIndex], word);
	    aliasIndex++;
    }
    else {
        // Temporarily save the old value
        strcpy(prev, aliasTable.word[index]);
	    strcpy(aliasTable.word[index], word);
    }

    for (int i = 0; i < aliasIndex; i++) {
        //printf("(%s) = (%s)\n", aliasTable.name[i], aliasTable.word[i]);
    }

    // If there is a loop undo and print err
    char **visited = malloc(100 * sizeof(char*));
    for (int i = 0; i < 100; i++) {
        visited[i] = malloc(100 * sizeof(char));
    }
    int visited_index = 0;
    if (check_loop(name, visited, visited_index) == 0) {
        printf("Error, expansion of \"%s\" would create a loop.\n", name);
        if (index == -1) {
            strcpy(aliasTable.name[aliasIndex], "\0");
            strcpy(aliasTable.word[aliasIndex], "\0");
            aliasIndex--;
        }
        else {
            // Put the old one back
            strcpy(aliasTable.word[index], prev);
        }
    }
    for (int i = 0; i < 100; i++) {
        free(visited[i]);
    }
    free(visited);

	return 1;
}

int runPrintAlias(struct fileout_struct* fileout) {
 
    if (fileout != NULL) {
        char *mode = "w";
        if (fileout->type == APPEND) {
            mode = "a";
        }
        FILE *fptr;
        fptr = fopen(fileout->filename, mode);
        if (fptr == NULL) {
            printf("Failed to open file (%s)\n", fileout->filename);
            return -1;
        }
        for (int i = 2; i < aliasIndex; i++) {
            fputs(aliasTable.name[i], fptr);
            fputs("=", fptr);
            fputs(aliasTable.word[i], fptr);
            fputs("\n", fptr);
        }        
        fclose(fptr);
        return 0;
    }
    char *name;
    char *word;
    for (int i = 2; i < aliasIndex; i++) {
        name = aliasTable.name[i];
        word = aliasTable.word[i];
        printf("%s=", name);
        printf("%s\n", word);
    }

    return 0;
}

int runUnAlias(const char *name) {
    char *currName;
    int currIndex = 0;
    int foundFlag = 0;
    //check if in table
    for ( ; currIndex < aliasIndex; currIndex++) {
        currName = aliasTable.name[currIndex];
        if (strcmp(name, currName) == 0) {
            foundFlag = 1;
            break;
        }
    }
    if (foundFlag) {
        //move all entries up one
        char *currWord;
        for ( ; currIndex < aliasIndex - 1; currIndex++) {
            currName = aliasTable.name[currIndex + 1];
            currWord = aliasTable.word[currIndex + 1];
            strcpy(aliasTable.name[currIndex], currName);
            strcpy(aliasTable.word[currIndex], currWord);
        }
        strcpy(aliasTable.name[currIndex], "");
        strcpy(aliasTable.word[currIndex], "");
        aliasIndex--;
    }
    return 1;
}

int runCmdList(struct basic_cmd_linkedlist* top, char *filein, struct fileout_struct* fileout, char* err, int background) {
    if (top == NULL) {
        return 0;
    }
    if (top->bcs == NULL) {
        return 0;
    }
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

    char *paths = get_path();
    execute(paths, cmds, num_nodes, filein, fileout, err, background);
    
    for (int i = 0; i < num_nodes; i++) {
        for (int j = 0; j < cmds[i].num_args; j++) {
            free(cmds[i].val[j]);
        }
    }
    return 0;
}

int runPrintEnv(struct fileout_struct* fileout) {
    int p[2];
    if (pipe(p) < 0) {
        printf("Error opening pipe\n");
        return -1;
    }

    if (fileout != NULL) {
        char *mode = "w";
        if (fileout->type == APPEND) {
            mode = "a";
        }
        FILE *fptr;
        fptr = fopen(fileout->filename, mode);
        for (int i = 0; i < varIndex; i++) {
            fputs(varTable.var[i], fptr);
            fputs("=", fptr);
            fputs(varTable.word[i], fptr);
            fputs("\n", fptr);
        }
        fclose(fptr);
        return 0;
    }
    char *name;
    char *word;
    for (int i = 0; i < varIndex; i++) {
        name = varTable.var[i];
        word = varTable.word[i];
        printf("%s=", name);
        printf("%s\n", word);
    }
    return 0;
}

int runSetEnv(const char* var, const char* val) {
    //check if word size is too large
    long unsigned int maxSize = sizeof(varTable.word[0]);
    long unsigned int wordSize = strlen(val);

    if (wordSize > maxSize) {
        printf("Error: word size is limited to %lu characters\n", maxSize);
        return 1;
    }

    int index = get_var_index(var);

    if (index == -1) { // This means the var does not exist yet
        //check if vartable is full
        if (varIndex >= sizeof(varTable.var) / sizeof(varTable.var[0]) ) {
            printf("Error: environment variable table is full\n");
            return 1;
        }
        // Add new env var
        strcpy(varTable.var[varIndex], var);
        strcpy(varTable.word[varIndex], val);
        varIndex++;
    } else {
        strcpy(varTable.word[index], val);
    }

    return 0;
}

int runUnSetEnv(const char *name) {
    if (strcmp(name, varTable.var[1]) == 0 || strcmp(name, varTable.var[3]) == 0) {
        printf("Unsetting (%s) is not allowed\n", name);
        return 1;
    }
    char *currName;
    int currIndex = 0;
    int foundFlag = 0;
    //check if in table
    for ( ; currIndex < varIndex; currIndex++) {
        currName = varTable.var[currIndex];
        if (strcmp(name, currName) == 0) {
            foundFlag = 1;
            break;
        }
    }
    if (foundFlag) {
        //move all entries up one
        char *currWord;
        for ( ; currIndex < varIndex - 1; currIndex++) {
            currName = varTable.var[currIndex + 1];
            currWord = varTable.word[currIndex + 1];
            strcpy(varTable.var[currIndex], currName);
            strcpy(varTable.word[currIndex], currWord);
        }
        strcpy(varTable.var[currIndex], "");
        strcpy(varTable.word[currIndex], "");
        varIndex--;
    }
    return 1;
}


/*
* Gets to global path variable
* return {const char*}
*/
char* get_path() {
    int index = get_var_index("PATH");
    if (index == -1) {
        char* result = malloc(sizeof(char));
        result[0] = '\0';
        return result;
    } else {
        int size = strlen(varTable.var[index]);
        char* result = malloc(size * sizeof(char));
        strcpy(result, varTable.word[index]);
        return result;
    }
}

/*
* Gets the var index from varTable
* params {const char*} The variable to look for
* return {int} the index of the variable, if not found returns -1
*/
int get_var_index(const char* var) {
    int index = -1;
    
    // Iterate through all vars
    for (int i = 0; i < varIndex; i++) {
        if (strcmp(varTable.var[i], var) == 0) {
            // If found get index
            index = i;
            break;
        }
    }

    return index; // If not found, -1 else i
}

/*
* Gets the alias index
* return -1 if not found, pos num otherwise
*/
int get_alias_index(const char* var) {
    int index = -1;

    // Iterate through all vars
    for (int i = 0; i < aliasIndex; i++) {
        if (strcmp(aliasTable.name[i], var) == 0) {
            // If found get index
            index = i;
            break;
        }
    }

    return index; // If not found, -1 else i
}

/**
 Checks if there is a loop in alias
 @return 0 if true, -1 if not
 */
int check_loop(const char* var, char **visited, int visited_index) {
    if (visited_index >= 100) {
        return -1;
    }
    for (int i = 0; i < visited_index; i++) {
        if (strcmp(visited[i], var) == 0) {
            return 0;
        }
    }
    
    int index = get_alias_index(var);
    if (index != -1) {
        char word[100];
        strcpy(word, aliasTable.word[index]);
        strcpy(visited[visited_index], var);
        visited_index++;
        if (check_loop(word, visited, visited_index) == 0) {
            return 0;
        }
    }
    return -1;
}


%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
#include <string.h>
void yyerror (char *s);
int yylex();

struct Node {
    char* val;
    struct Node* next;
};

int             count_nodes(struct Node* top);
void            free_linked_list(struct Node* top); 
char**          get_args(int node_count, struct Node* args);
int             list_current_directory(struct Node* command_arguments, struct Node* files_arguments);
struct Node*    make_node(const char* s1);
int             parse_string();
void            print_prompt();


void            end_lexical_scan(void);
void            set_input_string(const char* in);

static const int OK = 1;
static const int BUFF_SIZE = 1024;


%}

%union {char* arg; int command; struct Node* node;}
%start line
%token LIST_DIRECTORY 
%token ARG
%token FILE_ITEM

%type <arg> line ARG FILE_ITEM
%type <node> arguments files
%type <command> LIST_DIRECTORY

%%

line : LIST_DIRECTORY arguments files                   {list_current_directory($2, $3);}
     | LIST_DIRECTORY files                             {list_current_directory(NULL,$2);}
     | LIST_DIRECTORY arguments                         {list_current_directory($2,NULL);}
     | LIST_DIRECTORY                                   {list_current_directory(NULL,NULL);}
     ;

files : FILE_ITEM                                       {$$ = make_node($1);}
      | files FILE_ITEM                                 {
                                                             struct Node* top = make_node($2);
                                                             top->next = $1;
                                                             $$ = top;
                                                        }
      ;

arguments : ARG                                         {$$ = make_node($1);}
          | arguments ARG                               {
                                                            struct Node* top = make_node($2);
                                                            top->next = $1;
                                                            $$ = top;
                                                        }
          ;

%%

int main (void) {

    int CMD;
    while(1) {
       print_prompt();

       char buff[BUFF_SIZE]; fgets(buff,BUFF_SIZE,stdin); 

        // Get command and execute or error out
       parse_string(buff);     
    }
    return 0;
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}

/*
* Method used for 'ls'    
* params {char*} arguments
* return -1 if error 0 otherwise 
*/
int list_current_directory(struct Node* command_arguments, struct Node* files_arguments) {
    // Initialize pipes
    int stdout_pipe[2];
    int stderr_pipe[2];

    // Pipe init error check
    if (pipe(stdout_pipe) < 0 || pipe(stderr_pipe) < 0) {
        fprintf(stderr, "List current dir pipe initialization failed");
        return -1;
    }

    // Fork 'ls' command
    int child_id= fork();
    if (child_id == 0) {

        // Close pipes that are not needed
        close(stdout_pipe[0]);
        close(stderr_pipe[0]);

        // Redirect outputs to pipes
        dup2(stdout_pipe[1], STDOUT_FILENO);
        dup2(stderr_pipe[1], STDERR_FILENO);

        // Execute 'ls' command
        char *bin_path = "/bin/ls";
        int  args_count = count_nodes(command_arguments);
        char **args = get_args(args_count, command_arguments);

        int  files_count = count_nodes(files_arguments);
        char **files = get_args(files_count, files_arguments);

        char* arg_tokens[args_count+files_count+2];

        arg_tokens[0] = bin_path;

        int index = 1;
        for (int i = 0; i < args_count; i++) {
            arg_tokens[index] = args[i];
            index += 1;
        }

        for (int i = 0; i < files_count; i++) {
            arg_tokens[index] = files[i];
            index+=1;
        }
        arg_tokens[args_count+files_count+2-1] = (char*) NULL;
        execv(bin_path, arg_tokens);

    
        // Close used pipes
        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        
        return 0;
    }
    else {
        
        // Close pipes that are not needed
        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        
        // Check for stderr
        char c;
        if (read(stderr_pipe[0],&c,1) != 0) {

            // Output to user
            printf("%c",c);
            char a;
            while ((c = read(stderr_pipe[0],&a,1)) != 0) {
                printf("%c",a);
            }
            printf("\n");
        } 
        else {
            char a;
            while ((c = read(stdout_pipe[0],&a,1)) != 0) {
                printf("%c",a);
            }
            printf("\n");
        }
    

        // Close used pipes
        close(stdout_pipe[0]);
        close(stderr_pipe[0]);
        return 0;
    } 
}
//
/**
* Method that prints terminal start command symbol
*/
void print_prompt() {
    printf("> ");
}

/**
* Method that yyparses a single input line of string
* param {const char*} in
* return {int}
*/
int parse_string(const char* in) {
    set_input_string(in);
    int rv = yyparse();
    end_lexical_scan();
    return rv;
}

/**
* Makes a node struct from string
* param {const char*}
* return Node*
*/
struct Node* make_node(const char* s) {
    printf("making node %s\n", s);
    struct Node* node = malloc(sizeof(struct Node));
    node->val = strdup(s);
    node->next = NULL;
    return node;
}

/**
* Count the number of nodes in the linked list
* param {struct Node*}
* return {int}
*/
int count_nodes(struct Node* top) {
    int count = 0;
    struct Node* c = top;
    while (c != NULL) {
        count++;
        c = c->next;
    }
    return count;
}

/**
* Frees the linked list
* param {struct Node*} top 
* return {void}
*/
void free_linked_list(struct Node* top) {
    struct Node* c = top;
    while (c != NULL) {
        struct Node* tmp = c;
        c = c->next;
        free(tmp);
    } 
}

/**
* Puts linked list args in char*[]
* param {struct Node*}
* return {char**}
*/
char** get_args(int node_count, struct Node* args) {

    char** command_args;
    command_args= malloc((node_count)*sizeof(char*));;
    struct Node* c = args;

    int index = 0;
    while (c != NULL) {
        char *cp = strdup(c->val);
        command_args[index] = cp;
        c = c->next;
        index++;
    }
    return command_args;
}

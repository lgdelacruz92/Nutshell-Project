%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <unistd.h>
void yyerror (char *s);
int yylex();
int ListCurrentDirectory();
%}

%union {char* cmd;}
%start line
%token list_directory 
%token RETURN

%%

line : list_directory  RETURN              {ListCurrentDirectory();}
     | line list_directory RETURN          {ListCurrentDirectory();}
     ;

%%

int main (void) {
    return yyparse();
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}

/*
* Method used for 'ls'    
* return -1 if error 0 otherwise 
*/
int ListCurrentDirectory() {
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
        char *arg1 = ".";
        execl(bin_path,arg1,NULL);

    
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
            while ((c = read(stderr_pipe[0],&c,1))) {
                printf("%c",c);
            }
            printf("\n");
        } 
        else {
            char a;
            while ((c = read(stdout_pipe[0],&a,1))) {
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

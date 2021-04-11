//
//  methods.c
//  nutshell
//
//  Created by Dela Cruz, Lester on 4/3/21.
//
#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fnmatch.h>
#include "methods.h"

char *concatenate(char* s1, char* s2, char* s3) {
    unsigned long t1 = strlen(s1);
    unsigned long t2 = strlen(s2);
    unsigned long t3 = strlen(s3);
    unsigned long total = t1 + t2 + t3 + 3;

    char *command_line = malloc(STRING_BUFF * sizeof(char));
    strncpy(command_line, s1, t1);
    command_line[t1]  = ' ';
    strncpy(command_line + t1 + 1, s2, t2);
    command_line[t1 + t2 + 1] = ' ';
    strncpy(command_line + t1 + t2 + 2, s3, t3);
    command_line[total-1] = '\0';
    return command_line;
}

char* append_str(char* s1, char *s2) {
    int cmds_size = (int)strlen(s1);
    int path_size = (int)strlen(s2);
    char *new_cmd = malloc((cmds_size + path_size + 2) * sizeof(char));
    memcpy(new_cmd, s1, cmds_size);
    new_cmd[cmds_size] = '/';
    memcpy(new_cmd + cmds_size+1, s2, path_size);
    new_cmd[cmds_size + path_size + 1] = '\0';
    return new_cmd;
}

struct basic_cmd_struct* make_basic_cmd_struct(int num_args, char **arguments) {
    struct basic_cmd_struct * bcs = malloc(sizeof(struct basic_cmd_struct));
    bcs->num_cmd_args = num_args;
    bcs->cmd_args = arguments;
    return bcs;
}

struct basic_cmd_list_struct* make_basic_cmd_list_struct(int num_bcs, struct basic_cmd_struct **bcs_arr) {
    struct basic_cmd_list_struct* bcls = malloc(sizeof(struct basic_cmd_list_struct));
    bcls->num_basic_cmds = num_bcs;
    bcls->basic_cmd_list = bcs_arr;
    return bcls;
}

struct linked_list* make_linkedlist(const char *ll_val) {
    if (has_pattern(ll_val) == 0) {
        struct match_files* matches = get_matching(ll_val);
        if (matches != NULL) {
            struct linked_list* ll = NULL;
            for (int i = matches->num-1; i >= 0; i--) {
                struct linked_list* new_ll = malloc(sizeof(struct linked_list));
                new_ll->next = ll;
                new_ll->val = malloc(200 * sizeof(char));
                strcpy(new_ll->val, matches->files[i]);
                ll = new_ll;
            }
            free_match_files(matches);
            return ll;
        }
        return NULL;
    } else {
        struct linked_list* ll = malloc(sizeof(struct linked_list));
        ll->val = malloc(STRING_BUFF * sizeof(char));
        ll->next = NULL;
        strcpy(ll->val, ll_val);
        return ll;
    }

}

struct basic_cmd_struct* make_basic_cmd(char* cmd, struct linked_list* arguments) {
    int nodes_count = count_nodes(arguments);
    int total_size = 2 + nodes_count;
    
    char **cmd_args = malloc(total_size * sizeof(char *));
    int i = 0;
    cmd_args[0] = malloc(sizeof(char) * STRING_BUFF);
    strcpy(cmd_args[0], cmd);
    i++;
    struct linked_list* c = arguments;
    while (i < total_size-1 && c != NULL) {
        cmd_args[i] = malloc(STRING_BUFF * sizeof(char));
        strcpy(cmd_args[i], c->val);
        i++;
        c = c->next;
    }
    cmd_args[total_size-1] = (char *) NULL;
    
    struct basic_cmd_struct* bcs = make_basic_cmd_struct(total_size, cmd_args);
    return bcs;
}

struct basic_cmd_linkedlist* make_basic_cmd_linkedlist(struct basic_cmd_struct* bcs) {
    struct basic_cmd_linkedlist* top = malloc(sizeof(struct basic_cmd_linkedlist));
    top->bcs = bcs;
    top->next = NULL;
    return top;
}

int count_nodes(struct linked_list* arguments) {
    struct linked_list* c = arguments;
    int count = 0;
    while (c != NULL) {
        count++;
        c = c->next;
    }
    return count;
}

int count_bcll_nodes(struct basic_cmd_linkedlist* top) {
    struct basic_cmd_linkedlist* c = top;
    int count = 0;
    while (c != NULL) {
        count++;
        c = c->next;
    }
    return count;
}

char **format_to_char_ptrptr(struct basic_cmd_linkedlist* top) {
    const int num_result = top->bcs->num_cmd_args;
    char **result = malloc(num_result * sizeof(char *));
    for (int i = 0; i < num_result-1; i++) {
        result[i] = malloc(STRING_BUFF * sizeof(char));
        strcpy(result[i], top->bcs->cmd_args[i]);
    }
    result[num_result-1] = (char *)NULL;
    return result;
}

void free_linked_list(struct linked_list* top) {
    struct linked_list* c = top;
    while (c != NULL) {
        struct linked_list* tmp = c;
        c = c->next;
        free(tmp->val);
        free(tmp);
    }
}

void free_bcs_linked_list(struct basic_cmd_linkedlist* top) {
    struct basic_cmd_linkedlist* c = top;
    while (c != NULL) {
        struct basic_cmd_linkedlist* tmp = c;
        c = c->next;
        free(tmp->bcs);
        free(tmp);
    }
}

int execute(char* path, struct cmd_struct* cmds, int num_nodes, char* filein, struct fileout_struct* fileout, char* err, int background) {
    int num_process = num_nodes;
    int num_pipes = num_process-1;
    int p[num_pipes][2];

    for (int i = 0; i < num_pipes; i++) {
        if (pipe(p[i]) < 0) {
            printf("Error opening pipe %d\n", i);
            exit(EXIT_FAILURE);
        }
    }
    
    struct path_vars* paths = parse_path(path);

    for (int i = 0; i < num_process; i++) {
        int child = fork();
        if (child == 0) {
            
            if (i == 0) {
                if (filein != NULL) {
                    FILE *file_dis = fopen(filein, "r");
                    if (file_dis != NULL) {
                        int file_num = fileno(file_dis);
                        dup2(file_num, STDIN_FILENO);
                        close(file_num);
                    }
                }
                if (num_process == 1) {
                    if (fileout != NULL) {
                        char *mode = "w";
                        if (fileout->type == APPEND) {
                            mode = "a";
                        }
                        FILE *file_dis = fopen(fileout->filename, mode);
                        if (file_dis != NULL) {
                            int file_num = fileno(file_dis);
                            dup2(file_num, STDOUT_FILENO);
                            close(file_num);
                        }
                    }
                    
                    redirect_std_err_to_file(err);
                } else {
                    dup2(p[i][1], STDOUT_FILENO);
                }
                
            }
            else if (i == num_process-1) {
                dup2(p[i-1][0], STDIN_FILENO);
                if (fileout != NULL) {
                    char *mode = "w";
                    if (fileout->type == APPEND) {
                        mode = "a";
                    }
                    FILE *file_dis = fopen(fileout->filename, mode);
                    if (file_dis != NULL) {
                        int file_num = fileno(file_dis);
                        dup2(file_num, STDOUT_FILENO);
                        close(file_num);
                    }
                    redirect_std_err_to_file(err);
                }
            }
            else {
                dup2(p[i-1][0], STDIN_FILENO);
                dup2(p[i][1], STDOUT_FILENO);
            }

            for (int j = 0; j < num_pipes; j++) {
                close(p[j][0]);
                close(p[j][1]);
            }
            
            for (int j = 0; j < paths->num_paths; j++) {
                char *new_cmd = append_str(paths->paths[j], cmds[i].val[0]);
                execv(new_cmd, cmds[i].val);
            }
            
            dup2(1, STDOUT_FILENO);
            printf("Command not found: (%s)\n", cmds[i].val[0]);
            close(STDIN_FILENO);
            close(STDOUT_FILENO);
            exit(EXIT_FAILURE);
        }
    }

    for (int j = 0; j < num_pipes; j++) {
        close(p[j][0]);
        close(p[j][1]);
    }
//    if (background == BACKGROUND_OFF) {
    for (int i = 0; i < num_process; i++) {
        wait(NULL);
    }
//    }

    return 0;
}

/**
    Method that parses the path variable separated by ':'
        @return {struct path_vars*}
 */
struct path_vars* parse_path(char* path) {
    struct path_vars *result = malloc(sizeof(struct path_vars));
    
    // Calculate the number paths to allocate
    char *c = path;
    int num_paths = 1;
    while (*c != '\0') {
        if (*c == ':') {
            num_paths++;
        }
        c++;
    }
    
    // Allocate the path array pointers
    char **path_arr = malloc(num_paths * sizeof(char*));
    for (int i = 0; i < num_paths; i++) {
        path_arr[i] = malloc(STRING_BUFF * sizeof(char));
    }
    
    // Iterate through 'path' and save substrings
    char *p1 = path;
    char *p2 = path;
    int j = 0;
    while (*p1 != '\0') {
        while (*p2 != '\0' && *p2 != ':') {
            p2++;
        }
        memcpy(path_arr[j], p1, p2-p1);
        path_arr[j][p2-p1] = '\0';
        j++;
        if (*p2 == '\0') {
            break;
        }

        p1 = p2 + 1;
        p2++;
    }
    result->num_paths = num_paths;
    result->paths = path_arr;
    return result;
}

/**
 Method that frees a 'struct path_var' memory
 */
void free_path_vars(struct path_vars* p) {
   // First free its paths
    for (int i = 0; i < p->num_paths; i++) {
        free(p->paths[i]);
    }
    // Then free it's struct
    free(p);
}

/**
 Gets the current working directory
 @return {char*}
 */
char* get_current_dir(void) {
    char *cwd = malloc(STRING_BUFF * sizeof(char));
    if (getcwd(cwd, sizeof(char) * STRING_BUFF) != NULL) {
        return cwd;
    } else {
        perror("getcwd() error");
        return NULL;
    }
}

struct fileout_struct* make_fileout(char* filename, int type) {
    struct fileout_struct* result = malloc(sizeof(struct fileout_struct));
    result->filename = malloc(STRING_BUFF * sizeof(char));
    result->type = type;
    strcpy(result->filename, filename);
    return result;
}

void redirect_std_err_to_file(char *file) {
    if (file != NULL) {
        if (strcmp(file, "1") == 0) {
            // using stdout
            dup2(STDOUT_FILENO, STDERR_FILENO);
        } else {
            // using a file
            FILE *file_dis = fopen(file, "w");
            if (file_dis != NULL) {
                int file_num = fileno(file_dis);
                dup2(file_num, STDERR_FILENO);
                close(file_num);
            }
        }
    }
}

struct match_files* get_matching(const char* pattern) {
    int p[2];
    if (pipe(p) == -1) {
        printf("Error opening pipe\n");
        return NULL;
    }
    
    if (fork() == 0) {
        dup2(p[1], STDOUT_FILENO);
        close(p[0]);
        close(p[1]);
        char *args[] = { "/bin/ls", NULL };
        execv(args[0], args);
    }
    
    wait(NULL);
    close(p[1]);
    char c[STRING_BUFF];
    read(p[0], c, STRING_BUFF * sizeof(char));
    int num_lines = 0;
    for (int i = 0; i < STRING_BUFF && c[i] != '\0'; i++) {
        if (c[i] == '\n') {
            num_lines++;
        }
    }
    
    char **results = malloc(sizeof(char*) * num_lines);
    char *p1 = c;
    char *p2 = c;
    int j = 0;
    for (int i = 0; i < STRING_BUFF && *p1 != '\0'; i++) {
        if (*p2 == '\n') {
            results[j] = malloc(100 * sizeof(char));
            strncpy(results[j], p1, p2-p1);
            results[j][p2-p1] = '\0';
            j++;
            p1 = p2 + 1;
        }
        p2++;
    }
    
    int matches[200];
    for (int i = 0; i < 200; i++) {
        matches[i] = -1;
    }
    int k = 0;
    for (int i = 0; i < num_lines; i++) {
        if (fnmatch(pattern, results[i], 0) == 0) {
            matches[k] = i;
            k++;
        }
    }
    
    int count_matches = 0;
    for(int i= 0; i < 200; i++) {
        if (matches[i] == -1) {
            break;
        }
        count_matches++;
    }
    
    if (count_matches == 0) {
        for (int i = 0; i < j; i++) {
            free(results[i]);
        }
        
        close(p[0]);
        return NULL;
    }
    
    struct match_files *result = malloc(sizeof(struct match_files));
    result->num = count_matches;
    result->files = malloc(sizeof(char*) * count_matches);
    for (int i = 0; i < count_matches; i++) {
        result->files[i] = malloc(200 * sizeof(char));
        strcpy(result->files[i], results[matches[i]]);
    }
    
    for (int i = 0; i < j; i++) {
        free(results[i]);
    }
    
    close(p[0]);
    return result;
}

int has_pattern(const char *arg) {
    int size = (int)strlen(arg);
    for (int j = 0; j < size; j++) {
        if (arg[j] == '*' || arg[j] == '?') {
            return 0;
        }
    }
    return -1;
}

void free_match_files(struct match_files* matches) {
    for (int i = 0; i < matches->num; i++) {
        free(matches->files[i]);
    }
    free(matches);
}

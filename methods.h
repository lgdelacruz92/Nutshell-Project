//
//  methods.h
//  nutshell
//
//  Created by Dela Cruz, Lester on 4/3/21.
//

#ifndef methods_h
#define methods_h
#include <stdio.h>
#define STRING_BUFF 1024
struct basic_cmd_struct {
    int num_cmd_args;
    char **cmd_args;
};

struct basic_cmd_list_struct {
    int num_basic_cmds;
    struct basic_cmd_struct **basic_cmd_list;
};

struct linked_list {
    char *val;
    struct linked_list* next;
};

struct basic_cmd_linkedlist {
    struct basic_cmd_struct* bcs;
    struct basic_cmd_linkedlist* next;
};

struct cmd_struct {
    int num_args;
    char **val;
};

struct path_vars {
    int num_paths;
    char **paths;
};

char* concatenate(char* s1, char* s2, char* s3);
char* append_str(char* s1, char *s2);
struct basic_cmd_struct* make_basic_cmd_struct(int num_args, char **arguments);
struct basic_cmd_list_struct* make_basic_cmd_list_struct(int num_bcs, struct basic_cmd_struct **bcs_arr);
struct linked_list* make_linkedlist(const char *val);
struct basic_cmd_struct* make_basic_cmd(char* cmd, struct linked_list* arguments);
struct basic_cmd_linkedlist* make_basic_cmd_linkedlist(struct basic_cmd_struct* top);
int count_nodes(struct linked_list* top);
int count_bcll_nodes(struct basic_cmd_linkedlist* top);
char **format_to_char_ptrptr(struct basic_cmd_linkedlist* top);
void free_linked_list(struct linked_list* top);
void free_bcs_linked_list(struct basic_cmd_linkedlist* top);
int execute(char* path, struct cmd_struct* cmds, int num_nodes, char* filein, char* fileout);
struct path_vars* parse_path(char* path);
void free_path_vars(struct path_vars* p);
char* get_current_dir(void);

#endif /* methods_h */

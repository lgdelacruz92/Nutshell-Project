//
//  methods.h
//  nutshell
//
//  Created by Dela Cruz, Lester on 4/3/21.
//

#ifndef methods_h
#define methods_h

#include <stdio.h>

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

char* concatenate(char* s1, char* s2, char* s3);
struct basic_cmd_struct* make_basic_cmd_struct(int num_args, char **arguments);
struct basic_cmd_list_struct* make_basic_cmd_list_struct(int num_bcs, struct basic_cmd_struct **bcs_arr);
struct linked_list* make_linkedlist(const char *val);
struct basic_cmd_struct* make_basic_cmd(char* cmd, struct linked_list* arguments);
struct basic_cmd_linkedlist* make_basic_cmd_linkedlist(struct basic_cmd_struct* top);
int count_nodes(struct linked_list* top);
void free_linked_list(struct linked_list* top);
void free_bcs_linked_list(struct basic_cmd_linkedlist* top);

#endif /* methods_h */

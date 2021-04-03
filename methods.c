//
//  methods.c
//  nutshell
//
//  Created by Dela Cruz, Lester on 4/3/21.
//
#include <string.h>
#include <stdlib.h>
#include "methods.h"

char *concatenate(char* s1, char* s2, char* s3) {
    unsigned long t1 = strlen(s1);
    unsigned long t2 = strlen(s2);
    unsigned long t3 = strlen(s3);
    unsigned long total = t1 + t2 + t3 + 3;

    char *command_line = malloc(total * sizeof(char));
    strncpy(command_line, s1, t1);
    command_line[t1]  = ' ';
    strncpy(command_line + t1 + 1, s2, t2);
    command_line[t1 + t2 + 1] = ' ';
    strncpy(command_line + t1 + t2 + 2, s3, t3);
    command_line[total-1] = '\0';
    return command_line;
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
    struct linked_list* ll = malloc(sizeof(struct linked_list));
    unsigned long l1 = strlen(ll_val);
    ll->val = malloc(l1 * sizeof(char) + 1);
    ll->next = NULL;
    strcpy(ll->val, ll_val);
    return ll;
}

struct basic_cmd_struct* make_basic_cmd(char* cmd, struct linked_list* arguments) {
    int nodes_count = count_nodes(arguments);
    int total_size = 2 + nodes_count;
    
    char **cmd_args = malloc(total_size * sizeof(char *));
    int i = 0;
    cmd_args[0] = malloc(sizeof(char) * strlen(cmd));
    strcpy(cmd_args[0], cmd);
    i++;
    struct linked_list* c = arguments;
    while (i < total_size-1 && c != NULL) {
        cmd_args[i] = malloc(strlen(c->val) * sizeof(char));
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

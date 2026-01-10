%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "types.h"

extern lineno;
extern int yyparse();
extern FILE *yyin;

typedef struct var{
    int funct;
    int local;
    char* name;
    Type type;
    char* reg;
    struct var* next;
} var;

typedef struct table{
    struct var* vars;
    struct table* next;
} table;

table* symbols;
table* curr_scope;
char* curr_funct;

typedef struct stack{
    char label1[10];
    char label2[10];
    struct stack* next;
} stack;

stack* top;
int if_num = 1;
int while_num = 1;

void push_label(int stmnt){
    stack* new = malloc(sizeof(stack));
    new->next = top;
    if (stmnt == 0){
        sprintf(new->label1, "ELS%d", if_num);
        sprintf(new->label2, "END%d", if_num);
        if_num++;
    }
    else if (stmnt == 1){
        sprintf(new->label1, "TOP%d", while_num);
        sprintf(new->label2, "BOT%d", while_num);
        while_num++;
    }
    top = new;
}

stack* pop_label(){
    stack* val = top;
    top = top->next;
    return val;
}

var* lookup_var(char* new_var, table* scope){
    if (scope == NULL) return NULL;
    var* val = lookup_var(new_var, scope->next);
    if (val != NULL) return val;
    var* curr_var = scope->vars;
    while (curr_var != NULL){
        if (strcmp(curr_var->name, new_var) == 0){
            //printf("Var %s found\n", new_var);
            return curr_var;
        }
        curr_var = curr_var->next;
    }
    return NULL;
}
void add_var(char* new_var, Type type, int funct){
    table* curr_table = symbols;
    while (curr_table->next != NULL){
        curr_table = curr_table->next;
    }
    var* curr_var = curr_table->vars;
    if (curr_var == NULL){
        curr_table->vars = malloc(sizeof(var));
        curr_table->vars->name = malloc(sizeof(new_var));
        curr_table->vars->funct = funct;
        if (funct >= 0) curr_table->vars->local = 0;
        else curr_table->vars->local = -1;
        curr_table->vars->type = type;
        strcpy(curr_table->vars->name, new_var);
        curr_table->vars->reg = NULL;
        curr_table->vars->next = NULL;
    }
    else{
        while (curr_var->next != NULL){
            curr_var = curr_var->next;
        }
        curr_var->next = malloc(sizeof(var));
        curr_var->next->name = malloc(sizeof(new_var));
        curr_var->next->funct = funct;
        if (funct >= 0) curr_var->next->local = 0;
        else curr_var->next->local = -1;
        curr_var->next->type = type;
        strcpy(curr_var->next->name, new_var);
        curr_var->next->reg = NULL;
        curr_var->next->next = NULL;
    }
    //printf("Line %d: Var %s added\n", lineno, new_var);
}
void enter_scope(char* s){
    table* curr_table = symbols;
    while (curr_table->next != NULL){
        curr_table = curr_table->next;
    }
    curr_table->next = malloc(sizeof(table));
    curr_table->next->vars = NULL;
    curr_table->next->next = NULL;
    curr_scope = curr_table->next;
}
void exit_scope(char* s){
    table* curr_table = symbols;
    table* prev_table = NULL;
    while (curr_table->next != NULL){
        prev_table = curr_table;
        curr_table = curr_table->next;
    }
    var* curr_var = curr_table->vars;
    while (curr_var != NULL){
        (lookup_var(curr_funct, symbols)->local)--;
        curr_var = curr_var->next;
    }
    free(curr_table->vars);
    free(curr_table);
    prev_table->next = NULL;
    curr_scope = prev_table;
    //printf("Line %d: Exited scope %s\n", lineno, s);
}
void print_symbols(){
    int layer = 0;
    table* curr_table = symbols;
    var* curr_var = symbols->vars;
    printf("-----------------------------------\n");
    while (curr_table != NULL){
        curr_var = curr_table->vars;
        for (int i=0;i<layer;i++){
            printf("\t");
        }
        while (curr_var != NULL){
            printf("%s(%d %d) ", curr_var->name, curr_var->funct, curr_var->type);
            curr_var = curr_var->next;
        }  
        curr_table = curr_table->next;
        layer++;
        printf("\n");
    }
    printf("-----------------------------------\n");
}

char* regs[14] = {"%r10d", "%r11d", "%ebx", "%ebp", "%r12d", "%r13d", "%r14d", "%r15d", "%edi", "%esi", "%edx", "%ecx", "%r8d", "%r9d"};
int temp_regs_aval[8] = {1, 1, 1, 1, 1, 1, 1, 1};


/*
typedef struct registers{
    char*
} registers;
*/

char* get_register(){
    for (int i=0;i<8;i++){
        if (temp_regs_aval[i] == 1){
            temp_regs_aval[i] = 0;
            return regs[i];
        }
    }
    printf("No registers available\n");
    exit(0);
    return -1;
}

void return_register(char* reg){
    for (int i=0;i<8;i++){
        if (strcmp(regs[i], reg) == 0){
            temp_regs_aval[i] = 1;
            return;
        }
    }
}

%}

%code requires{
    typedef struct data{
        Type type;
        char* reg;
    } data; 
}

%token DEFINE IF WHILE WRITE WRITELN READ AND OR NOT SEQ SET LET TRUE FALSE PLUS MINUS MULT DIV LT LTE GT GTE NE E ID NUM ARRAY

%union{
    int val;
    char* name;
    data data;
}

%type <val> NUM id_list param_list actual_list
%type <name> ID
%type <data> expr expr_list

%left AND OR
%left LT GT LTE GTE E NE
%left PLUS MINUS
%left MULT DIV
%left NOT

%%
ml              :       arrays program
                        {
                            var* funct = NULL;
                            var* curr_var = symbols->vars;
                            while (curr_var != NULL){
                                if (strcmp(curr_var->name, "main") == 0){
                                    if (curr_var->next != NULL){
                                        printf("Line %d: Main function definition must be the last function defined\n", lineno);
                                    }
                                    funct = curr_var;
                                }
                                curr_var = curr_var->next;
                            }
                            if (funct == NULL) printf("Line %d: Missing main function definition\n", lineno);
                        }
                ;

arrays          :       arrays array
                |
                ;

array           :       '(' ARRAY ID NUM ')'
                        {
                            if (lookup_var($3, symbols) == NULL){
                                add_var($3, ARR, -1);
                                printf("\t.text\n.comm\t%s,40\n", $3);
                            }
                            else dup_error($3);
                        }
                ;

program         :       program function
                |       function

function        :       '(' DEFINE ID 
                        {
                            char* name = $3;
                            curr_funct = $3;
                            if (strcmp(name, "main") == 0) name = "minlisp_main";
                            printf("\t.text\n.globl %s\n\t.type\t%s, @function\n%s:\n", name, name, name);
                            printf(
                                "\tpushq %rbx\n"
                                "\tpushq %rbp\n"
                                "\tpushq %r12\n"
                                "\tpushq %r13\n"
                                "\tpushq %r14\n"
                                "\tpushq %r15\n"
                                "\tsubq $128, %rsp\n"
                            );
                            if (lookup_var($3, symbols) != 0){
                                dup_error($3);
                            }
                            add_var($3, INT, 0);
                            enter_scope($3);
                        }
                        param_list 
                        {
                            lookup_var($3, symbols)->funct = $5;
                        }
                        expr ')'
                        {
                            char* name = $3;
                            if (strcmp(name, "main") == 0){ 
                                name = "minlisp_main";
                                printf("\tmovl $1, %%eax\n");
                            }
                            else printf("\tmovl %s, %%eax\n", $7.reg);
                            printf(
                                    "\taddq $128, %rsp\n"
                                    "\tpopq %r15\n"
                                    "\tpopq %r14\n"
                                    "\tpopq %r13\n"
                                    "\tpopq %r12\n"
                                    "\tpopq %rbp\n"
                                    "\tpopq %rbx\n"
                                    "\tret\n"
                            );
                            printf("\t.size\t%s, .-%s\n", name, name);
                            if (strcmp(name, "minlisp_main") == 0){
                                printf(
                                    "precall:\n"
                                        "\tmovq %rdi, 64(%rsp)\n"
                                        "\tmovq %rsi, 72(%rsp)\n"
                                        "\tmovq %rdx, 80(%rsp)\n"
                                        "\tmovq %rcx, 88(%rsp)\n"
                                        "\tmovq %r8, 96(%rsp)\n"
                                        "\tmovq %r9, 104(%rsp)\n"
                                        "\tmovq %r10, 112(%rsp)\n"
                                        "\tmovq %r11, 120(%rsp)\n"
                                        "\tret\n"
                                    "postcall:\n"
                                        "\tmovq 64(%rsp), %rdi\n"
                                        "\tmovq 72(%rsp), %rsi\n"
                                        "\tmovq 80(%rsp), %rdx\n"
                                        "\tmovq 88(%rsp), %rcx\n"
                                        "\tmovq 96(%rsp), %r8\n"
                                        "\tmovq 104(%rsp), %r9\n"
                                        "\tmovq 112(%rsp), %r10\n"
                                        "\tmovq 120(%rsp), %r11\n"
                                        "\tret\n"
                                );
                            }
                            lookup_var($3, symbols)->type = $7.type;
                            exit_scope($3);
                        }
                ;

param_list      :       '(' ')' {$$ = 0;}
                |       '(' id_list ')' {$$ = $2;}
                ;

id_list         :       id_list ID
                        {
                            if (lookup_var($2, symbols) == NULL){
                                add_var($2, INT, -1);
                                lookup_var($2, symbols)->reg = regs[8+$1];
                                $$ = $1 + 1;
                            }
                            else dup_error($2);
                        }
                |       ID
                        {
                            if (lookup_var($1, symbols) == NULL){
                                add_var($1, INT, -1);
                                lookup_var($1, symbols)->reg = regs[8];
                                $$ = 1;
                            }
                            else dup_error($1);
                        }
                ;

expr            :       NUM
                        {
                            char* reg = get_register();
                            printf("\tmovl $%d, %s\n", $1, reg); 
                            $$.reg = reg;
                            $$.type = INT;
                        }
                |       ID 
                        {
                            if (lookup_var($1, symbols) == NULL){
                                undef_error($1, 0);
                                $$.type = INT;
                            }
                            else{
                                char* reg = get_register();
                                printf("\tmovl %s, %s\n", lookup_var($1, symbols)->reg, reg); 
                                $$.reg = reg;
                                $$.type = lookup_var($1, symbols)->type;
                            }
                        }
                |       ID '[' expr ']' 
                        {
                            if (lookup_var($1, symbols) == NULL){
                                undef_error($1, 0);
                            }
                            else if (lookup_var($1, symbols)->type != ARR){
                                printf("Line %d: Variable %s is not an array\n", lineno, lookup_var($1, symbols)->name);
                            }
                            else if ($3.type != INT){
                                type_error("Array index must be an integer");
                            }
                            printf("\tmovl %s(,%s,4), %s\n", $1, $3.reg, $3.reg);
                            $$.reg = $3.reg;
                            $$.type = INT;

                        }
                |       TRUE 
                        {
                            char* reg = get_register();
                            printf("\tmovl $1, %s\n", reg); 
                            $$.reg = reg;
                            $$.type = BOOL;
                        }
                |       FALSE 
                        {
                            char* reg = get_register();
                            printf("\tmovl $0, %s\n", reg); 
                            $$.reg = reg;
                            $$.type = BOOL;
                        }
                |       '(' IF 
                        {
                            push_label(0);
                        }
                        expr 
                        {
                            printf("\tcmpl $0, %s\n", $4.reg);
                            printf("\tje %s\n", top->label1);
                        }
                        expr 
                        {
                            printf("\tjmp %s\n", top->label2);
                            printf("%s:\n", top->label1); 
                        }
                        expr ')'
                        {
                            if ($4.type != BOOL){
                                type_error("If statement expects boolean condition");
                            }
                            if ($6.type != $8.type){
                                type_error("If statement branch type mismatch");
                            }
                            else if (($6.type != INT) && ($6.type != BOOL)){
                                type_error("If statement branch type must either be both intergers or both booleans");
                            }
                            printf("\tmovl %s, %s\n", $8.reg, $6.reg);
                            printf("%s:\n", top->label2); 
                            return_register($4.reg);
                            return_register($8.reg);
                            pop_label();
                            $$ = $6;
                        }
                |       '(' WHILE 
                        {
                            push_label(1);
                            printf("%s:\n", top->label1);
                        }
                        expr 
                        {
                            printf("\tcmpl $0, %s\n", $4.reg); 
                            printf("\tje %s\n", top->label2);
                        }
                        expr ')'
                        {
                            if ($4.type != BOOL){
                                type_error("While statement expects boolean condition");
                            }
                            printf("\tjmp %s\n", top->label1);
                            printf("%s:\n", top->label2);
                            return_register($4.reg);
                            pop_label();
                            $$ = $6;
                        }
                |       '(' ID actual_list ')' 
                        {
                            if (lookup_var($2, symbols) == NULL){
                                undef_error($2, 1);
                            }
                            else if (lookup_var($2, symbols)->funct == -1){
                                printf("Line %d: Variable %s is not a function\n", lineno, lookup_var($2, symbols)->name);
                                $$.type = INT;
                            }
                            else if ($3 != lookup_var($2, symbols)->funct){
                                printf("Line %d: Function %s applied to incorrect number of arguments\n", lineno, lookup_var($2, symbols)->name);
                                $$.type = lookup_var($2, symbols)->type;
                            }
                            else{ 
                                printf("\tcall precall\n");
                                printf("\tcall %s\n", $2);
                                printf("\tcall postcall\n");

                                char* reg = get_register();
                                printf("\tmovl %%eax, %s\n", reg);
                                $$.reg = reg;
                                $$.type = lookup_var($2, symbols)->type;
                            }

                        }
                |       '(' WRITE expr ')'
                        {
                            printf("\tcall precall\n");
                            printf("\tmovl %s, %%esi\n", $3.reg);
                            printf("\tmovq S1(%rip), %rdi\n");
                            printf("\tmovl $0, %%eax\n");
                            printf("\tcall printf\n");
                            printf("\tcall postcall\n");
                            $$.reg = $3.reg;
                            if ($3.type != INT){
                                type_error("Operator write expects an int expression");
                            }
                            $$.type = INT;
                        }
                |       '(' WRITELN expr ')'
                        {
                            printf("\tcall precall\n");
                            printf("\tmovl %s, %%esi\n", $3.reg);
                            printf("\tmovq S1(%rip), %rdi\n");
                            printf("\tmovl $0, %%eax\n");
                            //FIXME
                            printf("\tcall printf\n");
                            printf("\tcall postcall\n");
                            $$.reg = $3.reg;
                            if ($3.type != INT){
                                type_error("Operator writeln expects an int expression");
                            }
                            $$.type = INT;
                        }
                |       '(' READ ')' 
                        {
                            printf("\tcall precall\n");
                            printf("\tcall minlisp_input\n");
                            printf("\tcall postcall\n");
                            char* reg = get_register();
                            printf("\tmovl %%eax, %s\n", reg);
                            $$.reg = reg;
                            $$.type = INT;
                        }
                |       '(' LET 
                        {
                            enter_scope("LET");
                        }
                        '(' assign_list ')' expr ')'
                        {
                            $$ = $7;
                            exit_scope("LET");
                        }
                |       '(' SET ID expr ')'
                        {
                            if (lookup_var($3, symbols) == NULL){
                                undef_error($3, 0);
                            }
                            else if (lookup_var($3, symbols)->type != $4.type){
                                type_error("Set statement type mismatch");
                            }
                            else{
                                printf("\tmovl %s, %s\n", $4.reg, lookup_var($3, symbols)->reg);
                                $$.reg = $4.reg;
                            }
                            $$.type = $4.type;
                        }
                |       '(' SET ID '[' expr ']' expr ')'
                        {
                            if (lookup_var($3, symbols) == NULL){
                                undef_error($3, 0);
                            }
                            if ($5.type != INT){
                                type_error("Array index must be of type integer");
                            }
                            if ($7.type != INT){
                                type_error("New value at index must be of type integer");
                            }
                            printf("\tmovl %s, %s(,%s,4)\n", $7.reg, $3, $5.reg);
                            return_register($5.reg);
                            $$.reg = $7.reg;
                            $$.type = INT;
                        }
                |       '(' PLUS expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator + requires two integers");
                            printf("\taddl %s, %s\n", $3.reg, $4.reg); 
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = INT;
                        }
                |       '(' MINUS expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator - requires two integers");
                            printf("\tsubl %s, %s\n", $4.reg, $3.reg); 
                            return_register($4.reg);
                            $$.reg = $3.reg;
                            $$.type = INT;
                        }
                |       '(' MULT expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator * requires two integers");
                            printf("\timull %s, %s\n", $3.reg, $4.reg); 
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = INT;
                        }
                |       '(' DIV expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator / requires two integers");
                            //FIXME
                            $$.type = INT;
                        }
                |       '(' LT expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator < requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsetl %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' LTE expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator <= requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsetle %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' GT expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator > requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsetg %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' GTE expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator >= requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsetge %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' E expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator = requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsete %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' NE expr expr ')'
                        {
                            if (($3.type != INT) || ($4.type != INT)) type_error("Operator <> requires two integers");
                            printf("\tcmpl %s, %s\n", $4.reg, $3.reg);
                            printf("\tsetne %%al\n");
                            printf("\tmovzbl %%al, %s\n", $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' MINUS expr ')'
                        {
                            if ($3.type != INT) type_error("Operator - expects an integer");
                            printf("\tnegl %s\n", $3.reg); 
                            $$.reg = $3.reg;
                            $$.type = INT;
                        }
                |       '(' AND expr expr ')'
                        {
                            if (($3.type != BOOL) || ($4.type != BOOL)) type_error("Operator and requires two booleans");
                            /*
                            printf("\tcmpl %s, %s\n", $3.reg, $0);
                            printf("\tmovl $0, %%eax\n");
                            printf("\tsetg %%al\n");
                            printf("\tcmpl %s, %s\n", $4.reg, $0);
                            printf("\tmovl $0, %s\n", $3.reg);
                            printf("\tsetg %s\n", $3.reg);
                            printf("\tandl %%eax, %s\n", $3.reg); 
                            */
                            printf("\tandl %s, %s\n", $3.reg, $4.reg);
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' OR expr expr ')'
                        {
                            if (($3.type != BOOL) || ($4.type != BOOL)) type_error("Operator or requires two booleans");
                            printf("\torl %s, %s\n", $3.reg, $4.reg); 
                            return_register($3.reg);
                            $$.reg = $4.reg;
                            $$.type = BOOL;
                        }
                |       '(' NOT expr ')'
                        {
                            if ($3.type != BOOL) type_error("Operator not requires a boolean");
                            printf("cmpl $0, %s\n", $3.reg);
                            printf("sete %%al\n");
                            printf("movzbl %%al, %s\n", $3.reg);
                            $$.reg = $3.reg;
                            $$.type = BOOL;
                        }
                |       '(' SEQ expr_list ')' 
                        {
                            $$ = $3;
                        }
                ;

actual_list     :       actual_list expr
                        {
                            if ($2.type != INT){
                                type_error("Function arguments must be integers");
                            }
                            else {
                                if ($1 <= 4){ 
                                    printf("\tmovl %s, %s\n", $2.reg, regs[8+$1]);
                                    return_register($2.reg);
                                }
                                else printf("Error: Max 5 arguments\n");
                            }
                            $$ = $1 + 1;
                        }
                |       {
                            $$ = 0;
                        }
                ;

assign_list     :       assign_list '(' ID expr ')'
                        {
                            if (lookup_var($3, curr_scope) == NULL){
                                add_var($3, $4.type, -1);
                                int x = 4*(lookup_var(curr_funct, symbols)->local)++;
                                char reg[10];
                                sprintf(reg, "%d(%rsp)", x);
                                lookup_var($3, curr_scope)->reg = reg;
                                printf("\tmovl %s, %s\n", $4.reg, lookup_var($3, curr_scope)->reg); 
                                return_register($4.reg);
                            }
                            else dup_error($3);
                        }
                |       '(' ID expr ')'
                        {
                            if (lookup_var($2, curr_scope) == NULL){
                                add_var($2, $3.type, -1);
                                int x = 4*(lookup_var(curr_funct, symbols)->local)++;
                                char reg[10];
                                sprintf(reg, "%d(%rsp)", x);
                                lookup_var($2, curr_scope)->reg = reg;
                                printf("\tmovl %s, %s\n", $3.reg, lookup_var($2, curr_scope)->reg); 
                                return_register($3.reg);
                            }
                            else dup_error($2);
                        }
                ;

expr_list       :       expr_list expr {$$ = $2;}
                |       expr {$$ = $1;}
                ;
%%
main(int argc, const char * argv[]) {
    yyin = fopen(argv[1], "r");
    symbols = malloc(sizeof(table));
    symbols->vars = NULL;
    symbols->next = NULL;
    curr_scope = symbols;
    curr_funct = "main";
    top = NULL;
    yyparse();
    printf(".section .note.GNU-stack,\"\",@progbits\n");
    fclose(yyin);
}

yyerror(const char *s) {
    printf("Line %d: %s\n", lineno, s);
    exit(42);
}

dup_error(char* name){
    printf("Line %d: Duplicate variable %s in this scope\n", lineno, name);
}

undef_error(char* name, int funct){
    char* f;
    if (funct >= 0) f = "function";
    else f = "variable";
    printf("Line %d: Undeclared %s %s\n", lineno, f, name); 
}

type_error(char* err){
    printf("Line %d: %s\n", lineno, err);
}

# Description
A parser and compiler for a Lisp-like programming language written in C.

# Features
- Lexical analysis and parsing using Lex and Bison
- Static scoping and expression evaluation
- Code generation to assembly
- Support for conditionals, functions, and basic data types

# Build
- Requires gcc, make, flex, and bison
- Run `make` from the project root

# Run:
- Compile the Lisp program to assemply: ```./parser test_program.ml > out```
- Assemble the Lisp-generated assembly code: ```as -o out.o out```
- Compile the C main file: ```gcc -c -o minlisp_main.o minlisp_main.c```
- Link the object files into an executable: ```gcc -o my_program minlisp_main.o out.o```
- Run the program: ```./my_program```

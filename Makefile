# Define the output binary name
TARGET = parser

# Define source files
LEX_FILE = lex.l
YACC_FILE = parser.y

# Compiler and flags
CC = gcc
CFLAGS = -w -g
LDFLAGS = -lfl 

# Default target
$(TARGET): parser.tab.o lex.yy.o
	$(CC) $(CFLAGS) -o $(TARGET) parser.tab.o lex.yy.o $(LDFLAGS)

# Compile the Yacc file
parser.tab.o: $(YACC_FILE)
	bison -d $(YACC_FILE)            # Generates parser.tab.c and parser.tab.h
	$(CC) $(CFLAGS) -c parser.tab.c -o parser.tab.o

# Compile the Lex file
lex.yy.o: $(LEX_FILE) parser.tab.h    # Depends on parser.tab.h for tokens
	flex $(LEX_FILE)                   # Generates lex.yy.c
	$(CC) $(CFLAGS) -c lex.yy.c -o lex.yy.o

# Clean up generated files
clean:
	rm -f $(TARGET) lex.yy.c parser.tab.c parser.tab.h lex.yy.o parser.tab.o


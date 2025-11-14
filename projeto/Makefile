CC = gcc
FLEX = flex
BISON = bison

all: compilador

compilador: lex.yy.c parser.tab.c
	$(CC) -o compilador lex.yy.c parser.tab.c -lfl

lex.yy.c: lexer.l parser.tab.h
	$(FLEX) lexer.l

parser.tab.c parser.tab.h: parser.y
	$(BISON) -d parser.y

test: compilador
	./compilador teste1.rl

clean:
	rm -f lex.yy.c parser.tab.c parser.tab.h compilador

.PHONY: all test clean
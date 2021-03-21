all: run

build: lexer

lex.yy.c: tema1.lex
	flex tema1.lex

lexer: lex.yy.c 
	g++ -o lexer lex.yy.c -lfl

run: build
	./lexer $(arg)

clean:
	rm -f lexer.c lexer

.PHONY: clean

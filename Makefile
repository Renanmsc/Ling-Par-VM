CC = gcc
LEX = flex
YACC = bison
CFLAGS = -lfl

all: chemmic

chemmic: src/lexer.l src/parser.y
	$(YACC) -d -o src/parser.tab.c src/parser.y
	$(LEX) -o src/lex.yy.c src/lexer.l
	$(CC) -o src/chemmic src/lex.yy.c src/parser.tab.c $(CFLAGS)
	@echo "✅ Compilador ChemMic criado em src/chemmic"

run:
	cd src && ./chemmic ../example/example.chem > ../out/example.mwasm
	cd ../MicrowaveVM && python3 main.py ../Ling-Par-VM/out/example.mwasm

clean:
	rm -f src/*.o src/chemmic src/lex.yy.c src/parser.tab.*

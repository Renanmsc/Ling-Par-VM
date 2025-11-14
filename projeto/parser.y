%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern FILE *yyin;
extern int yylex();
void yyerror(const char *s);

void emit(const char *format, ...) {
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

int label_count = 0;
%}

%token ENERGY STEPS NUMERO
%token ANDAR VIRAR_ESQ VIRAR_DIR 
%token PONTO_VIRGULA ATRIBUICAO PAREN_ABRE PAREN_FECHA

%%

programa:
    comando_lista
    ;

comando_lista:
    comando
    | comando_lista comando
    ;

comando:
    atribuicao PONTO_VIRGULA
    | acao PONTO_VIRGULA
    ;

atribuicao:
    ENERGY ATRIBUICAO NUMERO { emit("SET ENERGY %d", $3); }
    | STEPS ATRIBUICAO NUMERO { emit("SET STEPS %d", $3); }
    ;

acao:
    ANDAR PAREN_ABRE PAREN_FECHA   { emit("ROBO_ANDAR"); }
    | VIRAR_ESQ PAREN_ABRE PAREN_FECHA { emit("ROBO_VIRAR_ESQ"); }
    | VIRAR_DIR PAREN_ABRE PAREN_FECHA { emit("ROBO_VIRAR_DIR"); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático: %s\n", s);
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Erro ao abrir arquivo: %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }
    
    printf("=== INICIANDO COMPILAÇÃO ===\n");
    yyparse();
    printf("=== COMPILAÇÃO CONCLUÍDA ===\n");
    
    if (argc > 1) fclose(yyin);
    return 0;
}
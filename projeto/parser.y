%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern FILE *yyin;
extern int yylex();
void yyerror(const char *s);

// Função para gerar código assembly
void emit(const char *format, ...);
void emit_label(const char *format, int label);
int new_label();

// Arquivo de saída
FILE *output_file;
int label_count = 0;
%}

%union {
    int num;
    char *id;
}

%token <num> NUMERO
%token <id> IDENTIFICADOR
%token ENERGY STEPS FRENTE_LIVRE CARREGANDO
%token ANDAR VIRAR_ESQ VIRAR_DIR PEGAR LARGAR
%token SE SENAO ENQUANTO
%token VERDADEIRO FALSO
%token IGUAL MENOR MAIOR
%token MAIS MENOS MULT DIV
%token NAO
%token ATRIBUICAO CHAVE_ABRE CHAVE_FECHA PAREN_ABRE PAREN_FECHA PONTO_VIRGULA

%type <num> expressao
%type <id> atribuicao

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
    | condicional
    | loop
    ;

atribuicao:
    IDENTIFICADOR ATRIBUICAO expressao
    {
        if (strcmp($1, "energy") == 0) {
            emit("SET ENERGY %d", $3);
        } else if (strcmp($1, "steps") == 0) {
            emit("SET STEPS %d", $3);
        }
        free($1);
    }
    ;

acao:
    ANDAR PAREN_ABRE PAREN_FECHA   { emit("ROBO_ANDAR"); }
    | VIRAR_ESQ PAREN_ABRE PAREN_FECHA { emit("ROBO_VIRAR_ESQ"); }
    | VIRAR_DIR PAREN_ABRE PAREN_FECHA { emit("ROBO_VIRAR_DIR"); }
    | PEGAR PAREN_ABRE PAREN_FECHA     { emit("ROBO_PEGAR"); }
    | LARGAR PAREN_ABRE PAREN_FECHA    { emit("ROBO_LARGAR"); }
    ;

condicional:
    SE PAREN_ABRE expressao PAREN_FECHA CHAVE_ABRE comando_lista CHAVE_FECHA
    {
        int end_label = new_label();
        emit("DECJZ ENERGY label_%d", end_label);
        emit_label("label_%d", end_label);
    }
    | SE PAREN_ABRE expressao PAREN_FECHA CHAVE_ABRE comando_lista CHAVE_FECHA SENAO CHAVE_ABRE comando_lista CHAVE_FECHA
    {
        int else_label = new_label();
        int end_label = new_label();
        
        emit("DECJZ ENERGY label_%d", else_label);
        emit("GOTO label_%d", end_label);
        emit_label("label_%d", else_label);
        // código do else vai aqui
        emit_label("label_%d", end_label);
    }
    ;

loop:
    ENQUANTO PAREN_ABRE expressao PAREN_FECHA CHAVE_ABRE comando_lista CHAVE_FECHA
    {
        int start_label = new_label();
        int end_label = new_label();
        
        emit_label("label_%d", start_label);
        emit("DECJZ ENERGY label_%d", end_label);
        // código do loop vai aqui
        emit("GOTO label_%d", start_label);
        emit_label("label_%d", end_label);
    }
    ;

expressao:
    NUMERO                   { $$ = $1; }
    | ENERGY                 { emit("PUSH ENERGY"); $$ = 1; }
    | STEPS                  { emit("PUSH STEPS"); $$ = 1; }
    | FRENTE_LIVRE           { emit("ROBO_FRENTE_LIVRE"); $$ = 1; }
    | CARREGANDO             { emit("ROBO_TEM_OBJETO"); $$ = 1; }
    | VERDADEIRO             { $$ = 1; }
    | FALSO                  { $$ = 0; }
    | expressao MAIS expressao { emit("ADD"); $$ = 1; }
    | expressao MENOS expressao { emit("SUB"); $$ = 1; }
    | expressao IGUAL expressao { emit("CMP"); $$ = 1; }
    | NAO expressao          { emit("NOT"); $$ = 1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático: %s\n", s);
}

void emit(const char *format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(output_file, format, args);
    fprintf(output_file, "\n");
    va_end(args);
}

void emit_label(const char *format, int label) {
    fprintf(output_file, format, label);
    fprintf(output_file, ":\n");
}

int new_label() {
    return label_count++;
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Erro ao abrir arquivo: %s\n", argv[1]);
            return 1;
        }
    }
    
    output_file = fopen("output.asm", "w");
    if (!output_file) {
        fprintf(stderr, "Erro ao criar arquivo de saída\n");
        return 1;
    }
    
    yyparse();
    
    fclose(output_file);
    if (argc > 1) fclose(yyin);
    
    return 0;
}
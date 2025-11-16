%{
/* parser.y - Bison grammar para ChemMic
   Implementa diretamente emissão de .mwasm para stdout.
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/* funções auxiliares definidas aqui para não depender de codegen.c */
static int label_counter = 0;

/* gera nova label com prefixo */
char *new_label(const char *prefix) {
    char buf[64];
    snprintf(buf, sizeof(buf), "%s_%d", prefix, ++label_counter);
    return strdup(buf);
}

/* emite instrução / comentário para stdout (o .mwasm) */
void emit(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
}

/* remove aspas se string vier com elas (por segurança) */
char *strip_quotes(char *s) {
    if (!s) return NULL;
    /* nossa lexer já retorna sem aspas, mas mantemos por segurança */
    size_t n = strlen(s);
    if (n >= 2 && s[0] == '"' && s[n-1] == '"') {
        char *out = strdup(s+1);
        out[n-2] = '\0';
        return out;
    }
    return strdup(s);
}

/* função de erro do Bison */
void yyerror(const char *s) {
    fprintf(stderr, "Erro de sintaxe: %s\n", s);
}

int yylex(void); /* protótipo do scanner */
extern FILE *yyin; 
%}

/* Definições de tokens */
%token REACTION AT FOR HEAT TO COOL STIR WAIT MEASURE REPEAT HALT
%token NUMBER STRING
%token LBRACE RBRACE

/* valores semânticos */
%union {
    int ival;
    char *sval;
}

/* associar tipos */
%type <ival> NUMBER
%type <sval> STRING

%%

program:
    /* vazio possível */
    | program statement
    ;

statement:
      reaction_stmt
    | heat_stmt
    | cool_stmt
    | stir_stmt
    | wait_stmt
    | measure_stmt
    | repeat_stmt
    | halt_stmt
    /* ignoring blank/comment lines handled by lexer */
    ;

reaction_stmt:
    REACTION STRING AT NUMBER FOR NUMBER
    {
        char *rname = strip_quotes($2);
        int target_temp = $4;
        int duration = $6;
        char *lbl;

        emit("; Reaction: %s\n", rname);
        /* heurística simples de POWER: proporcional à temperatura alvo,
           limitada entre 10 e 100 */
        int power_guess = target_temp / 2;
        if (power_guess < 10) power_guess = 10;
        if (power_guess > 100) power_guess = 100;

        emit("SET POWER %d\n", power_guess);
        emit("SET TIME %d\n", duration);

        lbl = new_label("react_loop");
        emit("%s:\n", lbl);
        emit("  DECJZ TIME %s_end\n", lbl);
        emit("  GOTO %s\n", lbl);
        emit("%s_end:\n", lbl);

        free(lbl);
        free(rname);
    }
    ;

heat_stmt:
    HEAT TO NUMBER
    {
        int target_temp = $3;
        char *lbl = new_label("heat_ramp");
        /* rampa simples: aumenta POWER em passos até um chute */
        int power_guess = target_temp / 2;
        if (power_guess < 10) power_guess = 10;
        if (power_guess > 100) power_guess = 100;

        emit("; Heat to %d (heuristic power %d)\n", target_temp, power_guess);
        emit("SET POWER %d\n", power_guess);
        /* não tentamos testar TEMP diretamente para simplicidade; apenas deixa a VM evoluir */
        free(lbl);
    }
    ;

cool_stmt:
    COOL TO NUMBER
    {
        int target_temp = $3;
        char *lbl = new_label("cool_wait");
        emit("; Cool to %d (POWER=0, waiting)\n", target_temp);
        emit("SET POWER 0\n");
        /* Como o parser não tem acesso ao TEMP para checar, deixamos um loop vazio
           que o usuário poderá ajustar; aqui apenas coloca um placeholder comment */
        emit("; NOTE: cooling until TEMP <= %d (VM updates TEMP each tick)\n", target_temp);
        /* opcional: inserir pequenas esperas (SET TIME N loops) - deixamos sem loop para evitar hang */
        free(lbl);
    }
    ;

stir_stmt:
    STIR NUMBER
    {
        int n = $2;
        char *lbl = new_label("stir");
        char *lbl_end = new_label("stir_end");
        /* implementa stir como alternância POWER 0 / 60 por 'n' micro-ciclos */
        /* usamos TIME como contador */
        emit("; Stir %d times\n", n);
        emit("SET TIME %d\n", n);
        emit("%s:\n", lbl);
        emit("  SET POWER 0\n");
        emit("  INC TIME\n");   /* gerar instrução para permitir ticks */
        emit("  SET POWER 60\n");
        emit("  INC TIME\n");
        emit("  DECJZ TIME %s\n", lbl_end);
        emit("  GOTO %s\n", lbl);
        emit("%s:\n", lbl_end);

        free(lbl);
        free(lbl_end);
    }
    ;

wait_stmt:
    WAIT NUMBER
    {
        int t = $2;
        char *lbl = new_label("wait");
        /* Simples: SET TIME t; loop decrementando */
        emit("; Wait %d ticks\n", t);
        emit("SET TIME %d\n", t);
        emit("%s:\n", lbl);
        emit("  DECJZ TIME %s_end\n", lbl);
        emit("  GOTO %s\n", lbl);
        emit("%s_end:\n", lbl);
        free(lbl);
    }
    ;

measure_stmt:
    MEASURE
    {
        /* A VM tem PRINT que imprime TIME (documentado). Para debug, imprimimos TIME.
           Se for necessário mostrar TEMP/POWER, isso depende da VM. */
        emit("; Measure (PRINT)\n");
        emit("PRINT\n");
    }
    ;

repeat_stmt:
    REPEAT NUMBER LBRACE program RBRACE
    {
        int n = $2;
        char *lbl_start = new_label("repeat_start");
        char *lbl_end = new_label("repeat_end");
        /* usar TIME como contador */
        emit("; Repeat %d times\n", n);
        emit("SET TIME %d\n", n);
        emit("%s:\n", lbl_start);
        /* corpo: $$ é ignorado aqui, mas program rules já teriam emitido código
           Como Bison expande left-to-right, o code já foi emitido - para garantir que o loop encerre
           corretamente, decrementamos TIME depois do corpo */
        /* inserir marcador para final do corpo */
        emit("  DECJZ TIME %s\n", lbl_end);
        emit("  GOTO %s\n", lbl_start);
        emit("%s:\n", lbl_end);

        free(lbl_start);
        free(lbl_end);
    }
    ;

halt_stmt:
    HALT
    {
        emit("; HALT\n");
        emit("HALT\n");
    }
    ;

%%

/* C code adicional: main e suporte */
int main(int argc, char **argv) {
    /* simples: parseia stdin (ou arquivo se passado) */
    if (argc > 1) {
        FILE *f = fopen(argv[1], "r");
        if (!f) {
            fprintf(stderr, "Erro ao abrir %s\n", argv[1]);
            return 1;
        }
        yyin = f;
    }
    /* Ao iniciar, opcional emitir comentário de cabeçalho */
    emit("; Generated by ChemMic compiler (parser skeleton)\n");
    int rv = yyparse();
    if (rv == 0) {
        /* se o programa não emitiu HALT, emita por segurança */
        emit("; program end - emitting HALT (if not present)\n");
        emit("HALT\n");
    } else {
        fprintf(stderr, "Erros de parsing\n");
        return 2;
    }
    return 0;
}

%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%

[ \t\n]                 ; /* Ignora espaços em branco */

"energy"                { return ENERGY; }
"steps"                 { return STEPS; }
"frente_livre"          { return FRENTE_LIVRE; }
"carregando"            { return CARREGANDO; }

"andar"                 { return ANDAR; }
"virar_esq"             { return VIRAR_ESQ; }
"virar_dir"             { return VIRAR_DIR; }
"pegar"                 { return PEGAR; }
"largar"                { return LARGAR; }

"se"                    { return SE; }
"senao"                 { return SENAO; }
"enquanto"              { return ENQUANTO; }

"verdadeiro"            { return VERDADEIRO; }
"falso"                 { return FALSO; }

"=="                    { return IGUAL; }
"<"                     { return MENOR; }
">"                     { return MAIOR; }

"+"                     { return MAIS; }
"-"                     { return MENOS; }
"*"                     { return MULT; }
"/"                     { return DIV; }

"nao"                   { return NAO; }

"="                     { return ATRIBUICAO; }
"{"                     { return CHAVE_ABRE; }
"}"                     { return CHAVE_FECHA; }
"("                     { return PAREN_ABRE; }
")"                     { return PAREN_FECHA; }
";"                     { return PONTO_VIRGULA; }

[0-9]+                  { yylval.num = atoi(yytext); return NUMERO; }

[a-zA-Z_][a-zA-Z0-9_]*  { yylval.id = strdup(yytext); return IDENTIFICADOR; }

.                       { printf("Erro léxico: caractere inválido '%s'\n", yytext); }

%%

int yywrap() {
    return 1;
}
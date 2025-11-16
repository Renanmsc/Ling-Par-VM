%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "parser.tab.h"

#define YY_SKIP_SPACES()
%}

%%

"reaction"      return REACTION;
"at"            return AT;
"for"           return FOR;
"heat"          return HEAT;
"to"            return TO;
"cool"          return COOL;
"stir"          return STIR;
"wait"          return WAIT;
"measure"       return MEASURE;
"repeat"        return REPEAT;
"halt"          return HALT;

"{"             return LBRACE;
"}"             return RBRACE;

[0-9]+          {
                    yylval.ival = atoi(yytext);
                    return NUMBER;
                }

\"([^\\\"]|\\.)*\"  {
                    int len = yyleng;
                    char *s = (char*)malloc(len-1); /* sem as duas aspas */
                    if (!s) { fprintf(stderr, "malloc failed\n"); exit(1); }
                    strncpy(s, yytext+1, len-2);
                    s[len-2] = '\0';
                    yylval.sval = s;
                    return STRING;
                  }

"#".*           { /* ignora comentário */ }

[ \t\r\n]+      { /* ignora */ }

.               {
                    fprintf(stderr, "Caracter inválido: %s\n", yytext);
                  }

%%

int yywrap(void) {
    return 1;
}

%{
#include "parser.tab.h"
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

char *yystrdup(const char *s) {
    char *d = malloc(strlen(s)+1);
    if(d) strcpy(d,s);
    return d;
}
%}

%option noyywrap

%%
[ \t\r\n]+       
GALAXIA            return GALAXIA;
ABASTECER          return ABASTECER;
ARISTA             return ARISTA;
ACTUALIZAR_ARISTA  return ACTUALIZAR_ARISTA;
NAVE               return NAVE;
VIAJE_AUTO         return VIAJE_AUTO;
DESTINO            return DESTINO;
MODO               return MODO;
MIN_COMBUSTIBLE    return MIN_COMBUSTIBLE;
MIN_SALTOS         return MIN_SALTOS;
PASOS              return PASOS;
VIAJE_MANUAL       return VIAJE_MANUAL;
VER_VECINAS        return VER_VECINAS;
RADIO              return RADIO;
HACIA              return HACIA;
RECARGAR           return RECARGAR;
SALIR              return SALIR;
[0-9]+             { yylval.intval = atoi(yytext); return NUMERO; }
[a-zA-Z0-9_]+      { yylval.strval = yystrdup(yytext); return IDENTIFICADOR; }
.                  
%%


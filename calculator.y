%{
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
void yyerror(const char *s);
int yylex();
%}

%token NUMBER PLUS MINUS TIMES DIVIDE LPAREN RPAREN

%left PLUS MINUS        
%left TIMES DIVIDE      
%right UMINUS          

%%

input:
      /* empty */
    | input line
    ;

line:
      expr '\n' { printf("OPERATION RESULT: %d\n", $1); }
    | '\n'      { /*emptyline */ }
    ;

expr:
      expr PLUS expr            { $$ = $1 + $3; }
    | expr MINUS expr           { $$ = $1 - $3; }
    | expr TIMES expr           { $$ = $1 * $3; }
    | expr DIVIDE expr          { 
                                    if ($3 == 0) {
                                        yyerror("Division by zero");
                                        $$ = 0;
                                    } else {
                                        $$ = $1 / $3;
                                    }
                                  }
    | LPAREN expr RPAREN        { $$ = $2; }
    | MINUS expr %prec UMINUS   { $$ = -$2; }
    | NUMBER                    { $$ = $1; }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main() {
    printf("Calculator\n");
    printf("ENTER: ");
    yyparse();
    return 0;
}

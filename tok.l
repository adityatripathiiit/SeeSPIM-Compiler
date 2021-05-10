%{
#include <stdio.h>
#include "parser.tab.h"
#include "AST.h"
extern YYSTYPE yylval;
char string[10000] = "";

// for keeping track of character position and line number
int charPos=1;  
int line_prev = 1;

/*
        Adjusts line and character position variables
*/
void adjust(void) {
        
        if(yylineno != line_prev){
                // If line not same as previous then reset
                line_prev = yylineno;
                charPos = yyleng;
        } else {
                // Otherwise increment character position
                charPos+=yyleng;
        }
}

%}


%option yylineno


DIGIT			[0-9]
LETTER			[a-zA-Z_]
SINGLE_LINE_COMMENT     "//"[^\n]*
MULTI_LINE_COMMENT      "/*"[^*/]*"*/"  
STRING_REGEX            "\""(.)*"\""

%%
{SINGLE_LINE_COMMENT}		{  yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); }
{MULTI_LINE_COMMENT}		{  yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); }
{STRING_REGEX}                  {  yylval.val.text=strdup(yytext); yylval.val.type=STRINGVAL; adjust();  return(STRINGVAL);}
"Newline"		        {  yylval.val.text=strdup(yytext); yylval.val.type=NEWLINE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(NEWLINE);}
"break"		                {  yylval.val.text=strdup(yytext); yylval.val.type=BREAK; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(BREAK);}
"char"		                {  yylval.val.text=strdup(yytext); yylval.val.type=CHAR; adjust(); return(CHAR);}
"string"	          	{  yylval.val.text=strdup(yytext); yylval.val.type=STRING; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(STRING);}
"continue"                  	{  yylval.val.text=strdup(yytext); yylval.val.type=CONTINUE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(CONTINUE);}
"else"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=ELSE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(ELSE);}
"for"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=FOR; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(FOR);}
"if"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=IF; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(IF);}
"int"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=INT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(INT);}
"return"                	{  yylval.val.text=strdup(yytext); yylval.val.type=RETURN; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(RETURN);}
"void"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=VOID; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(VOID);}
"while"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=WHILE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(WHILE);}
"input"	                	{  yylval.val.text=strdup(yytext); yylval.val.type=INPUT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(INPUT);}
"output"                	{  yylval.val.text=strdup(yytext); yylval.val.type=OUTPUT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(OUTPUT);}
{LETTER}({LETTER}|{DIGIT})*	{  yylval.val.text=strdup(yytext); yylval.val.type=IDENTIFIER; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(IDENTIFIER);}
{DIGIT}+		        {  yylval.val.text=strdup(yytext); yylval.val.type=INT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(NUM_CHAR); }
'(\\[t0n'"\\]|[^\\'])'  	{  yylval.val.text=strdup(yytext); yylval.val.type=CHAR; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(NUM_CHAR);}
"&&"			        {  yylval.val.text=strdup(yytext); yylval.val.type=AND; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(AND);}
"||"			        {  yylval.val.text=strdup(yytext); yylval.val.type=OR; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(OR);}
"<="			        {  yylval.val.text=strdup(yytext); yylval.val.type=LE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(LE); }
">="			        {  yylval.val.text=strdup(yytext); yylval.val.type=GE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(GE);}
"=="			        {  yylval.val.text=strdup(yytext); yylval.val.type=EQ; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(EQ);}
"!="			        {  yylval.val.text=strdup(yytext); yylval.val.type=NE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(NE);}
";"				{  yylval.val.text=strdup(yytext); yylval.val.type=SEMICOLON; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(SEMICOLON);}
("{")			        {  yylval.val.text=strdup(yytext); yylval.val.type=LBRACE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(LBRACE); }
("}")			        {  yylval.val.text=strdup(yytext); yylval.val.type=RBRACE; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(RBRACE); }
","				{  yylval.val.text=strdup(yytext); yylval.val.type=COMMA; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(COMMA); }
"="				{  yylval.val.text=strdup(yytext); yylval.val.type=ASSIGN; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(ASSIGN);  }
"("				{  yylval.val.text=strdup(yytext); yylval.val.type=LPAREN; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(LPAREN); }
")"				{  yylval.val.text=strdup(yytext); yylval.val.type=RPAREN; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(RPAREN); }
("[")			        {  yylval.val.text=strdup(yytext); yylval.val.type=LBRACKET; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(LBRACKET);}
("]")			        {  yylval.val.text=strdup(yytext); yylval.val.type=RBRACKET; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(RBRACKET);}
"&"				{  yylval.val.text=strdup(yytext); yylval.val.type=BITAND; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust();; return(BITAND);}
"!"				{  yylval.val.text=strdup(yytext); yylval.val.type=NOT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(NOT);}
"-"				{  yylval.val.text=strdup(yytext); yylval.val.type=MINUS; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(MINUS);}
"+"				{  yylval.val.text=strdup(yytext); yylval.val.type=PLUS; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(PLUS);}
"*"				{  yylval.val.text=strdup(yytext); yylval.val.type=MUL; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(MUL);}
"/"				{  yylval.val.text=strdup(yytext); yylval.val.type=DIV; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(DIV);}
"%"				{  yylval.val.text=strdup(yytext); yylval.val.type=MOD; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(MOD);}
"<"				{  yylval.val.text=strdup(yytext); yylval.val.type=LT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(LT);}
">"				{  yylval.val.text=strdup(yytext); yylval.val.type=GT; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(GT);}
"^"				{  yylval.val.text=strdup(yytext); yylval.val.type=XOR; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(XOR);}
"|"				{  yylval.val.text=strdup(yytext); yylval.val.type=BITOR; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(BITOR);}
"?"				{  yylval.val.text=strdup("if"); yylval.val.type=IF; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(TERNERY);}
":"				{  yylval.val.text=strdup(yytext); yylval.val.type=COLON; yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); return(COLON);}
[ \t\v\n\f]		        {  yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); }
.				{  yylval.val.yylineno = yylineno; yylval.val.charPos = charPos; adjust(); }

%%

/*
        Wrap character position to 1
*/
int yywrap(){
	charPos=1;
 	return 1;
}

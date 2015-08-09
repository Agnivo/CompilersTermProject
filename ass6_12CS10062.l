%{
#include <stdio.h>	
#include <math.h>
#include <string.h>
#include "ass6_12CS10062_translator.h"
#include "y.tab.h"

extern YYSTYPE yylval;
extern int line_num;

%}

identifier-nondigit   [_a-zA-Z]
digit                 [0-9]        

nonzero-digit         [1-9]
integer-constant      ([0]|{nonzero-digit}{digit}*)
sign                  ("+"|"-")
digit-sequence        {digit}+
exponent-part         (e|E)({sign}?){digit-sequence}
fractional-constant   (({digit-sequence}?)"."{digit-sequence}|{digit-sequence}".")
floating-constant     (({fractional-constant}{exponent-part}?)|({digit-sequence}{exponent-part}))
enumeration-constant  {identifier-nondigit}({identifier-nondigit}|{digit})*
escape-sequence       "\\"[\'\"\?\\abfnrtv]        
c-char                ([^\'\\\n]|{escape-sequence})
c-char-sequence       {c-char}+
character-constant    ("\'"{c-char-sequence}"\'")

s-char                ([^\"\\\n]|{escape-sequence})
s-char-sequence       {s-char}+

single-line-comment   ("//"[^\n]*)
multi-line-comment    (\/\*)([^\*]*\*+[^\*/])*([^\*]*\*+|[^\*]*)(\*\/)

%x comment

%%

"auto"    {return AUTO;}     

"break"   {return BREAK;}     

"case"    {return CASE;}     

"char"    {return CHAR;}     

"const"    {return CONST;}     

"continue" {return CONTINUE;}     

"default"  {return DEFAULT;}     

"do"       {return DO;}     

"double"   {return DOUBLE;}     

"else"     {return ELSE;}     

"enum"     {return ENUM;}     

"extern"   {return EXTERN;}     

"float"    {return FLOAT;}     

"for"      {return FOR;}

"goto"     {return GOTO;}          

"if"       {return IF;}     

"inline"   {return INLINE;}     

"int"      {return INT;}     

"long"     {return LONG;}     

"register" {return REGISTER;}     

"restrict" {return RESTRICT;}     

"return"   {return RETURN;}     

"short"    {return SHORT;}     

"signed"   {return SIGNED;}     

"sizeof"   {return SIZEOF;}     

"static"   {return STATIC;}     

"struct"   {return STRUCT;}     

"switch"   {return SWITCH;}     

"typedef"  {return TYPEDEF;}

"union"    {return UNION;}

"unsigned" {return UNSIGNED;}     

"void"     {return VOID;}     

"volatile" {return VOLATILE;}     

"while"    {return WHILE;}     

"_Bool"    {return _BOOL;}     

"_Complex" {return _COMPLEX;}     

"_Imaginary" {return _IMAGINARY;}      

{identifier-nondigit}({identifier-nondigit}|{digit})* { yylval.strng = strdup(yytext); return identifier;}

{integer-constant} { yylval.int_val = atoi(yytext); return integer_constant;}
{floating-constant} { yylval.double_val = atof(yytext); return floating_constant;}
{character-constant} { yylval.strng = strdup(yytext); return character_constant;}

("\""({s-char-sequence}?)"\"") { yylval.strng = strdup(yytext); return string_literal;}
                                                    
{single-line-comment}  {} 

"/*" BEGIN(comment);

<comment>[^*\n]*            /* eat anything that’s not a ’*’ */ 
<comment>"*"+[^*/\n]*       /* eat up ’*’s not followed by ’/’s */
<comment>\n                 ++line_num;
<comment>"*"+"/"           BEGIN(INITIAL);

"["           {return BRACKET_OPEN;}

"]"           {return BRACKET_CLOSE;}

"("           {return PARANTHESIS_OPEN;}

")"           {return PARANTHESIS_CLOSE;}

"{"           {return BRACES_OPEN;}

"}"           {return BRACES_CLOSE;}

"."           {return DOT;}        

"->"          {return ARROW;}        

"++"          {return PLUS_PLUS;}        

"--"          {return MINUS_MINUS;}

"&"           {return AND;}

"*"           {return STAR;}

"+"           {return PLUS;}

"-"           {return MINUS;}

"~"           {return COMPLEMENT;}

"!"           {return NOT;}

"/"           {return DIVIDE;}

"%"           {return MODULO;}

"<<"          {return SHIFT_LEFT;}

">>"          {return SHIFT_RIGHT;}

"<"           {return LESS;}

">"           {return GREATER;}

"<="          {return LESS_EQUAL;}

">="          {return GREATER_EQUAL;}

"=="          {return IS_EQUAL;}

"!="          {return NOT_EQUAL;}

"^"           {return XOR;}

"|"           {return OR;}

"&&"          {return LOGICAL_AND;}

"||"          {return LOGICAL_OR;}

"?"           {return QUESTION_MARK;}

":"           {return COLON;}

";"           {return SEMI_COLON;}

"..."         {return ELLIPSIS;}

"="           {return EQUAL;}

"*="          {return STAR_EQUAL;}

"/="          {return DIVIDE_EQUAL;}

"%="          {return MODULO_EQUAL;}

"+="          {return PLUS_EQUAL;}

"-="          {return MINUS_EQUAL;}

"<<="         {return SHIFT_LEFT_EQUAL;}

">>="         {return SHIFT_RIGHT_EQUAL;}

"&="          {return AND_EQUAL;}

"^="          {return XOR_EQUAL;}

"|="          {return OR_EQUAL;}

","           {return COMMA;}

"#"           {return HASH;}

[ \t]         {}

\n            { ++line_num; }
 
%%


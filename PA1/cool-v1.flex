/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_depth = 0;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN			<-
LE				<=
DIGIT			[0-9]
LETTER			[a-zA-Z]
SPACE			[ \n\f\r\t\v]
IDENTIFIER		{LETTER}|{DIGIT}|_

%Start COMMENT

%%


{SPACE}+	;


 /*
  *  Nested comments
  */
\(\*	{ BEGIN(COMMENT); comment_depth++; }
<INITIAL>\*\)	{
	cool_yylval.error_msg = "Unmatched *)";
	return ERROR;
}
<COMMENT>\*\)	{
	comment_depth--;
	if (comment_depth == 0)
		BEGIN 0;
}
<COMMENT><<EOF>> {
	BEGIN 0;
	cool_yylval.error_msg = "EOF in comment";
	return ERROR;
}
<COMMENT>.


 /*
  * Single characters
  */
\+				{ return '+'; }
\-				{ return '-'; }
\*				{ return '*'; }
\/				{ return '/'; }
\<				{ return '<'; }
\;				{ return ';'; }
\,				{ return ','; }
\:				{ return ':'; }
\.				{ return '.'; }
\~				{ return '~'; }
\=				{ return '='; }
\(				{ return '('; }
\)				{ return ')'; }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return DARROW; }
{ASSIGN}		{ return ASSIGN; }
{LE}			{ return LE; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
[cC][lL][aA][sS][sS]	{ return CLASS; }
[eE][lL][sS][eE]		{ return ELSE; }
[fF][iI]				{ return FI; }
[iI][fF]				{ return IF; }
[iI][nN]				{ return IN; }
[iI][nN][hH][eE][rR][iI][tT][sS]	{ return INHERITS; }
[lL][eE][tT]			{ return LET; }
[lL][oO][oO][pP]		{ return LOOP; }
[pP][oO][oO][lL]		{ return POOL; }
[tT][hH][eE][nN]		{ return THEN; }
[wW][hH][iI][lL][eE]	{ return WHILE; }
[cC][aA][sS][eE]		{ return CASE; }
[eE][sS][aA][cC]		{ return ESAC; }
[oO][fF]				{ return OF; }
[nN][eE][wW]			{ return NEW; }
[nN][oO][tT]			{ return NOT; }
[iI][sS][vV][oO][iI][dD]			{ return ISVOID; }
t[rR][uU][eE]			{ cool_yylval.boolean = 1; return BOOL_CONST; }
f[aA][lL][sS][eE]		{ cool_yylval.boolean = 0; return BOOL_CONST; }
{DIGIT}+				{ cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }
[A-Z]{IDENTIFIER}*		{ cool_yylval.symbol = idtable.add_string(yytext); return TYPEID; }
[a-z]{IDENTIFIER}*		{ cool_yylval.symbol = idtable.add_string(yytext); return OBJECTID; }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"(\\.|[^"\n])*\n		{
	cool_yylval.error_msg = "Unterminated string constant";
	return ERROR;
}
\"(\\.|[^"])*\"		{
	char ch;
	int i = 0, j = 0, len = strlen(yytext);
	if (len > MAX_STR_CONST) {
		cool_yylval.error_msg = "String constant tool long";	
		return ERROR;	
	}
	char* news = (char*) malloc(len + 1);
	for(; j < len; ++j) {
		switch(yytext[j]) {
		case '\\':
			assert(j+1 < len);
			++j;
			switch(yytext[j]) {
			case 'n': news[i++] = '\n'; break;
			case 't': news[i++] = '\t'; break;
			case 'b': news[i++] = '\b'; break;
			case 'f': news[i++] = '\f'; break;
			default:  news[i++] = yytext[j]; break;
			}
			break;
		case '\"':	  break;
		case '\0':
			cool_yylval.error_msg = "String contains null character";
			return ERROR;
		case '\n':
			cool_yylval.error_msg = "Unterminated string constant";
			return ERROR;
		default:
			news[i++] = yytext[j];	
			break;
		}
	}
	news[i] = 0;
	cool_yylval.symbol = stringtable.add_string(news); 
	return STR_CONST; 
}

.	{ cool_yylval.error_msg = yytext; return ERROR; }

%%

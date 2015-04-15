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
int too_long = 0;
int null_character = 0;
int comment_depth = 0;

void start_string() {
	too_long = 0;
	null_character = 0;
	string_buf_ptr = string_buf;
}

void add_char(char ch) {
	if (string_buf_ptr-string_buf < MAX_STR_CONST-1)
		*string_buf_ptr++ = ch;
	else
		too_long = 1;
	if (ch == 0)
		null_character = 1;
}

void end_string() {
	if (string_buf_ptr-string_buf <= MAX_STR_CONST-1)
		*string_buf_ptr = 0;
	else
		too_long = 1;
}

void inc_line() {
	++curr_lineno;
}
void count_line() {
	char* ptr;
	for (ptr = yytext; *ptr != 0; ++ptr)
		if (*ptr == '\n')
			++curr_lineno;
}
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

%Start STRING COMMENT DASH_COMMENT

%%


<INITIAL>{SPACE}+		{ count_line(); }


 /*
  *  Nested comments
  */
<INITIAL,COMMENT>\(\*	{ BEGIN(COMMENT); comment_depth++; }
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
<COMMENT>.|\n	{ count_line(); }

<INITIAL>\-\-			{ BEGIN(DASH_COMMENT); }
<DASH_COMMENT>[^\n]		{ }
<DASH_COMMENT>\n		{ BEGIN 0; count_line(); }
<DASH_COMMENT><<EOF>>	{ BEGIN 0; }

<INITIAL>\" 	{
	BEGIN(STRING);
	start_string();
}
<STRING>\\n		{ add_char('\n'); }
<STRING>\\t		{ add_char('\t'); }
<STRING>\\b		{ add_char('\b'); }
<STRING>\\f		{ add_char('\f'); }
<STRING>\\\n	{ add_char('\n'); count_line(); }
<STRING>\\.		{ add_char(yytext[1]); }
<STRING>\n		{
	BEGIN 0;
	count_line();
	cool_yylval.error_msg = "Unterminated string constant"; 
	return ERROR;
}
<STRING>[^"]	{ add_char(yytext[0]); }
<STRING>\"		{
	BEGIN 0;
	end_string();
	if (too_long) {
		cool_yylval.error_msg = "String constant tool long";	
		return ERROR;
	} else if (null_character) {
		cool_yylval.error_msg = "String contains null character";
		return ERROR;
	}
	cool_yylval.symbol = stringtable.add_string(string_buf);
	return STR_CONST;
}
<STRING><<EOF>> {
	BEGIN 0;
	cool_yylval.error_msg = "EOF in string constant";
	return ERROR;
}


 /*
  * Single characters
  */
<INITIAL>\+				{ return '+'; }
<INITIAL>\-				{ return '-'; }
<INITIAL>\*				{ return '*'; }
<INITIAL>\/				{ return '/'; }
<INITIAL>\<				{ return '<'; }
<INITIAL>\;				{ return ';'; }
<INITIAL>\,				{ return ','; }
<INITIAL>\:				{ return ':'; }
<INITIAL>\.				{ return '.'; }
<INITIAL>\~				{ return '~'; }
<INITIAL>\=				{ return '='; }
<INITIAL>\(				{ return '('; }
<INITIAL>\)				{ return ')'; }
<INITIAL>\{				{ return '{'; }
<INITIAL>\}				{ return '}'; }
<INITIAL>\@				{ return '@'; }

 /*
  *  The multiple-character operators.
  */
<INITIAL>{DARROW}		{ return DARROW; }
<INITIAL>{ASSIGN}		{ return ASSIGN; }
<INITIAL>{LE}			{ return LE; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
<INITIAL>[cC][lL][aA][sS][sS]	{ return CLASS; }
<INITIAL>[eE][lL][sS][eE]		{ return ELSE; }
<INITIAL>[fF][iI]				{ return FI; }
<INITIAL>[iI][fF]				{ return IF; }
<INITIAL>[iI][nN]				{ return IN; }
<INITIAL>[iI][nN][hH][eE][rR][iI][tT][sS]	{ return INHERITS; }
<INITIAL>[lL][eE][tT]			{ return LET; }
<INITIAL>[lL][oO][oO][pP]		{ return LOOP; }
<INITIAL>[pP][oO][oO][lL]		{ return POOL; }
<INITIAL>[tT][hH][eE][nN]		{ return THEN; }
<INITIAL>[wW][hH][iI][lL][eE]	{ return WHILE; }
<INITIAL>[cC][aA][sS][eE]		{ return CASE; }
<INITIAL>[eE][sS][aA][cC]		{ return ESAC; }
<INITIAL>[oO][fF]				{ return OF; }
<INITIAL>[nN][eE][wW]			{ return NEW; }
<INITIAL>[nN][oO][tT]			{ return NOT; }
<INITIAL>[iI][sS][vV][oO][iI][dD]			{ return ISVOID; }
<INITIAL>t[rR][uU][eE]			{ cool_yylval.boolean = 1; return BOOL_CONST; }
<INITIAL>f[aA][lL][sS][eE]		{ cool_yylval.boolean = 0; return BOOL_CONST; }
<INITIAL>{DIGIT}+				{ cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }
<INITIAL>[A-Z]{IDENTIFIER}*		{ cool_yylval.symbol = idtable.add_string(yytext); return TYPEID; }
<INITIAL>[a-z]{IDENTIFIER}*		{ cool_yylval.symbol = idtable.add_string(yytext); return OBJECTID; }


<INITIAL>.	{ cool_yylval.error_msg = yytext; return ERROR; }

%%

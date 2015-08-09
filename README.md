# CompilersTermProject
A Compiler for Tiny C language, a language having a subset of features of C language

Name - Agnivo Saha
Roll Number - 12CS10062
Assignment 6
The test files are named ass6_12CS10062_testi.c where 1 <= i <= 5 and the output quads are generated in ass6_12CS10062_quadsi.out and the symboltables are generated in ass6_12CS10062_symboltablesi.out and the asm codes are generated in ass6_12CS10062_i.c.
The files to be viewed are ass6_12CS10062.l, ass6_12CS10062.y, ass6_12CS10062_translator.h, ass6_12CS10062_translator.cxx, ass6_12CS10062_target_translator.cxx.


**************NOTE : IMPORTANT ************************************************

Steps for Compiling :-
1. First type make which will create the a.out file.
2. If you want to run any of the test files given(i.e. ass6_12CS10062_testi where 1 <= i <= 5),
type "make testi" where 1 <= i <= 5. It will directly execute the test file after generating the ouputs in files mentioned above.
3. If you want to run a new file :-
	a) Type "./a.out < filename.c" where the file to be run is filename.c .
	b) Type "make test" which will directly execute the generated .s file.
	The quads will be in ass6_12CS10062_quads.out .
	The symboltables will be in ass6_12CS10062_symboltables.out .
	The generated x86-assembly code will be in ass6_12CS10062.s . 
4. Type "make clean" to delete all the .o files.

*******************************************************************************

Explanations/Answers :-
Augmentations in grammar :-
1. logical_AND_expression : logical_AND_expression LOGICAL_AND M inclusive_OR_expression
M is added for backpatching the truelist of logical_AND_expression (i.e. $1).
2. logical_OR_expression : logical_OR_expression LOGICAL_OR M logical_AND_expression
M is added for backpatching the falselist of logical_AND_expression (i.e. $1).
3. M : 
To keep track of nextinstr after it.
4. N : 
To emit a goto which is backpatched later.
5. selection_statement : IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N
For backpatching expression's truelist with M.instr and N2 emits a goto which is redundant
if expression is a boolean else it skips checking the expression more than once.
6. selection_statement : IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N ELSE M statement
If the expression is not boolean, then convert the expression into boolean after emitting a goto to avoid
checking been done more than once. Backpatch the truelist to the instruction of M1 and falselist to the 
instruction of M2 and create the nextlist of this statement as nextlist of N2 and nextlist of statement.
7. iteration_statement : WHILE PARANTHESIS_OPEN M expression N PARANTHESIS_CLOSE M statement
Convert the expression into boolean and the nextlist of N has been backpatched to instruction of M2
and emit goto to instruction of M1.
8. iteration_statement : DO M statement WHILE M PARANTHESIS_OPEN expression PARANTHESIS_CLOSE SEMI_COLON
Convert the expression into boolean and the truelist of N has been backpatched to instruction of M1
and the nextlist of statement has been backpatched to instruction of M1.
9. iteration_statement : FOR PARANTHESIS_OPEN expression_opt SEMI_COLON M expression_opt N SEMI_COLON M expression_opt N 
PARANTHESIS_CLOSE M statement 
If expression2 is not a boolean, convert it into a boolean and backpatch nextlist of statement to M2,
backpatch nextlist of N2 to M1 and backpatch truelist of expression2 into instruction of M3,
N1's goto is redundant if expression2 is boolean, else it is backpatched to nextinstr before converting 
expression2 into boolean.

All attributes are stored in struct expression_attributes and whichever attribute is needed, that is only used.
Statements use nextlist.
Expressions uses loc,_type_,width,truelist,falselist,int_val,double_val,strng and is_l_val.
Arrays uses loc,array,is_array_id,_type_,width,strng and int_val.
Function declarations use loc,parameter_list, num_params, symbol_table_ and strng;
Declaration uses loc, _type_, width and strng.
M uses instr to keep track of nextinstr after it.
N uses nextlist as it emits a dangling goto which is yet to be backpatched.
All types are of type struct expression_attributes.
All tokens except identifier, integer_constant, floating_constant, character_constant and string_literal are of type 
struct expression_attributes to avoid warnings.
identifier is of type char*, integer_constant is of type int, floating_constant is of type double, character_constant
and string_literal are of type char* .

Shortcomings : The grammar allows various semantically wrong codes to be parsed.
String Literal can only be passed as a parameter to a function (i.e. a parameter having char* type).

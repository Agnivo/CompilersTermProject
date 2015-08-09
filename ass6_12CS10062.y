%{
#include <string.h>
#include <stdio.h>
#include "ass6_12CS10062_translator.h"

//Augmentations in grammar :-
//1. logical_AND_expression : logical_AND_expression LOGICAL_AND M inclusive_OR_expression
//M is added for backpatching the truelist of logical_AND_expression (i.e. $1).
//2. logical_OR_expression : logical_OR_expression LOGICAL_OR M logical_AND_expression
//M is added for backpatching the falselist of logical_AND_expression (i.e. $1).
//3. M : 
//To keep track of nextinstr after it.
//4. N : 
//To emit a goto which is backpatched later.
//5. selection_statement : IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N
//For backpatching expression's truelist with M.instr and N2 emits a goto which is redundant
//if expression is a boolean else it skips checking the expression more than once.
//6. selection_statement : IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N ELSE M statement
//If the expression is not boolean, then convert the expression into boolean after emitting a goto to avoid
//checking been done more than once. Backpatch the truelist to the instruction of M1 and falselist to the 
//instruction of M2 and create the nextlist of this statement as nextlist of N2 and nextlist of statement.
//7. iteration_statement : WHILE PARANTHESIS_OPEN M expression N PARANTHESIS_CLOSE M statement
//Convert the expression into boolean and the nextlist of N has been backpatched to instruction of M2
//and emit goto to instruction of M1.
//8. iteration_statement : DO M statement WHILE M PARANTHESIS_OPEN expression PARANTHESIS_CLOSE SEMI_COLON
//Convert the expression into boolean and the truelist of N has been backpatched to instruction of M1
//and the nextlist of statement has been backpatched to instruction of M1.
//9. iteration_statement : FOR PARANTHESIS_OPEN expression_opt SEMI_COLON M expression_opt N SEMI_COLON M expression_opt N 
//PARANTHESIS_CLOSE M statement 
//If expression2 is not a boolean, convert it into a boolean and backpatch nextlist of statement to M2,
//backpatch nextlist of N2 to M1 and backpatch truelist of expression2 into instruction of M3,
//N1's goto is redundant if expression2 is boolean, else it is backpatched to nextinstr before converting 
//expression2 into boolean.

//All attributes are stored in struct expression_attributes and whichever attribute is needed, that is only used.
//Statements use nextlist.
//Expressions uses loc,_type_,width,truelist,falselist,int_val,double_val,strng and is_l_val.
//Arrays uses loc,array,is_array_id,_type_,width,strng and int_val.
//Function declarations use loc,parameter_list, num_params, symbol_table_ and strng;
//Declaration uses loc, _type_, width and strng.
//M uses instr to keep track of nextinstr after it.
//N uses nextlist as it emits a dangling goto which is yet to be backpatched.
//All types are of type struct expression_attributes.
//All tokens except identifier, integer_constant, floating_constant, character_constant and string_literal are of type 
//struct expression_attributes to avoid warnings.
//identifier is of type char*, integer_constant is of type int, floating_constant is of type double, character_constant
//and string_literal are of type char* .

//Shortcomings : The grammar allows various semantically wrong codes to be parsed.
//0 has not been included as integer constant.
 
//Global Declarations.
extern int yylex();

symboltable* Global_symtab = new symboltable; // Global Symboltable.
symboltable* curr_symtab = Global_symtab; // Current symboltable initialize to global symboltable.
Quad* Quad_array[MAX_SIZE]; // Quad Array of size MAX_SIZE.
int nextinstr = 1; // Global variable nextinstr storing the count of Quads in Quad Array.
_type* global_type; // Global variable global_type used for storing type while declaration.
int global_width; // Global variable global_width used for storing width while declaration.
int unary_operator_type; // stores the type of unary operator.
int line_num = 1; // stores the line number for debugging reasons.
int flag_return_type = 0; // flag for obtaining the return type of a function to check its type with returned variable.
_type* return_type; // stores the return type of a function.
int return_width = 0; // stores the size of the return type of a function.

void yyerror(char s[]);

%}

%union {
	struct expression_attributes expression_attr;
  int int_val;
  double double_val;
  char* strng;
}

%token <expression_attr>     AUTO
%token <expression_attr>     BREAK
%token <expression_attr>     CASE
%token <expression_attr>     CHAR
%token <expression_attr>     CONST
%token <expression_attr>     CONTINUE
%token <expression_attr>     DEFAULT
%token <expression_attr>     DO
%token <expression_attr>     DOUBLE
%token <expression_attr>     ELSE
%token <expression_attr>     ENUM
%token <expression_attr>     EXTERN
%token <expression_attr>     FLOAT
%token <expression_attr>     FOR
%token <expression_attr>     GOTO
%token <expression_attr>     IF
%token <expression_attr>     INLINE
%token <expression_attr>     INT
%token <expression_attr>     LONG
%token <expression_attr>     REGISTER
%token <expression_attr>     RESTRICT
%token <expression_attr>     RETURN
%token <expression_attr>     SHORT
%token <expression_attr>     SIGNED
%token <expression_attr>     SIZEOF
%token <expression_attr>     STATIC
%token <expression_attr>     STRUCT 
%token <expression_attr>     SWITCH 
%token <expression_attr>     TYPEDEF
%token <expression_attr>     UNION 
%token <expression_attr>     UNSIGNED
%token <expression_attr>     VOID
%token <expression_attr>     VOLATILE 
%token <expression_attr>     WHILE
%token <expression_attr>     _BOOL
%token <expression_attr>     _COMPLEX
%token <expression_attr>     _IMAGINARY

%token <expression_attr>     BRACKET_OPEN
%token <expression_attr>     BRACKET_CLOSE
%token <expression_attr>     PARANTHESIS_OPEN
%token <expression_attr>     PARANTHESIS_CLOSE
%token <expression_attr>     BRACES_OPEN
%token <expression_attr>     BRACES_CLOSE
%token <expression_attr>     DOT
%token <expression_attr>     ARROW
%token <expression_attr>     PLUS_PLUS
%token <expression_attr>     MINUS_MINUS
%token <expression_attr>     AND 
%token <expression_attr>     STAR
%token <expression_attr>     PLUS
%token <expression_attr>     MINUS
%token <expression_attr>     COMPLEMENT
%token <expression_attr>     NOT
%token <expression_attr>     DIVIDE
%token <expression_attr>     MODULO
%token <expression_attr>     SHIFT_LEFT
%token <expression_attr>     SHIFT_RIGHT
%token <expression_attr>     LESS
%token <expression_attr>     GREATER
%token <expression_attr>     LESS_EQUAL
%token <expression_attr>     GREATER_EQUAL
%token <expression_attr>     IS_EQUAL
%token <expression_attr>     NOT_EQUAL
%token <expression_attr>     XOR
%token <expression_attr>     OR 
%token <expression_attr>     LOGICAL_AND
%token <expression_attr>     LOGICAL_OR
%token <expression_attr>     QUESTION_MARK
%token <expression_attr>     COLON
%token <expression_attr>     SEMI_COLON 
%token <expression_attr>     ELLIPSIS
%token <expression_attr>     EQUAL
%token <expression_attr>     STAR_EQUAL
%token <expression_attr>     DIVIDE_EQUAL
%token <expression_attr>     MODULO_EQUAL
%token <expression_attr>     PLUS_EQUAL
%token <expression_attr>     MINUS_EQUAL
%token <expression_attr>     SHIFT_LEFT_EQUAL
%token <expression_attr>     SHIFT_RIGHT_EQUAL
%token <expression_attr>     AND_EQUAL
%token <expression_attr>     XOR_EQUAL
%token <expression_attr>     OR_EQUAL
%token <expression_attr>     COMMA
%token <expression_attr>     HASH

%token <strng>               identifier
%token <int_val>             integer_constant
%token <double_val>          floating_constant
%token <strng>               character_constant
%token <strng>               string_literal

%type <expression_attr>      primary_expression 
%type <expression_attr>      postfix_expression
%type <expression_attr>      enumeration_constant
%type <expression_attr>      argument_expression_list
%type <expression_attr>      unary_expression
%type <expression_attr>      unary_operator
%type <expression_attr>      cast_expression
%type <expression_attr>      multiplicative_expression
%type <expression_attr>      additive_expression
%type <expression_attr>      shift_expression
%type <expression_attr>      relational_expression
%type <expression_attr>      equality_expression
%type <expression_attr>      AND_expression
%type <expression_attr>      exclusive_OR_expression
%type <expression_attr>      inclusive_OR_expression
%type <expression_attr>      logical_AND_expression
%type <expression_attr>      logical_OR_expression
%type <expression_attr>      conditional_expression
%type <expression_attr>      assignment_expression
%type <expression_attr>      assignment_operator
%type <expression_attr>      expression
%type <expression_attr>      expression_opt
%type <expression_attr>      constant_expression
%type <expression_attr>      declaration
%type <expression_attr>      declaration_specifiers
%type <expression_attr>      init_declarator_list
%type <expression_attr>      init_declarator
%type <expression_attr>      storage_class_specifier
%type <expression_attr>      type_specifier
%type <expression_attr>      specifier_qualifier_list
%type <expression_attr>      enum_specifier
%type <expression_attr>      enumerator_list
%type <expression_attr>      enumerator
%type <expression_attr>      type_qualifier
%type <expression_attr>      function_specifier
%type <expression_attr>      declarator
%type <expression_attr>      direct_declarator
%type <expression_attr>      pointer
%type <expression_attr>      type_qualifier_list
%type <expression_attr>      parameter_type_list
%type <expression_attr>      parameter_list
%type <expression_attr>      parameter_declaration
%type <expression_attr>      identifier_list
%type <expression_attr>      typename
%type <expression_attr>      initializer
%type <expression_attr>      initializer_list
%type <expression_attr>      designation 
%type <expression_attr>      designator_list
%type <expression_attr>      designator
%type <expression_attr>      statement
%type <expression_attr>      labeled_statement
%type <expression_attr>      compound_statement
%type <expression_attr>      block_item_list 
%type <expression_attr>      block_item
%type <expression_attr>      expression_statement
%type <expression_attr>      selection_statement
%type <expression_attr>      iteration_statement
%type <expression_attr>      jump_statement
%type <expression_attr>      translation_unit
%type <expression_attr>      external_declaration
%type <expression_attr>      function_definition
%type <expression_attr>      declaration_list
%type <expression_attr>      M
%type <expression_attr>      N

%nonassoc IFEND
%nonassoc ELSE
%start translation_unit

%%   

translation_unit : external_declaration {

          }
        | translation_unit external_declaration {

          }
        ;

external_declaration : function_definition 
        | declaration 
        ;
                

function_definition : declaration_specifiers declarator compound_statement {
              //if the return type is not a pointer, then enter ret_val into the symboltable.
              if($2._type_ == NULL || !strcmp($2._type_->var_type,"function")){
                char str[] = "ret_val";
                $2.symbol_table_->insert(str,$1._type_,$1.width);
              }
              //if return type is a pointer, then update the type of return value obtained from declaration_specifiers and declarator
              //and insert ret_val into the symboltable.
              else {
                _type* t;
                t = $1._type_;
                while(t->_next_ != NULL){
                 t = t->_next_;
                }
                t->_next_ = $2._type_;
                char str[] = "ret_val";
                $2.symbol_table_->insert(str,$1._type_,4);
              }     
              //change current symboltable to global symboltable as function scope has finished.
              curr_symtab = Global_symtab; 
              if($3.nextlist != NULL){
                backpatch($3.nextlist,nextinstr);
              }    
              flag_return_type = 0;
              return_width = 0;
              emit(_FUNCTION_END,$2.strng);
          }
        | declaration_specifiers declarator declaration_list compound_statement {
              //if the return type is not a pointer, then enter ret_val into the symboltable.
              if($2._type_ == NULL || !strcmp($2._type_->var_type,"function")){
                char str[] = "ret_val";
                $2.symbol_table_->insert(str,$1._type_,$1.width);
              }
              //if return type is a pointer, then update the type of return value obtained from declaration_specifiers and declarator
              //and insert ret_val into the symboltable.
              else {
                _type* t;
                t = $1._type_;
                while(t->_next_ != NULL){
                 t = t->_next_;
                }
                t->_next_ = $2._type_;
                char str[] = "ret_val";
                $2.symbol_table_->insert(str,$1._type_,4);
              }     
              //change current symboltable to global symboltable as function scope has finished.
              curr_symtab = Global_symtab; 
              if($4.nextlist != NULL){
                backpatch($4.nextlist,nextinstr);
              }
              flag_return_type = 0; 
              return_width = 0;
              emit(_FUNCTION_END,$2.strng);
          }
        ;

declaration_list : declaration
        | declaration_list declaration 
        ;  

primary_expression : identifier {
              $$.strng = strdup($1);  
              $$.int_val = 0;
              $$.loc = NULL;
              $$.array = NULL;
              $$.pointer = NULL;
              $$.truelist = NULL;
              $$.falselist = NULL;
              $$.is_l_val = 0;
              $$.double_val = 0;
              $$.char_val = NULL;
              $$.is_pointer_type = 0;
          }
        | integer_constant {
              //create a temporary and emit temporary assigned integer_constant and update the type and width attributes.
              $$.loc = curr_symtab->gentemp();
              _type* t = new _type;
              t->var_type = strdup("int");
              t->_next_ = NULL;
              curr_symtab->update($$.loc,t,4,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + 4;
              $$._type_ = t;
              $$.width = 4;
              emit($$.loc->_name_,$1);
              $$.int_val = $1;
              $$.truelist = NULL;
              $$.falselist = NULL;
              $$.strng = strdup($$.loc->_name_);
              $$.is_l_val = 1;
              $$.is_pointer_type = 0;
          }
        | floating_constant {
              //create a temporary and emit temporary assigned floating_constant and update the type and width attributes.
              $$.loc = curr_symtab->gentemp();
              _type* t = new _type;
              t->var_type = strdup("double");
              t->_next_ = NULL;
              curr_symtab->update($$.loc,t,8,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + 8;
              $$._type_ = t;
              $$.width = 8;
              emit($$.loc->_name_,$1);
              $$.double_val = $1;
              $$.truelist = NULL;
              $$.falselist = NULL;
              $$.int_val = 0;
              $$.strng = strdup($$.loc->_name_);
              $$.is_l_val = 1;
              $$.is_pointer_type = 0;
          }
        | character_constant {
              //create a temporary and emit temporary assigned character_constant and update the type and width attributes.
              $$.loc = curr_symtab->gentemp();
              _type* t = new _type;
              t->var_type = strdup("char");
              t->_next_ = NULL;
              curr_symtab->update($$.loc,t,1,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + 1;
              $$._type_ = t;
              $$.width = 1;
              emit($$.loc->_name_,$1);
              $$.int_val = 0;
              $$.truelist = NULL;
              $$.falselist = NULL;
              $$.strng = strdup($$.loc->_name_);
              $$.is_l_val = 1;
              $$.char_val = strdup($1);
              $$.is_pointer_type = 0;
          }
        | string_literal {
              //create a variable and emit variable assigned string_literal and update the type and width attributes.
              char* s = curr_symtab->generate_constant_label($1);
              $$.loc = curr_symtab->lookup(s);
              _type* t = new _type;
              t->var_type = strdup("ptr");
              t->_next_ = new _type;
              t->_next_->var_type = strdup("char");
              t->_next_->_next_ = NULL;
              $$._type_ = t;
              curr_symtab->update($$.loc,t,4,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + 4;
              $$.int_val = 0;
              $$.strng = strdup($$.loc->_name_);
              $$.is_l_val = 1;
              $$.char_val = strdup($1);
              $$.truelist = NULL;
              $$.falselist = NULL;
              $$.is_pointer_type = 0;
          }
        | PARANTHESIS_OPEN expression PARANTHESIS_CLOSE {
              //Assign the attributes of parameter expression as expression.
              $$ = $2;
              _list* l = $2.falselist;
              if(l == NULL){
                $$.falselist = NULL;
              }
              else {
                $$.falselist = new _list;
                _list* l2 = $$.falselist;
                while(l->_next_ != NULL){
                  l2->_index_ = l->_index_;
                  l2->_next_ = new _list;
                  l2 = l2->_next_;
                  l = l->_next_;
                }
                l2->_index_ = l->_index_;
                l2->_next_ = NULL;
              }
              _list* l1 = $2.truelist;
              if(l1 == NULL){
                $$.truelist = NULL;
              }
              else {
                $$.truelist = new _list;
                _list* l2 = $$.truelist;
                while(l1->_next_ != NULL){
                  l2->_index_ = l1->_index_;
                  l2->_next_ = new _list;
                  l2 = l2->_next_;
                  l1 = l1->_next_;
                }
                l2->_index_ = l1->_index_;
                l2->_next_ = NULL;
              } 
          }     
        ;

postfix_expression : primary_expression {
              $$ = $1;
              $$.array = NULL;
              $$.is_array_id = 0;
          }
        | postfix_expression BRACKET_OPEN expression BRACKET_CLOSE { 
        	    //If it is the first dimension of array, then get the array from the symboltable entry.
              if($1.array == NULL){
                $1.loc = curr_symtab->lookup($1.strng);
                $1._type_ = gettype($1.loc);
                $1.width = getwidth($1.loc);
                $1.array = $1.loc;
              }
              $$.array = $1.array;
              //If the expression variable has not been declared then print error message.
              if($3._type_ == NULL){
                char str[] = "Identifier not declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Array indices cannot be negative.
              if($3.int_val < 0){
                char s[] = "Array index cannot be negative at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);   
              }
              //If the expression which is array index is boolean or char, convert it into integer.
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Only integer/character or boolean expressions allowed as indices of an array.
              if(strcmp($3._type_->var_type,"int")){
                char s[] = "Array indices should be an integer at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              if($1._type_ == NULL){
                char s[] = "Array not declared before at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              else if(!strcmp($1._type_->var_type,"ptr")){
                 if(!strcmp($1._type_->_next_->var_type,"int")){
                    $$.width = 4;
                 }
                 else if(!strcmp($1._type_->_next_->var_type,"char")){
                    $$.width = 1;
                 } 
                 else if(!strcmp($1._type_->_next_->var_type,"double")){
                    $$.width = 4;
                 }
              }
              //If the array has not been declared then print error message.
              else if(strcmp($1._type_->var_type,"array")){
                char s[] = "Array not declared before at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              if($1._type_->size == 0 && strcmp($1._type_->_next_->var_type,"array")){
                if(!strcmp($1._type_->_next_->var_type,"int")){
                    $$.width = 4;
                 }
                 else if(!strcmp($1._type_->_next_->var_type,"char")){
                    $$.width = 1;
                 } 
                 else if(!strcmp($1._type_->_next_->var_type,"double")){
                    $$.width = 4;
                 }
              }
              else if($1._type_->size == 0 && !strcmp($1._type_->_next_->var_type,"array")){
                char s[] = "Array size not declared before at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              else {
                //Calculate new size of the array after indexing.
                $$.width = $1.width / ($1._type_->size);
              }  
              //If its the first dimension of array,then generate a temporary and store the index of the array which is product
              //of expression's integer value and the width of the array.
              if($1.is_array_id == 0){
                $$.loc = curr_symtab->gentemp();
                _type t;
                t.var_type = strdup("int");
                t._next_ = NULL;
                curr_symtab->update($$.loc,&t,4,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + 4;
                char s5[65];
                sprintf(s5,"%d",$$.width);
                emit($$.loc->_name_,$3.loc->_name_,_MULT,s5);
              }
              //If its not the first dimension of the array, then generate a temporary and store the index of the array which is 
              //sum of the previous dimension of array's width and the product of the expression's integer value and width of array.
              else {
                $$.loc = curr_symtab->gentemp();
                symtab* temp;
                temp = curr_symtab->gentemp();
                _type t;
                t.var_type = strdup("int");
                t._next_ = NULL;
                curr_symtab->update($$.loc,&t,4,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + 4;
                curr_symtab->update(temp,&t,4,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + 4;
                char s1[65];
                sprintf(s1,"%d",$$.width);
                emit(temp->_name_,$3.loc->_name_,_MULT,s1);
                emit($$.loc->_name_,$1.loc->_name_,_PLUS,temp->_name_);
              }
              //Assign the new type after array indexing.
              $$._type_ = $1._type_->_next_;
              $$.is_array_id = 1;
              $$.is_l_val = 0;
          }
        | postfix_expression PARANTHESIS_OPEN PARANTHESIS_CLOSE {
              //Get the function symboltable entry by looking up in the Global Symboltable.
              $1.loc = Global_symtab->lookup($1.strng);
              $1._type_ = gettype($1.loc);
              symboltable* symbol_table = $1.loc->_nested_table_;
              //If the function has not been declared then the nested table entry will be NULL, print error message.
              if(symbol_table == NULL){
                char s[] = "Function has not been defined at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //Get the return value type from the symbol table of the function.
              //Create a new temporary variable for storing the return value after the function call.
              $$.loc = curr_symtab->gentemp();
              curr_symtab->update($$.loc,return_type,return_width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + return_width;
              _type *p,*q;
              //Equate the type of return variable as the type of temporary variable.
              $$._type_ = new _type;
              p = $$._type_;
              q = return_type;
              while(q->_next_ != NULL){
                p->var_type = strdup(q->var_type);
                p->size = q->size;
                p->_next_ = new _type;
                q = q->_next_;
                p = p->_next_;
              }
              p->var_type = strdup(q->var_type);
              p->size = q->size;
              p->_next_ = NULL;          
              $$.width = return_width;
              char s2[2];
              sprintf(s2,"0");
              //Call the function and store the return value in the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_CALL,s2);
              $$.is_l_val = 1;
          }
        | postfix_expression PARANTHESIS_OPEN argument_expression_list PARANTHESIS_CLOSE {
              //Get the function symboltable entry by looking up in the Global Symboltable.
              $1.loc = Global_symtab->lookup($1.strng);
              $1._type_ = gettype($1.loc);
              symboltable* symbol_table = $1.loc->_nested_table_;
              //If the function has not been declared then the nested table entry will be NULL, print error message.
              if(symbol_table == NULL){
                char s[] = "Function has not been defined at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //If the number of parameters between declaration and function call are different, print an error message.
              if($1.loc->num_params != $3.num_params){
                char s[] = "Mismatch in number of parameters at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);               
              }
              int i;
              func_list* f = $3.parameter_list;
              //For each parameter in the function call, check if it's type matches with the parameter in the function declaration. 
              for(i = 0;i < $3.num_params;i++){
                  _type* t1 = symbol_table->_symboltable_[i]._type_;
                  if(!strcmp(symbol_table->_symboltable_[i]._name_,"ret_val")){
                    char s[] = "More function parameters than expected at line ";
                    char temps[33];
                    sprintf(temps,"%d",line_num);
                    strcat(s,temps);
                    yyerror(s);
                    exit(1);
                  }
                  _type* t2 = f->_type_;
                  //Check if the implicit type conversion between parameter in the function call and the parameter in the 
                  //function declaration is possible or not. If possible, do the conversion.
                  //Implicit type conversion is implemented for fundamental datatypes.
                  if(t1->_next_ == NULL && t2->_next_ == NULL){
                    if(!strcmp(t1->var_type,"char")){
                      if(!strcmp(t2->var_type,"int")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("char");                        
                        curr_symtab->update(temp,t2,1,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 1;
                        emit(temp->_name_,f->loc->_name_,_INT_TO_CHAR);
                        f->loc = temp;
                        f->width = 1;
                      }
                      else if(!strcmp(t2->var_type,"double")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("int");                        
                        curr_symtab->update(temp,t2,4,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 4;
                        emit(temp->_name_,f->loc->_name_,_DOUBLE_TO_INT);
                        f->loc = temp;
                        temp = curr_symtab->gentemp();
                        t2->var_type = strdup("char");                        
                        curr_symtab->update(temp,t2,1,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 1;
                        emit(temp->_name_,f->loc->_name_,_INT_TO_CHAR);
                        f->loc = temp;
                        f->width = 1;
                      }
                    }
                    else if(!strcmp(t1->var_type,"int")){
                      if(!strcmp(t2->var_type,"char")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("int");                        
                        curr_symtab->update(temp,t2,4,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 4;
                        emit(temp->_name_,f->loc->_name_,_CHAR_TO_INT);
                        f->loc = temp;
                        f->width = 4;
                      }
                      else if(!strcmp(t2->var_type,"double")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("int");                        
                        curr_symtab->update(temp,t2,4,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 4;
                        emit(temp->_name_,f->loc->_name_,_DOUBLE_TO_INT);
                        f->loc = temp;
                        f->width = 4;
                      }
                    }
                    else if(!strcmp(t1->var_type,"double")){
                      if(!strcmp(t2->var_type,"int")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("double");                        
                        curr_symtab->update(temp,t2,8,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 8;
                        emit(temp->_name_,f->loc->_name_,_INT_TO_DOUBLE);
                        f->loc = temp;
                        f->width = 8;
                      }
                      else if(!strcmp(t2->var_type,"char")){
                        symtab* temp = curr_symtab->gentemp();
                        t2->var_type = strdup("int");                        
                        curr_symtab->update(temp,t2,4,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 4;
                        emit(temp->_name_,f->loc->_name_,_CHAR_TO_INT);
                        f->loc = temp;
                        temp = curr_symtab->gentemp();
                        t2->var_type = strdup("double");                        
                        curr_symtab->update(temp,t2,8,curr_symtab->offset);
                        curr_symtab->offset = curr_symtab->offset + 8;
                        emit(temp->_name_,f->loc->_name_,_INT_TO_DOUBLE);
                        f->loc = temp;
                        f->width = 8;
                      }
                    }
                  }
                  //Check if the function parameter types are same or not after implicit type conversion.
                  while(t1 != NULL && t2 != NULL){
                    if((!strcmp(t1->var_type,"ptr") && !strcmp(t2->var_type,"array")) || (!strcmp(t1->var_type,"array") && !strcmp(t2->var_type,"ptr"))){

                    }
                    else if(strcmp(t1->var_type,t2->var_type)){
                      char s[] = "Function parameters type mismatch at line ";
                      char temps[33];
                      sprintf(temps,"%d",line_num);
                      strcat(s,temps);
                      yyerror(s);
                      exit(1);
                    }
                    t1 = t1->_next_;
                    t2 = t2->_next_;
                  }
                  //If the types are not same, print error message.
                  if(t1 != NULL || t2 != NULL){
                    char s[] = "Function parameters type mismatch at line ";
                    char temps[33];
                    sprintf(temps,"%d",line_num);
                    strcat(s,temps);
                    yyerror(s);
                    exit(1);
                  }
                  //If this parameter has same type as function declaration then emit this as a parameter of the function.
                  emit(_PARAM,f->loc->_name_);
                  //Check for next parameter.
                  f = f->_next_;
              }
              //Get the return value type from the symbol table of the function.
              $$.loc = curr_symtab->gentemp();
              curr_symtab->update($$.loc,return_type,return_width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + return_width;
              //Equate the type of return variable as the type of temporary variable.
              _type *p,*q;
              $$._type_ = new _type;
              p = $$._type_;
              q = return_type;
              while(q->_next_ != NULL){
                p->var_type = strdup(q->var_type);
                p->_next_ = new _type;
                q = q->_next_;
                p = p->_next_;
              }
              p->var_type = strdup(q->var_type);
              p->_next_ = NULL;          
              $$.width = return_width;
              char s3[33];
              sprintf(s3,"%d",$3.num_params);
              //Call the function and store the return value in the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_CALL,s3);
              $$.is_l_val = 1;   
          }
        | postfix_expression DOT identifier
        | postfix_expression ARROW identifier
        | postfix_expression PLUS_PLUS {
             //If it is a l-value then this operation is valid else it is invalid.
             char *strr;
             if($1.is_l_val == 0){
               $$ = $1;
               //Get the variable from the symboltable.
               if($1.is_array_id == 1){
                  symtab* temp = curr_symtab->gentemp();
                  strr = strdup($1.loc->_name_);
                  emit(temp->_name_,$1.array->_name_,_ARRAY_DEREFERENCE,$1.loc->_name_);
                  $1.loc = temp;
                  curr_symtab->update($1.loc,$1._type_,$1.width,curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + $1.width;
               }
               else {
                  $1.loc = curr_symtab->lookup($1.strng);
                  $1._type_ = gettype($1.loc);
                  $1.width = getwidth($1.loc);
               }   
               $$.loc = curr_symtab->gentemp();
               if($1._type_ == NULL){
                 char str[] = "Identifier not declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
               }
               //If it is a boolean type, then convert into int.
               if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                  convbool2int(&($1));
               }
               //Assign this value to a temporary variable and then increment the value of the variable.
               curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $1.width;
               emit($$.loc->_name_,$1.loc->_name_);
               emit(_INCREMENT,$1.loc->_name_);
               if($1.is_array_id == 1){
                  emit($1.array->_name_,strr,_ARRAY_ACCESS,$1.loc->_name_);
                  $1.is_array_id = 0;
               }
               $$.is_array_id = 0;
               $$._type_ = $1._type_;
               $$.width = $1.width;
               $$.int_val = $1.int_val;
               $$.is_l_val = 1;
               $$.is_array_id = 0;
            } 
            else {
                 char str[] = "Invalid operation at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
             }  
          }
        | postfix_expression MINUS_MINUS {
             //If it is a l-value then this operation is valid else it is invalid.
             char *strr;
             if($1.is_l_val == 0){
               $$ = $1;
               //Get the variable from the symboltable.
               if($1.is_array_id == 1){
                  symtab* temp = curr_symtab->gentemp();
                  strr = strdup($1.loc->_name_);
                  emit(temp->_name_,$1.array->_name_,_ARRAY_DEREFERENCE,$1.loc->_name_);
                  $1.loc = temp;
                  curr_symtab->update($1.loc,$1._type_,$1.width,curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + $1.width;
               }
               else {
                  $1.loc = curr_symtab->lookup($1.strng);
                  $1._type_ = gettype($1.loc);
                  $1.width = getwidth($1.loc);
               }   
               $$.loc = curr_symtab->gentemp();
               if($1._type_ == NULL){
                 char str[] = "Identifier not declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
               }
               //If it is a boolean type, then convert into int.
               if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                  convbool2int(&($1));
               }
               curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $1.width;
               //Assign this value to a temporary variable and then decrement the value of the variable.
               emit($$.loc->_name_,$1.loc->_name_);
               emit(_DECREMENT,$1.loc->_name_);
               if($1.is_array_id == 1){
                  emit($1.array->_name_,strr,_ARRAY_ACCESS,$1.loc->_name_);
                  $1.is_array_id = 0;
                  $$.is_array_id = 0;
               }
               $$._type_ = $1._type_;
               $$.width = $1.width;
               $$.int_val = $1.int_val;
               $$.is_l_val = 1;
             }
             else {
                 char str[] = "Invalid operation at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
             }  
          }
        | PARANTHESIS_OPEN typename PARANTHESIS_CLOSE BRACES_OPEN initializer_list BRACES_CLOSE
        | PARANTHESIS_OPEN typename PARANTHESIS_CLOSE BRACES_OPEN initializer_list COMMA BRACES_CLOSE
        ;

argument_expression_list : assignment_expression {
             $$ = $1;
             if($1._type_ == NULL){
                char str[] = "Parameter variable not declared at line "; 
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //If the parameter is a boolean expression convert it into an integer expression.
             if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
               convbool2int(&($1));
             }
             //Add this parameter to the parameter list of the function.
             $$.parameter_list = make_func_list($1.loc,$1._type_,$1.width);
             $$.num_params = 1;
          }
        | argument_expression_list COMMA assignment_expression {
             $$ = $3;
             if($3._type_ == NULL){
                char str[] = "Parameter variable not declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //If the parameter is a boolean expression convert it into an integer expression.           
             if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
               convbool2int(&($3));
             }
             //Add this parameter to the parameter list of the function.
             $$.parameter_list = merge_func_list($1.parameter_list,make_func_list($3.loc,$3._type_,$3.width));
             $$.num_params = $1.num_params + 1;
          }
        ;

unary_expression : postfix_expression {
              //If the variable has not been obtained from symboltable, then obtain the symboltable entry for the variable.
              if($1.loc == NULL){
                $1.loc = curr_symtab->lookup($1.strng);
                $1._type_ = gettype($1.loc);
                $1.width = getwidth($1.loc);
              }
              $$ = $1;
          }
        | PLUS_PLUS unary_expression {
             //If it is a l-value then this operation is valid else it is invalid.
             char* strr;
             if($2.is_l_val == 0){
               $$ = $2;
               $$.loc = curr_symtab->gentemp();
               if($2.is_array_id == 1){
                 symtab* temp = curr_symtab->gentemp();
                 strr = strdup($2.loc->_name_);
                 emit(temp->_name_,$2.array->_name_,_ARRAY_DEREFERENCE,$2.loc->_name_);
                 $2.loc = temp;
                 curr_symtab->update($2.loc,$2._type_,$2.width,curr_symtab->offset);
                 curr_symtab->offset = curr_symtab->offset + $2.width;
               }
               if($2._type_ == NULL){
                 char str[] = "Identifier not declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
               }
               //If it is a boolean type, then convert into int.
               if($2._type_ != NULL && !strcmp($2._type_->var_type,"bool")){
                 convbool2int(&($2));
               } 
               curr_symtab->update($$.loc,$2._type_,$2.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $2.width;
               //Increment the value of the variable and then assign this value to a temporary variable.
               emit(_INCREMENT,$2.loc->_name_);
               emit($$.loc->_name_,$2.loc->_name_);
               if($2.is_array_id == 1){
                  emit($2.array->_name_,strr,_ARRAY_ACCESS,$2.loc->_name_);
                  $2.is_array_id = 0;
                  $$.is_array_id = 0;
               }
               $$._type_ = $2._type_;
               $$.width = $2.width;
               $$.int_val = $2.int_val + 1;
               $$.is_l_val = 1;
            }
            else {
                 char str[] = "Invalid operation at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
             }   
          }
        | MINUS_MINUS unary_expression {
             //If it is a l-value then this operation is valid else it is invalid.
             char *strr;
             if($2.is_l_val == 0){
               $$ = $2;
               $$.loc = curr_symtab->gentemp();
               if($2.is_array_id == 1){
                 symtab* temp = curr_symtab->gentemp();
                 strr = strdup($2.loc->_name_);
                 emit(temp->_name_,$2.array->_name_,_ARRAY_DEREFERENCE,$2.loc->_name_);
                 $2.loc = temp;
                 curr_symtab->update($2.loc,$2._type_,$2.width,curr_symtab->offset);
                 curr_symtab->offset = curr_symtab->offset + $2.width;
               }
               if($2._type_ == NULL){
                 char str[] = "Identifier not declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
               }
               //If it is a boolean type, then convert into int.
               if($2._type_ != NULL && !strcmp($2._type_->var_type,"bool")){
                 convbool2int(&($2));
               }
               curr_symtab->update($$.loc,$2._type_,$2.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $2.width;
               //Decrement the value of the variable and then assign this value to a temporary variable.
               emit(_DECREMENT,$2.loc->_name_);
               emit($$.loc->_name_,$2.loc->_name_);
               if($2.is_array_id == 1){
                  emit($2.array->_name_,strr,_ARRAY_ACCESS,$2.loc->_name_);
                  $2.is_array_id = 0;
                  $$.is_array_id = 0;
               }
               $$._type_ = $2._type_;
               $$.width = $2.width;
               $$.int_val = $2.int_val - 1;
               $$.is_l_val = 1;
            }
            else {
                 char str[] = "Invalid operation at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
             }   
          }
        | unary_operator cast_expression { 
              $$.loc = curr_symtab->gentemp();
              //If it is a boolean type, then convert into int.
              if($2.is_array_id == 1){
                 symtab* temp = curr_symtab->gentemp();
                 emit(temp->_name_,$2.array->_name_,_ARRAY_DEREFERENCE,$2.loc->_name_);
                 $2.loc = temp;
                 $2.is_array_id = 0;
                 curr_symtab->update($2.loc,$2._type_,$2.width,curr_symtab->offset);
                 curr_symtab->offset = curr_symtab->offset + $2.width;
              }
              if($2._type_ != NULL && !strcmp($2._type_->var_type,"bool")){
                convbool2int(&($2));
              }
              if($2._type_ == NULL){
                char str[] = "Identifier not declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              curr_symtab->update($$.loc,$2._type_,$2.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $2.width;
              switch(unary_operator_type){
                case 1 : {
                  //If the operation is referencing then the new type will be a pointer to the old type.
                  emit($$.loc->_name_,$2.loc->_name_,_REFERENCE);
                  _type* t = new _type;
                  t->var_type = strdup("ptr");
                  t->_next_ = $2._type_;
                  $$._type_ = t;
                  $$.width = 4;
                  $$.is_l_val = 1;
                  break;
                }
                case 2 : {
                  //This unary operatiom is valid for pointer type only.
                  if(strcmp($2._type_->var_type,"ptr")){
                    char str[] = "Operator should be a pointer at line ";
                    char temps[33];
                    sprintf(temps,"%d",line_num);
                    strcat(str,temps);
                    yyerror(str);
                    exit(1);
                  }
                  //If the operation is dereferencing then the new type will be dereferenced type of the old type.
                  $$._type_ = $2._type_->_next_;
                  $$.pointer = $2.loc;
                  $$.is_pointer_type = 1;
                  if(!strcmp($$._type_->var_type,"double")){
                    $$.width = 8;
                  }
                  else if(!strcmp($$._type_->var_type,"ptr")){
                    $$.width = 4;
                  }
                  else if(!strcmp($$._type_->var_type,"int")){
                    $$.width = 4;
                  }
                  else if(!strcmp($$._type_->var_type,"char")){
                    $$.width = 1;
                  }
                  $$.is_l_val = 0;
                  emit($$.loc->_name_,$2.loc->_name_,_DEREFERENCE);
                  break;
                }
                case 3 : {
                  //Assign the type to be same as the cast expression.
                  $$._type_ = $2._type_;
                  $$.width = $2.width;
                  $$.is_l_val = 1;
                  emit($$.loc->_name_,$2.loc->_name_,_UNARY_PLUS);
                  break;
                }
                case 4 : {
                  //Assign the type to be same as the cast expression.
                  $$._type_ = $2._type_;
                  $$.width = $2.width;
                  $$.is_l_val = 1;
                  emit($$.loc->_name_,$2.loc->_name_,_UNARY_MINUS);
                  $$.int_val = -$2.int_val;
                  break;
                }
                case 5 : {
                  //Assign the type to be same as the cast expression.
                  $$._type_ = $2._type_;
                  $$.width = $2.width;
                  $$.is_l_val = 1;
                  emit($$.loc->_name_,$2.loc->_name_,_COMPLEMENT);
                  $$.int_val = ~($2.int_val);
                  break;
                }
                case 6 : {
                  //Assign the type to be same as the cast expression.
                  $$._type_ = $2._type_;
                  $$.width = $2.width;
                  $$.is_l_val = 1;
                  emit($$.loc->_name_,$2.loc->_name_,_NOT);
                  $$.int_val = !($2.int_val);
                  break;
                }
              }
          }
        | SIZEOF unary_expression
        | SIZEOF PARANTHESIS_OPEN typename PARANTHESIS_CLOSE
        ;

unary_operator : AND {
              unary_operator_type = 1;
          }
        | STAR {
              unary_operator_type = 2;
          } 
        | PLUS {
              unary_operator_type = 3;
          }
        | MINUS {
              unary_operator_type = 4;
          }
        | COMPLEMENT {
              unary_operator_type = 5;
          }
        | NOT {
              unary_operator_type = 6;
          }
        ;

cast_expression : unary_expression {
              $$ = $1;
              $$.is_pointer_type = 0;
          }
        | PARANTHESIS_OPEN typename PARANTHESIS_CLOSE cast_expression {
              //If cast expression is a boolean expression , then convert it into an integer expression.
              if($4.is_array_id == 1){
                symtab* temp = curr_symtab->gentemp();
                emit(temp->_name_,$4.array->_name_,_ARRAY_DEREFERENCE,$4.loc->_name_);
                $4.loc = temp;
                $4.is_array_id = 0;
                curr_symtab->update($4.loc,$4._type_,$4.width,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + $4.width;
              } 
              if($4._type_ != NULL && !strcmp($4._type_->var_type,"bool")){
                convbool2int(&($4));
              }
              //Typename/Casting can only be done to fundamental data types like int,char or double.
              //Valid casting are int to double/char,char to double/int and double to char/int.
              if(!strcmp($2._type_->var_type,"int")){
                if(!strcmp($4._type_->var_type,"char")){
                   convchar2int(&($4));
                } 
                else if(!strcmp($4._type_->var_type,"double")){
                   convdouble2int(&($4));
                }
                else if(!strcmp($4._type_->var_type,"int")){
                   
                }
                else {
                  char str[] = "Invalid cast operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
              }
              else if(!strcmp($2._type_->var_type,"char")){
                if(!strcmp($4._type_->var_type,"int")){
                   convint2char(&($4));
                } 
                else if(!strcmp($4._type_->var_type,"double")){
                   convdouble2int(&($4));
                   convint2char(&($4));
                }
                else if(!strcmp($4._type_->var_type,"char")){
                   
                }
                else {
                  char str[] = "Invalid cast operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
              }
              else if(!strcmp($2._type_->var_type,"double")){
                if(!strcmp($4._type_->var_type,"int")){
                   convint2double(&($4));
                } 
                else if(!strcmp($4._type_->var_type,"char")){
                   convchar2int(&($4));
                   convint2double(&($4));
                }
                else if(!strcmp($4._type_->var_type,"double")){
                   
                }
                else {
                  char str[] = "Invalid cast operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
              }
              else {
                  char str[] = "Invalid cast operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
              }
              $$ = $4;
              $$.is_pointer_type = 0;
          }
        ;

multiplicative_expression : cast_expression {
              if($1.is_array_id == 1){
                symtab* temp = curr_symtab->gentemp();
                emit(temp->_name_,$1.array->_name_,_ARRAY_DEREFERENCE,$1.loc->_name_);
                $1.loc = temp;
                $1.is_array_id = 0;
                curr_symtab->update($1.loc,$1._type_,$1.width,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + $1.width;
              }
              $$ = $1;
          }
        | multiplicative_expression STAR cast_expression { 
              //Multiplication operation is not valid for pointers.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"ptr")){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"ptr")){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the product into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_MULT,$3.loc->_name_);
              $$.int_val = $1.int_val * $3.int_val;
              $$._type_ = $1._type_;
          }
        | multiplicative_expression DIVIDE cast_expression {
              //Division operation is not valid for pointers.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"ptr")){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"ptr")){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_DIVIDE,$3.loc->_name_);
              //As division by zero is not allowed, the int_val which is required for index of an array is made negative 
              //which is not allowed.
              if($3.int_val != 0){
                $$.int_val = $1.int_val / $3.int_val;
              }
              else {
                $$.int_val = -1;
              }
              $$._type_ = $1._type_;
          }
        | multiplicative_expression MODULO cast_expression {
              //Print error if the identifiers have not been declared.
              if($1._type_ == NULL || $3._type_ == NULL){
                 char str[] = "Variable has not been declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
              }
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Modulus operation is defined for integer/character/boolean operations only.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                 char s[] = "Operands for modulus should be integer at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(s,temps);
                 yyerror(s);
                 exit(1);
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_MODULO,$3.loc->_name_);
              if($3.int_val != 0){
                $$.int_val = $1.int_val % $3.int_val;
              }
              else {
                $$.int_val = -1;
              }
              $$._type_ = $1._type_;
          }
        ;

additive_expression : multiplicative_expression {
              $$ = $1;
          }
        | additive_expression PLUS multiplicative_expression { 
              //Addition operation is not valid if both operands are pointers.
              if(($1._type_ != NULL && !strcmp($1._type_->var_type,"ptr")) && ($3._type_ != NULL && !strcmp($3._type_->var_type,"ptr"))){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              //Addition operation is not valid if one operand is pointer and another is double expression.
              if((!strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"double")) || (!strcmp($3._type_->var_type,"ptr") && !strcmp($1._type_->var_type,"double"))){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              //Addition operation is valid if one operand is pointer and another is character/integer expression.
              if(!strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              if(!strcmp($3._type_->var_type,"ptr") && !strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the sum into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_PLUS,$3.loc->_name_);
              $$.int_val = $1.int_val + $3.int_val;
              $$._type_ = $1._type_;
          }
        | additive_expression MINUS multiplicative_expression { 
              //Subtraction operation is not valid if both operands are pointers.
              if(($1._type_ != NULL && !strcmp($1._type_->var_type,"ptr")) && ($3._type_ != NULL && !strcmp($3._type_->var_type,"ptr"))){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1); 
              }
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              //Subtraction operation is not valid if one operand is pointer and another is double expression.
              if((!strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"double")) || (!strcmp($3._type_->var_type,"ptr") && !strcmp($1._type_->var_type,"double"))){
                char s[] = "Invalid operation on pointer type variable at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              //Subtraction operation is valid if one operand is pointer and another is character/integer expression.
              if(!strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              if(!strcmp($3._type_->var_type,"ptr") && !strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the difference into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_MINUS,$3.loc->_name_);
              if($$.int_val != 0){
                $$.int_val = $1.int_val - $3.int_val;
              } 
              $$._type_ = $1._type_;
          }
        ;

shift_expression : additive_expression {
              $$ = $1;
          }
        | shift_expression SHIFT_LEFT additive_expression { 
              //This operation requires both types to be either boolean or character or integer expressions.
              if($1._type_ == NULL || $3._type_ == NULL){
                 char str[] = "Variable has not been declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
              }
              //Convert boolean expression into an integer expression.
              if(!strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Both operands have to be of integer type at this point for shift operation to be valid.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                 char s[] = "Shift amount and value to be shifted should be integer at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(s,temps);
                 yyerror(s);
                 exit(1);
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_SHIFT_LEFT,$3.loc->_name_);
              $$.int_val = $1.int_val << $3.int_val;
              $$._type_ = $1._type_;
          }
        | shift_expression SHIFT_RIGHT additive_expression { 
              //This operation requires both types to be either boolean or character or integer expressions.
              if($1._type_ == NULL || $3._type_ == NULL){
                 char str[] = "Variable has not been declared at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(str,temps);
                 yyerror(str);
                 exit(1);
              }
              //Convert boolean expression into an integer expression.
              if(!strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Both operands have to be of integer type at this point for shift operation to be valid.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                 char s[] = "Shift amount and value to be shifted should be integer at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(s,temps);
                 yyerror(s);
                 exit(1);
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Create a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_SHIFT_RIGHT,$3.loc->_name_);
              $$.int_val = $1.int_val >> $3.int_val;
              $$._type_ = $1._type_;
          }
        ;                

relational_expression : shift_expression {
              $$ = $1;
          }
        | relational_expression LESS shift_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type) || p->size != q->size){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              } 
              //Make truelist as nextinstr where if E1 < E2 is emitted with a dangling goto.       
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_LESS,$3.loc->_name_);
              emit(_GOTO,str);
          }
        | relational_expression GREATER shift_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type)){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Make truelist as nextinstr where if E1 > E2 is emitted with a dangling goto.
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_GREATER,$3.loc->_name_);
              emit(_GOTO,str);
          }
        | relational_expression LESS_EQUAL shift_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type)){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Make truelist as nextinstr where if E1 <= E2 is emitted with a dangling goto.
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_LESS_EQUAL,$3.loc->_name_);
              emit(_GOTO,str);
          }
        | relational_expression GREATER_EQUAL shift_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type)){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Make truelist as nextinstr where if E1 >= E2 is emitted with a dangling goto.
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_GREATER_EQUAL,$3.loc->_name_);
              emit(_GOTO,str);
          }
        ;

equality_expression : relational_expression {
              $$ = $1;
          }
        | equality_expression IS_EQUAL relational_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type)){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Make truelist as nextinstr where if E1 == E2 is emitted with a dangling goto.
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_IS_EQUAL,$3.loc->_name_);
              emit(_GOTO,str);
          }
        | equality_expression NOT_EQUAL relational_expression {
              //Convert boolean expression into an integer expression.
              if($1._type_ != NULL && !strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if($3._type_ != NULL && !strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Check type of two operands and do implicit type casting if allowed.
              typecheck(&($1),&($3));
              _type *p = $1._type_;
              _type *q = $3._type_;
              //Check if the types of the two expression are same or not after implicit type casting.
              while(p != NULL && q != NULL){
                if(strcmp(p->var_type,q->var_type)){
                  char str[] = "Incompatible types for operation at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
                p = p->_next_;
                q = q->_next_;
              }
              if(p != NULL || q != NULL){
                char str[] = "Incompatible types for operation at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Make truelist as nextinstr where if E1 != E2 is emitted with a dangling goto.
              $$.truelist = makelist(nextinstr);
              //Make falselist as nextinstr + 1 where a dangling goto is emitted.
              $$.falselist = makelist(nextinstr + 1);
              //Make the type of the expression as boolean expression.
              _type* t = new _type;
              t->var_type = strdup("bool");
              t->_next_ = NULL;
              $$._type_ = t;
              char str[] = "...";
              emit(str,$1.loc->_name_,_IF_NOT_EQUAL,$3.loc->_name_);
              emit(_GOTO,str);
          }      
        ;      
              
AND_expression : equality_expression {
              $$ = $1;
          }
        | AND_expression AND equality_expression {
              if($1._type_ == NULL || $3._type_ == NULL){
                char str[] = "Variable has not been declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Convert boolean expression into an integer expression.
              if(!strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Only integer expressions are allowed for bitwise and operation.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                char s[] = "Operands of Bitwise And should be integer at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Generate a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_AND,$3.loc->_name_);
              $$.int_val = $1.int_val & $3.int_val;
              $$._type_ = $1._type_;
          }
        ;

exclusive_OR_expression : AND_expression {
              $$ = $1;
          }
        | exclusive_OR_expression XOR AND_expression { 
              if($1._type_ == NULL || $3._type_ == NULL){
                char str[] = "Variable has not been declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Convert boolean expression into an integer expression.
              if(!strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              //Only integer expressions are allowed for bitwise xor operation.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                 char s[] = "Operands of Bitwise Xor should be integer at line ";
                 char temps[33];
                 sprintf(temps,"%d",line_num);
                 strcat(s,temps);
                 yyerror(s);
                 exit(1);
              }
              else {
                  $$.loc = curr_symtab->gentemp();
                  $$.width = $1.width;
                  curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + $1.width;
                  //Generate a temporary and emit the result into the temporary variable.
                  emit($$.loc->_name_,$1.loc->_name_,_XOR,$3.loc->_name_);
                  $$.int_val = $1.int_val ^ $3.int_val;
                  $$._type_ = $1._type_;
              }
          }        
        ;

inclusive_OR_expression : exclusive_OR_expression {
              $$ = $1;   
          }     
        | inclusive_OR_expression OR exclusive_OR_expression {
              if($1._type_ == NULL || $3._type_ == NULL){
                char str[] = "Variable has not been declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              //Convert boolean expression into an integer expression.
              if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
              }
              if(!strcmp($1._type_->var_type,"bool")){
                convbool2int(&($1));
              }
              //Convert character expression into an integer expression.
              if(!strcmp($1._type_->var_type,"char")){
                convchar2int(&($1));
              }
              if(!strcmp($3._type_->var_type,"char")){
                convchar2int(&($3));
              }
              //Only integer expressions are allowed for bitwise or operation.
              if(strcmp($1._type_->var_type,"int") || strcmp($3._type_->var_type,"int")){
                char s[] = "Operands of Bitwise Or should be integer at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(s,temps);
                yyerror(s);
                exit(1);
              }
              $$.loc = curr_symtab->gentemp();
              $$.width = $1.width;
              curr_symtab->update($$.loc,$1._type_,$1.width,curr_symtab->offset);
              curr_symtab->offset = curr_symtab->offset + $1.width;
              //Generate a temporary and emit the result into the temporary variable.
              emit($$.loc->_name_,$1.loc->_name_,_OR,$3.loc->_name_);
              $$.int_val = $1.int_val | $3.int_val;
              $$._type_ = $1._type_;
          }
        ;

logical_AND_expression : inclusive_OR_expression {
              $$ = $1;
          }
        | logical_AND_expression LOGICAL_AND M inclusive_OR_expression { // Grammar Augmented so as to backpatch the dangling truelist.
            if($1._type_ == NULL || $4._type_ == NULL){
              char str[] = "Variable has not been declared at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(str,temps);
              yyerror(str);
              exit(1);
            }
            //Convert into a boolean expression.
            if(strcmp($1._type_->var_type,"bool")){
              conv2bool(&($1));
            }
            if(strcmp($4._type_->var_type,"bool")){
              conv2bool(&($4));
            }
            //As if B1 is true in B1 && B2, we need to check B2. 
            backpatch($1.truelist,$3.instr);
            //The expression is true if both B1 and B2 are true.
            $$.truelist = $4.truelist;
            //The expression is false if only one of them is false.
            $$.falselist = merge($1.falselist,$4.falselist);
            $$._type_ = $1._type_;
          }
        ; 

logical_OR_expression : logical_AND_expression {
            $$ = $1;
          } 
        | logical_OR_expression LOGICAL_OR M logical_AND_expression  { // Grammar Augmented so as to backpatch the dangling falselist.
            if($1._type_ == NULL || $4._type_ == NULL){
              char str[] = "Variable has not been declared at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(str,temps);
              yyerror(str);
              exit(1);
            }
            //Convert into a boolean expression.
            if(strcmp($1._type_->var_type,"bool")){
              conv2bool(&($1));
            }
            if(strcmp($4._type_->var_type,"bool")){
              conv2bool(&($4));
            }
            //As if B1 is false in B1 && B2, we need to check B2.
            backpatch($1.falselist,$3.instr);
            //The expression is false if both B1 and B2 are false.
            $$.falselist = $4.falselist;
            //The expression is true if only one of them is true.
            $$.truelist = merge($1.truelist,$4.truelist);
            $$._type_ = $1._type_;
            _list* temp_list;
          }
        ;
        
M :       {
            $$.instr = nextinstr;     //M stores the current instruction. 
          }
        ; 
  
conditional_expression : logical_OR_expression {
            $$ = $1;
          }
        | logical_OR_expression N QUESTION_MARK M expression N COLON M conditional_expression { // Grammar augmented to backpatch 
             //truelist and falselist of expression1 and N's are added to add a goto to the new boolean expression
             //generated after conversion of expression1, else if expression1 is boolean, to add a redundant goto  
             $$ = $5;
             //Generate temporary for storing the value expression2 or expression3.
             $$.loc = curr_symtab->gentemp();
             curr_symtab->update($$.loc,$5._type_,$5.width,curr_symtab->offset);
             curr_symtab->offset = curr_symtab->offset + $5.width;
             //emit temporary variable assigned expression3.
             emit($$.loc->_name_,$9.loc->_name_);
             _list* temp_list = makelist(nextinstr);
             char str[] = "...";
             //emit goto for skipping assignment of expression2.
             emit(_GOTO,str);
             backpatch($6.nextlist,nextinstr);
             //emit temporary variable assigned expression2.
             emit($$.loc->_name_,$5.loc->_name_);
             temp_list = merge(temp_list,makelist(nextinstr));
             emit(_GOTO,str);
             backpatch($2.nextlist,nextinstr);
             //Conversion of expression1 into boolean expression.
             if(strcmp($1._type_->var_type,"bool")){
               conv2bool(&($1));
             }
             //backpatch truelist and falselist of expression1 to expression2 assignment and expression3 assignment. 
             backpatch($1.truelist,$4.instr);
             backpatch($1.falselist,$8.instr);
             backpatch(temp_list,nextinstr);  
          }
        ;

assignment_expression : conditional_expression {
            $$ = $1;
          }
        | unary_expression assignment_operator assignment_expression {
             //If the left hand side is not a l-value, print error message.
             if($1.is_l_val == 1){
                char str[] = "Assignment can only be done to a l-value at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             if($1._type_ == NULL || $3._type_ == NULL){
                char str[] = "Variable not declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //Handle array dereferencing by generating a temporary variable and equating to it.
             if($3.is_array_id == 1 && strcmp($3._type_->var_type,"array")){
               symtab* t = curr_symtab->gentemp();
               curr_symtab->update(t,$3._type_,$3.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $3.width;
               emit(t->_name_,$3.array->_name_,_ARRAY_DEREFERENCE,$3.loc->_name_);
               $3.loc = t;
               $3.is_array_id = 0;
             }
             //Conversion of boolean expression into character expression.
             if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
             }
             //Conversion from $3._type_ to $1._type_ for fundamental datatypes if it is permissible.
             if(!strcmp($1._type_->var_type,"int")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  convdouble2int(&($3));
                }
             }
             else if(!strcmp($1._type_->var_type,"char")){
                if(!strcmp($3._type_->var_type,"int")){
                  convint2char(&($3));
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  convdouble2int(&($3));
                  convint2char(&($3));
                }
             }
             else if(!strcmp($1._type_->var_type,"double")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                  convint2double(&($3));
                }
                else if(!strcmp($3._type_->var_type,"int")){
                  convint2double(&($3));
                }
             }
             //Print warning for assignment of character/integer to a pointer and error for assignment of a double to a pointer.
             else if(!strcmp($1._type_->var_type,"ptr")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                }
                if(!strcmp($3._type_->var_type,"int")){
                  char str[] = "Warning : Assignment of integer to a pointer at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  char str[] = "Assignment of double to a pointer at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
             }
             //Assignment of pointer to a non-pointer gives an error.
             if(strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"ptr")){
                char str[] = "Warning : Assignment of a pointer to a non-pointer type at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
             }
             if(!strcmp($1._type_->var_type,"array") || !strcmp($3._type_->var_type,"array")){
                char str[] = "Wrong assignment of array at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //If left side is an assignment to the variable pointed to by a pointer, opcode is _POINTER_ASSIGNMENT.
             if($1.is_pointer_type == 1){
               emit($1.pointer->_name_,$3.loc->_name_,_POINTER_ASSIGNMENT);
               $1.is_pointer_type = 0;
             }
             //If left side is an array, then opcode is _ARRAY_ACCESS.
             else if($1.is_array_id == 1){
                emit($1.array->_name_,$1.loc->_name_,_ARRAY_ACCESS,$3.loc->_name_);
             }
             //Normal Assignment after implicit type conversion.
             else {
                emit($1.loc->_name_,$3.loc->_name_);
             }
          }
        ;

assignment_operator : EQUAL 
        | STAR_EQUAL    
        | DIVIDE_EQUAL
        | MODULO_EQUAL
        | PLUS_EQUAL
        | MINUS_EQUAL
        | SHIFT_LEFT_EQUAL
        | SHIFT_RIGHT_EQUAL
        | AND_EQUAL
        | XOR_EQUAL
        | OR_EQUAL
        ;

expression : assignment_expression {
            $$ = $1;
          }
        | expression COMMA assignment_expression        
        ;

constant_expression : conditional_expression
        ;        

declaration : declaration_specifiers SEMI_COLON
        | declaration_specifiers init_declarator_list SEMI_COLON 
        ;   

declaration_specifiers : storage_class_specifier 
        | storage_class_specifier declaration_specifiers
        | type_specifier {
        	  //Store the type in global_type and size in global_width.
            $$ = $1;
            global_type = new _type;
            global_type->var_type = strdup($1._type_->var_type);
        	  global_type->_next_ = NULL;
            global_width = $1.width;
            if(flag_return_type == 0){
              return_type = new _type;
              return_type->var_type = strdup(global_type->var_type);
              return_type->_next_ = NULL;
              return_width = global_width;
              flag_return_type = 2;
            }
          }
        | type_specifier declaration_specifiers
        | type_qualifier
        | type_qualifier declaration_specifiers
        | function_specifier
        | function_specifier declaration_specifiers
        ;
                

init_declarator_list : init_declarator {
	          $$ = $1;
		      }
        | init_declarator_list COMMA init_declarator {
        	  $$ = $3;
          } 
        ;

init_declarator : declarator {
            _type* p = $1._type_;
            //If it is a function declaration, then current syboltable is global symboltable.
            if($1._type_ != NULL && !strcmp($1._type_->var_type,"function")){
              curr_symtab = Global_symtab;
              flag_return_type = 0;
              nextinstr--;
            }
            else {
              $1.loc = curr_symtab->lookup_new($1.strng);
              int flag = 1;
              //If the type of the variable is not a pointer, update the type and size in the symboltable.
              if(p == NULL){       
                curr_symtab->update($1.loc,global_type,global_width,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + global_width;
                _type *t,*q;
                q = new _type;
                $1._type_ = q;
                t = global_type;
                while(t->_next_ != NULL){
                  q->var_type = strdup(t->var_type);
                  q->size = t->size;
                  q->_next_ = new _type;
                  t = t->_next_;
                  q = q->_next_;
                }
                q->var_type = strdup(t->var_type);
                q->size = t->size;
                q->_next_ = NULL;
                $1.width = global_width;
              }
              else {
                if(!strcmp(p->var_type,"ptr")){
                  flag = 0;
                }
                while(p->_next_ != NULL){
                  p = p->_next_;
                  if(!strcmp(p->var_type,"ptr") && flag == 1){
                    flag = 2;
                  }
                }
                _type *t,*q;
                q = new _type;
                t = global_type;
                while(t->_next_ != NULL){
                  q->var_type = strdup(t->var_type);
                  q->size = t->size;
                  q->_next_ = new _type;
                  t = t->_next_;
                  q = q->_next_;
                }
                q->var_type = strdup(t->var_type);
                q->size = t->size;
                q->_next_ = NULL;
                p->_next_ = q;
                //If the type is a pointer.
                if(flag == 0){
                  curr_symtab->update($1.loc,$1._type_,4,curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + 4;
                }
                //If the type is array.
                else if(flag == 1){
                  curr_symtab->update($1.loc,$1._type_,($1.width * global_width),curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + ($1.width * global_width);
                }
                //If the type is array of pointers.
                else {
                  curr_symtab->update($1.loc,$1._type_,($1.width * 4),curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + ($1.width * 4);
                }             
              }
            }
            $$ = $1;
          }
        | declarator EQUAL initializer {       
             _type* p = $1._type_;
             //If it is a function declaration, then current syboltable is global symboltable.
             if($1._type_ != NULL && !strcmp($1._type_->var_type,"function")){
              curr_symtab = Global_symtab;
              flag_return_type = 0;
              nextinstr--;
             }
             else {
              $1.loc = curr_symtab->lookup_new($1.strng);
              int flag = 1;
              //If the type of the variable is not a pointer, update the type and size in the symboltable.
              if(p == NULL){       
                curr_symtab->update($1.loc,global_type,global_width,curr_symtab->offset);
                curr_symtab->offset = curr_symtab->offset + global_width;
                _type *t,*q;
                q = new _type;
                $1._type_ = q;
                t = global_type;
                while(t->_next_ != NULL){
                  q->var_type = strdup(t->var_type);
                  q->size = t->size;
                  q->_next_ = new _type;
                  t = t->_next_;
                  q = q->_next_;
                }
                q->var_type = strdup(t->var_type);
                q->size = t->size;
                q->_next_ = NULL;
                $1.width = global_width;
              }
              else {
                if(!strcmp(p->var_type,"ptr")){
                  flag = 0;
                }
                while(p->_next_ != NULL){
                  p = p->_next_;
                  if(!strcmp(p->var_type,"ptr") && flag == 1){
                    flag = 2;
                  }
                }
                _type *t,*q;
                q = new _type;
                t = global_type;
                while(t->_next_ != NULL){
                  q->var_type = strdup(t->var_type);
                  q->size = t->size;
                  q->_next_ = new _type;
                  t = t->_next_;
                  q = q->_next_;
                }
                q->var_type = strdup(t->var_type);
                q->size = t->size;
                q->_next_ = NULL;
                p->_next_ = q;
                //If the type is a pointer.
                if(flag == 0){
                  curr_symtab->update($1.loc,$1._type_,4,curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + 4;
                  $1.width = 4;
                }
                //If the type is array.
                else if(flag == 1){
                  curr_symtab->update($1.loc,$1._type_,($1.width * global_width),curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + ($1.width * global_width);
                  $1.width = $1.width * global_width;
                }
                //If the type is array of pointers.
                else {
                  curr_symtab->update($1.loc,$1._type_,($1.width * 4),curr_symtab->offset);
                  curr_symtab->offset = curr_symtab->offset + ($1.width * 4);
                  $1.width = $1.width * 4;
                }             
              }
             }
             if($3._type_ == NULL){
                char str[] = "Variable not declared at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //Conversion of boolean expression into an integer expression.
             if(!strcmp($3._type_->var_type,"bool")){
                convbool2int(&($3));
             }
             if($3.is_array_id == 1 && strcmp($3._type_->var_type,"array")){
               symtab* t = curr_symtab->gentemp();
               curr_symtab->update(t,$3._type_,$3.width,curr_symtab->offset);
               curr_symtab->offset = curr_symtab->offset + $3.width;
               emit(t->_name_,$3.array->_name_,_ARRAY_DEREFERENCE,$3.loc->_name_);
               $3.loc = t;
               $3.is_array_id = 0;
             }
             //Fundamental type conversions from $3._type_ to $1._type_ which is permissible.
             if(!strcmp($1._type_->var_type,"int")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  convdouble2int(&($3));
                }
             }
             else if(!strcmp($1._type_->var_type,"char")){
                if(!strcmp($3._type_->var_type,"int")){
                  convint2char(&($3));
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  convdouble2int(&($3));
                  convint2char(&($3));
                }
             }
             else if(!strcmp($1._type_->var_type,"double")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                  convint2double(&($3));
                }
                else if(!strcmp($3._type_->var_type,"int")){
                  convint2double(&($3));
                }
             }
             //Warning if character/integer is assigned to a pointer and error if double is assigned to a pointer.
             else if(!strcmp($1._type_->var_type,"ptr")){
                if(!strcmp($3._type_->var_type,"char")){
                  convchar2int(&($3));
                }
                if(!strcmp($3._type_->var_type,"int")){
                  char str[] = "Warning : Assignment of integer to a pointer at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                }
                else if(!strcmp($3._type_->var_type,"double")){
                  char str[] = "Assignment of double to a pointer at line ";
                  char temps[33];
                  sprintf(temps,"%d",line_num);
                  strcat(str,temps);
                  yyerror(str);
                  exit(1);
                }
             }
             //Warning if a non-pointer is assigned to a pointer.
             if(strcmp($1._type_->var_type,"ptr") && !strcmp($3._type_->var_type,"ptr")){
                char str[] = "Warning : Assignment of a pointer to a non-pointer type at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
             }
             if(!strcmp($1._type_->var_type,"array") || !strcmp($3._type_->var_type,"array")){
                char str[] = "Wrong assignment of array at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
             }
             //Update the symboltable with initial values.
             if(!strcmp($3._type_->var_type,"int")){
               curr_symtab->update($1.loc,$3.int_val);
             }
             else if(!strcmp($3._type_->var_type,"double")){
               curr_symtab->update($1.loc,$3.double_val);
             }
             else if(!strcmp($3._type_->var_type,"char")){
               if($3.char_val != NULL){
                 curr_symtab->update($1.loc,$3.char_val);
               } 
             }
             $$ = $1;
             emit($1.loc->_name_,$3.loc->_name_);
          }
        ;

storage_class_specifier : EXTERN 
        | STATIC
        | AUTO
        | REGISTER 
        ;

type_specifier : VOID {
            $$._type_ = new _type;
            $$._type_->var_type = strdup("void");
            $$._type_->_next_ = NULL;
		      }
        | CHAR {
            $$.width = 1;
            $$._type_ = new _type;
            $$._type_->var_type = strdup("char");
            $$._type_->_next_ = NULL;
          }
        | SHORT 
        | INT {
            $$.width = 4;
            $$._type_ = new _type;
            $$._type_->var_type = strdup("int");
            $$._type_->_next_ = NULL;
          }
        | LONG 
        | FLOAT 
        | DOUBLE {
            $$.width = 8;
            $$._type_ = new _type;
            $$._type_->var_type = strdup("double");
            $$._type_->_next_ = NULL;
          }
        | SIGNED 
        | UNSIGNED 
        | _BOOL
        | _COMPLEX 
        | _IMAGINARY
        | enum_specifier
        ;

specifier_qualifier_list : type_specifier {
             $$ = $1;
          }
        | type_specifier specifier_qualifier_list
        | type_qualifier
        | type_qualifier specifier_qualifier_list
        ;

enum_specifier : ENUM BRACES_OPEN enumerator_list BRACES_CLOSE
        | ENUM identifier BRACES_OPEN enumerator_list BRACES_CLOSE
        | ENUM BRACES_OPEN enumerator_list COMMA BRACES_CLOSE
        | ENUM identifier BRACES_OPEN enumerator_list COMMA BRACES_CLOSE
        | ENUM identifier
        ;

enumerator_list : enumerator 
        | enumerator_list COMMA enumerator
        ;

enumerator : enumeration_constant
        | enumeration_constant EQUAL constant_expression 
        ;                

enumeration_constant : identifier {
  
          }
        ;

type_qualifier : CONST 
        | RESTRICT
        | VOLATILE
        ;

function_specifier : INLINE
        ;

declarator : direct_declarator {
            $$ = $1;
          }
        | pointer direct_declarator {
            $$ = $2;
            //If the type of direct_declarator is array then the new type is array of pointer.
            if($2._type_ != NULL && !strcmp($2._type_->var_type,"array")){
              _type* q = $2._type_;
              while(q->_next_ != NULL){
                q = q->_next_;
              }
              q->_next_ = $1._type_;
              $$._type_ = $2._type_;
            }
            else {
              _type* q = $1._type_;
              while(q->_next_ != NULL){
                q = q->_next_;
              }
              q->_next_ = $2._type_;
              $$._type_ = $1._type_;
            }
          }
        ;                               

direct_declarator : identifier {
            $$.strng = strdup($1);
            $$._type_ = NULL;
				    $$.width = 1;
            //To store the return type of the current function, flag_return_type is used.
            if(flag_return_type == 2 || flag_return_type == 3){
              flag_return_type = 1;
            }
			    }
	     |  PARANTHESIS_OPEN declarator PARANTHESIS_CLOSE {
	    		  $$ = $2;
	    	  }
        | direct_declarator BRACKET_OPEN BRACKET_CLOSE {
             $$ = $1;
             $$._type_ = new _type;
             $$._type_->var_type = strdup("array");
             $$._type_->size = 0;
             $$._type_->_next_ = NULL;
          }
        | direct_declarator BRACKET_OPEN type_qualifier_list BRACKET_CLOSE
        | direct_declarator BRACKET_OPEN assignment_expression BRACKET_CLOSE {
            $$.strng = strdup($1.strng);
            _type* p = new _type;
            _type* q;
            //If index is character expression, convert into an integer expression.
            if(!strcmp($3._type_->var_type,"char")){
               convchar2int(&($3));
            }
            //The expression of the index of array has to be an integer.
            if(strcmp($3._type_->var_type,"int")){
              char s[] = "Array indices have non-integer type at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(s,temps);
              yyerror(s);
              exit(1);
            }
            //Negative indices for array declaration is not allowed.
            if($3.int_val <= 0){
              char s[] = "Array size cannot be negative at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(s,temps);
              yyerror(s);
              exit(1);   
            }
        	  p->var_type = strdup("array");
            p->size = $3.int_val;
        	  p->_next_ = NULL;
        	  q = $1._type_;
        	  //Build the width of the array.
            if(q == NULL){
        	  	$$._type_ = p;
              $$.width = $3.int_val;
        	  }
        	  else {
        	  	while(q->_next_ != NULL){
                  q = q->_next_;
        	  	}
        	  	q->_next_ = p;
        	  	$$._type_ = $1._type_;
        	  	$$.width = $3.int_val * $1.width;
        	  }
           }
	      | direct_declarator BRACKET_OPEN type_qualifier_list assignment_expression BRACKET_CLOSE 
        | direct_declarator BRACKET_OPEN STATIC assignment_expression BRACKET_CLOSE 
	      | direct_declarator BRACKET_OPEN STATIC type_qualifier_list assignment_expression BRACKET_CLOSE 
        | direct_declarator BRACKET_OPEN type_qualifier_list STATIC assignment_expression BRACKET_CLOSE 
        | direct_declarator BRACKET_OPEN STAR BRACKET_CLOSE 
        | direct_declarator BRACKET_OPEN type_qualifier_list STAR BRACKET_CLOSE 
        | direct_declarator PARANTHESIS_OPEN parameter_type_list PARANTHESIS_CLOSE {
            _type* t = new _type;
            t->var_type = strdup("function");
            t->_next_ = NULL;
            Global_symtab->insert($1.strng,t,$3.num_params,$3.symbol_table_);
            curr_symtab = $3.symbol_table_;
            $$ = $1;
            $$._type_ = t;
            $$.strng = $1.strng;
            $$.symbol_table_ = $3.symbol_table_;
            emit(_FUNCTION_START,$1.strng);
          }
        | direct_declarator PARANTHESIS_OPEN PARANTHESIS_CLOSE {
            _type* t = new _type;
            t->var_type = strdup("function");
            t->_next_ = NULL;
            $$ = $1;
            $$.symbol_table_ = new symboltable;
            $$._type_ = t;
            $$.strng = $1.strng;
            Global_symtab->insert($1.strng,t,0,$$.symbol_table_);
            curr_symtab = $$.symbol_table_;
            emit(_FUNCTION_START,$1.strng);
          }
        | direct_declarator PARANTHESIS_OPEN identifier_list PARANTHESIS_CLOSE 
        ;

pointer : STAR {
             $$._type_ = new _type;
             $$._type_->var_type = strdup("ptr");
             $$._type_->_next_ = NULL;
             //If the return type of the function has a pointer, make the return type a pointer to the previous return type. 
             if(flag_return_type == 2){
              _type *p,*q;
              p = new _type;
              q = $$._type_;
              p->var_type = strdup(q->var_type);
              p->_next_ = return_type;
              return_type = p;
              flag_return_type = 3;
              return_width = 4; 
            }
          }
        | STAR type_qualifier_list
        | STAR pointer {
             $$ = $2;
             _type* p = new _type;
             p->var_type = strdup("ptr");
             p->_next_ = $2._type_;
             $$._type_ = p;
             //Make the return type pointer of the previous type and change the flag accordingly.
             if(flag_return_type == 3){
                _type *p;
                p = new _type;
                p->var_type = strdup("ptr");
                p->_next_ = return_type;
                return_type = p;
                return_width = 4;
             }
          }
        | STAR type_qualifier_list pointer
        ;

type_qualifier_list : type_qualifier
        | type_qualifier_list type_qualifier
        ;

parameter_type_list : parameter_list {
            $$ = $1;
          }
        | parameter_list COMMA ELLIPSIS {
            $$ = $1;
          }
        ;

parameter_list : parameter_declaration {
            //Make the new function's symboltable and insert the parameter into the symboltable.
            $$.symbol_table_ = new symboltable;
            $$.symbol_table_->insert($1.strng,$1._type_,$1.width);
            $$.num_params = 1;
          }
        | parameter_list COMMA parameter_declaration {
            //Make the new function's symboltable and insert the parameter into the symboltable.
            $$ = $1;
            $$.symbol_table_->insert($3.strng,$3._type_,$3.width);
            $$.num_params = $1.num_params + 1;
          }
        ;

parameter_declaration : declaration_specifiers declarator {
             //Create the type of the parameter.
             if($2._type_ == NULL){
               $$._type_ = $1._type_;
               $$.width = $1.width;
               $$.strng = strdup($2.strng);
             } 
             else {
               _type* p = $2._type_;
               int flag = 1;
               if(!strcmp(p->var_type,"ptr")){
                  flag = 0;
               }
               while(p->_next_ != NULL){
                  p = p->_next_;
                  if(!strcmp(p->var_type,"ptr")){
                    flag = 0;
                  }
              }
              p->_next_ = $1._type_;
              if(flag == 0){
                $$._type_ = $2._type_;
                $$.width = 4; 
                $$.strng = strdup($2.strng);
              }
              else {
                $$._type_ = $2._type_;
                $$.width = $2.width * $1.width;
                $$.strng = strdup($2.strng);
              }
             }
          }
        | declaration_specifiers {
            $$ = $1;
         }
        ;        

identifier_list : identifier {
          
          }
        | identifier_list COMMA identifier {

          }
        ;

typename : specifier_qualifier_list {
              $$ = $1;
          }
        ;

initializer : assignment_expression {
			         $$ = $1;
		      }   	
        | BRACES_OPEN initializer_list BRACES_CLOSE  
        | BRACES_OPEN initializer_list COMMA BRACES_CLOSE
        ;                        

initializer_list : initializer {
            $$ = $1;
          }
        | designation initializer 
        | initializer_list COMMA initializer
        | initializer_list COMMA designation initializer
        ;

designation : designator_list EQUAL              
        ;

designator_list : designator 
        | designator_list designator
        ;

designator : BRACKET_OPEN constant_expression BRACKET_CLOSE
        | DOT identifier 
        ;

statement : labeled_statement 
        | compound_statement  {
            $$ = $1;
          }      
        | expression_statement {
            $$ = $1;
          }
        | selection_statement {
            $$ = $1; 
          }
        | iteration_statement {
            $$ = $1;
          }
        | jump_statement {
            $$ = $1;
          }
        ;

labeled_statement : identifier COLON statement {
            
          }
        | CASE constant_expression COLON statement 
        | DEFAULT COLON statement 
        ;

compound_statement : BRACES_OPEN BRACES_CLOSE
        | BRACES_OPEN block_item_list BRACES_CLOSE {
            $$ = $2;
          }
        ;

block_item_list : block_item {
            $$ = $1;  
          }
        | block_item_list M block_item {
            if($1.nextlist != NULL){
              backpatch($1.nextlist,$2.instr);
            }
            $$.nextlist = $3.nextlist;
          }
        ;

block_item : declaration {
             $$ = $1;
             $$.nextlist = NULL;
          }
        | statement {
            $$ = $1;
          }
        ;     

expression_statement : SEMI_COLON 
        | expression SEMI_COLON {
            //If the expression is boolean expression, insert its truelist and falselist into the statement's nextlist.
            if($1.truelist != NULL && $1.falselist != NULL){
              $$.nextlist = merge($1.truelist,$1.falselist);
            }
            else if($1.truelist != NULL){
              $$.nextlist = $1.truelist;
            }
            else if($1.falselist != NULL){
              $$.nextlist = $1.falselist;
            }
            else {
              $$.nextlist = NULL;
            }
            
          }
        ;

N  :      {   //Grammar Augmented to emit a goto and store the line number in its nextlist.
              
              $$.nextlist = makelist(nextinstr);
              char str[] = "...";
              emit(_GOTO,str);
          }
        ;  

selection_statement : IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N %prec IFEND {
               _list* temp_list;
               //If the expression is not boolean, then convert the expression into boolean after emitting a goto to avoid
               //checking been done more than once. Backpatch the truelist to the instruction of M
               //and create the nextlist of this statement as merge of the false list of the expression and nextlist 
               //of the statement.
               if(strcmp($3._type_->var_type,"bool")){
                  backpatch($4.nextlist,nextinstr);
                  conv2bool(&($3));
                  temp_list = merge($7.nextlist,$8.nextlist);
                  backpatch($3.truelist,$6.instr);
                  $$.nextlist = merge(temp_list,$3.falselist);
               }
               else {
                  backpatch($4.nextlist,$6.instr);
                  backpatch($3.truelist,$6.instr);
                  temp_list = merge($3.falselist,$8.nextlist);
                  $$.nextlist = merge($7.nextlist,temp_list);
               }
          }
        | IF PARANTHESIS_OPEN expression N PARANTHESIS_CLOSE M statement N ELSE M statement {
                  _list* temp_list;
                  //If the expression is not boolean, then convert the expression into boolean after emitting a goto to avoid
                  //checking been done more than once. Backpatch the truelist to the instruction of M1 and falselist to the 
                  //instruction of M2 and create the nextlist of this statement as nextlist of N2 and nextlist of statement.
                  if(strcmp($3._type_->var_type,"bool")){
                    temp_list = makelist(nextinstr);
                    char str[] = "...";
                    emit(_GOTO,str);
                    backpatch($4.nextlist,nextinstr);
                    conv2bool(&($3));
                    temp_list = merge($7.nextlist,temp_list);
                    temp_list = merge($8.nextlist,temp_list);
                    $$.nextlist = merge(temp_list,$11.nextlist);
                    backpatch($3.truelist,$6.instr);
                    backpatch($3.falselist,$10.instr);
                  }
                  else {
                    temp_list = merge($7.nextlist,$8.nextlist);
                    $$.nextlist = merge(temp_list,$11.nextlist);
                    backpatch($4.nextlist,$6.instr);
                    backpatch($3.truelist,$6.instr);
                    backpatch($3.falselist,$10.instr);
                  }
          }
        | SWITCH PARANTHESIS_OPEN expression PARANTHESIS_CLOSE statement
        ;

iteration_statement : WHILE PARANTHESIS_OPEN M expression N PARANTHESIS_CLOSE M statement {
                _list* temp_list;            
                //Convert the expression into boolean and the nextlist of N has been backpatched to instruction of M2
                //and emit goto to instruction of M1.    
                if(strcmp($4._type_->var_type,"bool")){
                    backpatch($5.nextlist,nextinstr);
                    char s4[33];
                    sprintf(s4,"%d",$3.instr);
                    emit(_GOTO,s4);
                    conv2bool(&($4));
                    backpatch($8.nextlist,$3.instr);
                    backpatch($4.truelist,$7.instr);
                    $$.nextlist = $4.falselist;
                }
                else {
                    backpatch($8.nextlist,$3.instr);
                    backpatch($4.truelist,$7.instr);
                    backpatch($5.nextlist,$7.instr);
                    $$.nextlist = $4.falselist;
                    char s4[33];
                    sprintf(s4,"%d",$3.instr);
                    emit(_GOTO,s4);
                }     
          }            
        | DO M statement WHILE M PARANTHESIS_OPEN expression PARANTHESIS_CLOSE SEMI_COLON {
                //Convert the expression into boolean and the truelist of N has been backpatched to instruction of M1
                //and the nextlist of statement has been backpatched to instruction of M1.   
                if(strcmp($7._type_->var_type,"bool")){ 
                    conv2bool(&($7));
                }
                backpatch($7.truelist,$2.instr);
                backpatch($3.nextlist,$5.instr);
                $$.nextlist = $7.falselist;     
          }
        | FOR PARANTHESIS_OPEN expression_opt SEMI_COLON M expression_opt N SEMI_COLON M expression_opt N PARANTHESIS_CLOSE M statement {
             //If expression2 is not a boolean, convert it into a boolean and backpatch nextlist of statement to M2,
             //backpatch nextlist of N2 to M1 and backpatch truelist of expression2 into instruction of M3,
             //N1's goto is redundant if expression2 is boolean, else it is backpatched to nextinstr before converting 
             //expression2 into boolean.
             backpatch($11.nextlist,$5.instr);
             backpatch($14.nextlist,$9.instr);
             char str[33];
             sprintf(str,"%d",$9.instr);
             emit(_GOTO,str);
             if($6._type_ != NULL && strcmp($6._type_->var_type,"bool")){
               backpatch($7.nextlist,nextinstr);
               conv2bool(&($6));
             }
             else {
               backpatch($7.nextlist,$13.instr);
             }
             backpatch($6.truelist,$13.instr);
             $$.nextlist = $6.falselist;
          } 
        | FOR PARANTHESIS_OPEN declaration SEMI_COLON PARANTHESIS_CLOSE statement
        | FOR PARANTHESIS_OPEN declaration expression SEMI_COLON PARANTHESIS_CLOSE statement
        | FOR PARANTHESIS_OPEN declaration SEMI_COLON expression PARANTHESIS_CLOSE statement
        | FOR PARANTHESIS_OPEN declaration expression SEMI_COLON expression PARANTHESIS_CLOSE statement
        ;

expression_opt :             {
              $$._type_ = NULL;
          }
        | expression {
              $$ = $1;
          }
        ;

jump_statement : GOTO identifier SEMI_COLON
        | CONTINUE SEMI_COLON       
        | BREAK SEMI_COLON
        | RETURN SEMI_COLON {
            //Check if the return type of the function is void or not else print error.
            if(!strcmp(return_type->var_type,"void")){
              char str[] = "";
              emit(_RETURN_VOID,str);
            }
            else {
              char str[] = "Function expects non-void return type at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(str,temps);
              yyerror(str);
              exit(1);
            }
          }
        | RETURN expression SEMI_COLON {
            //Check if the return type matches with the return type of the function,then emit _RETURN else print an error message.
            if($2._type_ == NULL){
              char str[] = "Variable not declared at line ";
              char temps[33];
              sprintf(temps,"%d",line_num);
              strcat(str,temps);
              yyerror(str);
              exit(1);
            }
            _type *p,*q;
            p = return_type;
            q = $2._type_;
            while(p != NULL && q != NULL){
              if((!strcmp(p->var_type,"ptr") && !strcmp(q->var_type,"array")) || (!strcmp(p->var_type,"array") && !strcmp(q->var_type,"ptr"))){

              }
              else if(strcmp(p->var_type,q->var_type) || p->size != q->size){
                char str[] = "Function return type mismatch at line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
              }
              p = p->_next_;
              q = q->_next_;
            }
            if(p != NULL || q != NULL){
                char str[] = "Function return type mismatch at 2 line ";
                char temps[33];
                sprintf(temps,"%d",line_num);
                strcat(str,temps);
                yyerror(str);
                exit(1);
            }
            emit(_RETURN,$2.loc->_name_);
          }
        ;

%%

void yyerror(char s[])
{
   printf("%s\n",s);       
}

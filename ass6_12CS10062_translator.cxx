#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include "ass6_12CS10062_translator.h"
#include "y.tab.h"

using namespace std;

#ifdef YYDEBUG
extern int yydebug;
#endif

//Quad constructor for binary/unary operators.
Quad::Quad(OPCODE op,char* result1,char* argument1,char* argument2) : op_code(op)
{
	result = strdup(result1);
	arg1 = strdup(argument1);
	if(argument2 != 0){
		arg2 = strdup(argument2);
	}
}

//Quad constructor for assignment to integer operation.
Quad::Quad(OPCODE op,char* result1,int int_num) : op_code(op)
{
	result = strdup(result1);
	arg1 = new char[33];
	sprintf(arg1,"%d",int_num);
} 

//Quad constructor for assignment to floating number operation.
Quad::Quad(OPCODE op,char* result1,double double_num) : op_code(op)
{
	result = strdup(result1);
	arg1 = new char[65];
	sprintf(arg1,"%lf",double_num);
} 

//Quad constructor for goto and return operation.
Quad::Quad(OPCODE op,char* result1) : op_code(op)
{
	result = strdup(result1);
}

//This function updates the result member of the quad.
void Quad::update(char* result1)
{
	result = strdup(result1);
}

//Creates a new quad for binary/unary operators.
void emit(char *result,char* arg1,OPCODE op,char* arg2)
{
	Quad_array[nextinstr++] = new Quad(op,result,arg1,arg2);
}

//Creates a new quad for unary operators.
void emit(char *result,char* arg1,OPCODE op)
{
	Quad_array[nextinstr++] = new Quad(op,result,arg1);
}

//Creates a new quad for assignment operation.
void emit(char* result,char* arg1)
{
	Quad_array[nextinstr++] = new Quad(_COPY,result,arg1);
}

//Creates a new quad for assignment to integer operation.
void emit(char* result,int int_num)
{
	Quad_array[nextinstr++] = new Quad(_COPY,result,int_num);
}

void emit(char* result,double double_num)
{
	Quad_array[nextinstr++] = new Quad(_COPY,result,double_num);
}

//Creates a new quad for assignment to floating number operation.
void emit(OPCODE op,char* result)
{
	Quad_array[nextinstr++] = new Quad(op,result);
}

//prints a quad in suitable format.
void Quad::print()
{
	//Binary Operators.
	if(op_code <= _GREATER_EQUAL && op_code >= _PLUS){
		printf("%s = %s ",result,arg1);
		switch(op_code){
			case _PLUS : 
			{	
				printf("+");
				break;
			}
			case _MINUS : 
			{	
				printf("-");
				break;
			}
			case _MULT : 
			{	
				printf("*");
				break;
			}
			case _DIVIDE : 
			{	
				printf("/");
				break;
			}
			case _AND : 
			{	
				printf("&");
				break;
			}
			case _MODULO : 
			{	
				printf("%%");
				break;
			}
			case _SHIFT_LEFT : 
			{	
				printf("<<");
				break;
			}
			case _SHIFT_RIGHT : 
			{	
				printf(">>");
				break;
			}
			case _XOR : 
			{	
				printf("^");
				break;
			}
			case _OR : 
			{	
				printf("|");
				break;
			}
			case _LOGICAL_AND : 
			{	
				printf("&&");
				break;
			}
			case _LOGICAL_OR : 
			{	
				printf("||");
				break;
			}
			case _LESS : 
			{	
				printf("<");
				break;
			}
			case _GREATER : 
			{	
				printf(">");
				break;
			}
			case _IS_EQUAL : 
			{	
				printf("==");
				break;
			}
			case _NOT_EQUAL : 
			{	
				printf("!=");
				break;
			}
			case _LESS_EQUAL : 
			{	
				printf("<=");
				break;
			}
			case _GREATER_EQUAL : 
			{	
				printf(">=");
				break;
			}
		}
		printf(" %s\n",arg2);
	} 
	//Unary Operator.
	else if(op_code <= _NOT && op_code >= _UNARY_MINUS){
		printf("%s = ",result);
		switch(op_code){
			case _UNARY_MINUS : {
				printf("-");
				break;
			}
			case _UNARY_PLUS  : {
				printf("+");
				break;
			}
			case _COMPLEMENT  : {
				printf("~");
				break;
			}
			case _NOT         : {
				printf("!");
				break;
			}
		}
		printf("%s\n",arg1);
	}
	//Conditional jump operators.
	else if(op_code >= _IF_LESS && op_code <= _IF_NOT_EQUAL){
		printf("if %s ",arg1);
		switch(op_code){
			case _IF_LESS    : {
				printf("<");
				break;
			}
			case _IF_GREATER : {
				printf(">");
				break;
			}
			case _IF_LESS_EQUAL: {
				printf("<=");
				break;
			}
			case _IF_GREATER_EQUAL: {
				printf(">=");
				break;
			}
			case _IF_IS_EQUAL: {
				printf("==");
				break;
			}
			case _IF_NOT_EQUAL: {
				printf("!=");
				break;
			}
		}
		printf(" %s goto %s\n",arg2,result);
	}
	else if(op_code == _IF_EXPRESSION){
		printf("if %s goto %s\n",arg1,result);
	}
	else if(op_code == _IF_NOT_EXPRESSION){
		printf("ifFalse %s goto %s\n",arg1,result);
	}
	//Unconditional jump.
	else if (op_code == _GOTO){
		printf("goto %s\n",result);
	}
	//Array Access.
	else if(op_code == _ARRAY_ACCESS){
		printf("%s[%s] = %s\n",result,arg1,arg2);
	}
	//Array dereferencing.
	else if(op_code == _ARRAY_DEREFERENCE){
		printf("%s = %s[%s]\n",result,arg1,arg2);
	}
	//assignment operator.
	else if(op_code == _COPY){
		printf("%s = %s\n",result,arg1);
	}
	//Procedure Call.
	else if(op_code == _PARAM){
		printf("param %s\n",result);
	}
	else if(op_code == _CALL){
		printf("%s = call %s, %s\n",result,arg1,arg2);
	}
	//Return Value
	else if(op_code == _RETURN_VOID){
		printf("return \n");
	}
	else if(op_code == _RETURN){
		printf("return %s\n",result);
	}
	//Address and Pointer Assignment Instructions.
	else if(op_code == _REFERENCE){
		printf("%s = &%s\n",result,arg1);
	}
	else if(op_code == _DEREFERENCE){
		printf("%s = *%s\n",result,arg1);
	}
	else if(op_code == _POINTER_ASSIGNMENT){
		printf("*%s = %s\n",result,arg1);
	}
	//Type Conversions.
	else if(op_code == _INT_TO_DOUBLE){
		printf("%s = int2double(%s)\n",result,arg1);
	}
	else if(op_code == _CHAR_TO_INT){
		printf("%s = char2int(%s)\n",result,arg1);
	}
	else if(op_code == _DOUBLE_TO_INT){
		printf("%s = double2int(%s)\n",result,arg1);
	}
	else if(op_code == _INT_TO_CHAR){
		printf("%s = int2char(%s)\n",result,arg1);
	}
	else if(op_code == _FUNCTION_START){
		printf("%s : \n",result);
	}
	else if(op_code == _FUNCTION_END){
		printf("end %s\n",result);
	}
	else if(op_code == _INCREMENT){
		printf("inc %s\n",result);	
	}
	else if(op_code == _DECREMENT){
		printf("dec %s\n",result);	
	}
}

//Constructor for class symboltable.
symboltable::symboltable() : offset(0)
{
	_constant_table_ = NULL;
}

//This function checks if the variable is present in symboltable or not, if it is present it returns the symboltable entry
//of its previous occurance else it creates a new entry with this variable name.
symtab* symboltable::lookup(char *s)
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_ && !strcmp(sp->_name_,s)){
			return sp;
		}
		if(!sp->_name_){
			sp->_name_ = strdup(s);
			sp->_size_ = 0;
			sp->_type_ = NULL;
			sp->_nested_table_ = NULL;
			sp->_activation_record_ = NULL;
			sp->_offset_ = 0;
			this->_num_entries_++;
			return sp;
		}
	}
	char str[] = "Too many symbols!!\n";
	yyerror(str);
	exit(1);
}

//This function checks if the variable is present in symboltable or not, if it is present it gives a redeclaration error
//else it creates a new entry with this variable name.
symtab* symboltable::lookup_new(char* s)
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_ && !strcmp(sp->_name_,s)){
			char s[] = "Redeclaration of variable at line ";
			char temps[33];
            sprintf(temps,"%d",line_num);
            strcat(s,temps);
            yyerror(s);
			exit(1);
		}
		if(!sp->_name_){
			sp->_name_ = strdup(s);
			sp->_size_ = 0;
			sp->_type_ = NULL;
			sp->_nested_table_ = NULL;
			sp->_activation_record_ = NULL;
			sp->_offset_ = 0;
			this->_num_entries_++;
			return sp;
		}
	}
	char str[] = "Too many symbols!!\n";
	yyerror(str);
	exit(1);	
}

//It creates a temporary variable and calls function lookup on that temporary variable name.
symtab* symboltable::gentemp()
{
	static int count = 0;
	char str[10];
	sprintf(str,"t%05d",count++);
	return lookup(str);
}

//Generates a constant label for each new string literal.
char* symboltable::generate_constant_label(char* s)
{
	static int constant_count = 0;
	char* str;
	char t[10];
	sprintf(t,".LC%05d",constant_count);
	constant_count++;
	str = strdup(t);
	constant_table *constants,*temp_constant_entry;
	temp_constant_entry = new constant_table;
	temp_constant_entry->label = strdup(t);
	temp_constant_entry->constant = strdup(s);
	temp_constant_entry->next = NULL;
	constants = this->_constant_table_;
	if(constants == NULL){
		this->_constant_table_ = temp_constant_entry;
	}
	else {
		while(constants->next != NULL){
			constants = constants->next;
		}
		constants->next = temp_constant_entry;
	}
	return str;	
}

//This prints the symboltable in a suitable format.
void symboltable::print()
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_){
			printf("%s , ",sp->_name_);
			_type* t = sp->_type_;
			if(t == NULL){
				printf("NULL , ");
			}
			else if(t->_next_ == NULL){
				printf(" %s , ",t->var_type);
				if(!strcmp(t->var_type,"int")){
					printf(" %d , ",sp->_init_val_.int_value);
				}
				else if(!strcmp(t->var_type,"double")){
					printf(" %lf , ",sp->_init_val_.double_value);
				}
				else if(!strcmp(t->var_type,"char")){
					printf(" %s , ",sp->_init_val_.string_lit);
				}
				else {
					printf(" NULL , ");
				}
			}
			else {
				while(t->_next_ != NULL) {
					printf("%s(%d , ",t->var_type,t->size);
					t = t->_next_;
				}
				printf("%s) , ",t->var_type);
				printf(" NULL , ");
			}
			printf("%d , %d , ",sp->_size_,sp->_offset_);
			if(sp->_nested_table_ == NULL){
				printf("NULL\n");
			}
			else {
				printf("Symbol Table of %s\n\n",sp->_name_);
			}
		}
	}
}

//This function updates a symboltable entry with type &t, size width and offset as offset.
void symboltable::update(symtab* symtab_entry,_type* t,int width,int offset)
{
	_type *p,*q;
	symtab_entry->_type_ = new _type;
	p = symtab_entry->_type_;
	if(t == NULL){
		symtab_entry->_type_ = NULL;
	}
	else {
		q = t;
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
	}	
	symtab_entry->_size_ = width;
	symtab_entry->_offset_ = offset;
}

//To initiliaze init_value with an integer value.
void symboltable::update(symtab* symtab_entry,int int_val)
{
	symtab_entry->_init_val_.int_value = int_val;
}

//To initiliaze init_value with a double value.
void symboltable::update(symtab* symtab_entry,double double_val)
{
	symtab_entry->_init_val_.double_value = double_val;
}

//To initiliaze init_value with a character value.
void symboltable::update(symtab* symtab_entry,char* char_val)
{
	symtab_entry->_init_val_.string_lit = strdup(char_val);
}

void symboltable::update(char* s,Activation_Record* ac_record_)
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_ && !strcmp(sp->_name_,s)){
			sp->_activation_record_= ac_record_;
			return;
		}
	}		
}

//This function checks if the variable is present in symboltable or not, if it is present it gives a redeclaration error
//else it creates a new entry with this variable name, type &t and size width.
void symboltable::insert(char *s,_type* t,int width)
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_ && !strcmp(sp->_name_,s)){
			char str[] = "Redeclaration of variable at line ";
			char temps[33];
            sprintf(temps,"%d",line_num);
            strcat(str,temps);
            yyerror(str);
			exit(1);
		}
		if(!sp->_name_){
			sp->_name_ = strdup(s);
			sp->_size_ = width;
			_type *p,*q;
			sp->_type_ = new _type;
			p = sp->_type_;
			q = t;
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
			sp->_offset_ = this->offset;
			this->offset = this->offset + width;
			sp->_activation_record_ = NULL;
			this->_num_entries_++;
			return ;
		}
	}
	char str[] = "Too many symbols!!\n";
	yyerror(str);
	exit(1);
}

//This function inserts a function into the symboltable.It checks if the variable is present in symboltable or not,
// if it is present then it matches the parameters with the previous declaration,if it is different then it gives a redeclaration error
//else it creates a new entry with this function name, type &t and number of parameters num_params and a pointer to its symboltable.
void symboltable::insert(char* s,_type* t,int num_params,symboltable* symbol_table)
{
	symtab* sp;
	for(sp = this->_symboltable_;sp < &(this->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_ && !strcmp(sp->_name_,s)){
			int flag = 0,i = 0;
			if(sp->_nested_table_ == NULL){
				flag = 1;
			}
			else {
				if(sp->num_params != num_params){
					flag = 1;
				}
				else {
					symtab* p = &(sp->_nested_table_->_symboltable_[i]);
					symtab* q = &(symbol_table->_symboltable_[i++]);
					while(p->_name_){
						_type *t1 = p->_type_;
						_type *t2 = q->_type_;
						while(t1 != NULL && t2 != NULL){
							if(strcmp(t1->var_type,t2->var_type) || t1->size != t2->size){
								flag = 1;
								break;
							}
							t1 = t1->_next_;
							t2 = t2->_next_;
						}
						if(t1 != NULL || t2 != NULL){
							flag = 1;
						}
						if(flag == 1){
							break;
						}
						p = &(sp->_nested_table_->_symboltable_[i]);
					    q = &(symbol_table->_symboltable_[i++]);
					}	
				}	
			}
			if(flag == 1){
				char str[] = "Redeclaration of function at line ";
				char temps[33];
            	sprintf(temps,"%d",line_num);
            	strcat(str,temps);
            	yyerror(str);
				exit(1);
			}
			else {
				sp->_nested_table_ = symbol_table;
				sp->_activation_record_ = NULL;
			}	
			return;
		}
		else if(!sp->_name_){
			sp->_name_ = strdup(s);
			sp->_nested_table_ = symbol_table;
			_type *p,*q;
			sp->_type_ = new _type;
			p = sp->_type_;
			q = t;
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
			sp->_offset_ = this->offset;
			sp->_activation_record_ = NULL;
			sp->num_params = num_params;
			this->_num_entries_++;
			return ;
		}
	}
	char str[] = "Too many symbols!!\n";
	yyerror(str);
	exit(1);
}

//This function returns the type of a symboltable entry.
_type* gettype(symtab* sym_entry)
{
	_type *p,*q,*temp;
	p = sym_entry->_type_;
	if(p == NULL){
		return NULL;
	}
	q = new _type;
	temp = q;
	while(p->_next_ != NULL){
		q->var_type = strdup(p->var_type);
		q->size = p->size;
		q->_next_ = new _type;
		q = q->_next_;
		p = p->_next_;
	}
	q->var_type = strdup(p->var_type);
	q->size = p->size;
	q->_next_ = NULL;
	return temp;
}

//This function returns the size of a symboltable entry.
int getwidth(symtab* sym_entry)
{
	return sym_entry->_size_;
}

//This function makes a list with index as i and returns a pointer to the list.
_list* makelist(int i)
{
	_list* new_list = new _list;
	new_list->_index_ = i;
	new_list->_next_ = NULL;
	return new_list;
}

//This function merges two lists p1 and p2 by concatenating p2 into p1.
_list* merge(_list* p1,_list* p2)
{
	if(p1 == NULL){
		return p2;
	}
	if(p2 == NULL){
		return p1;
	}
	_list* p = p1;
	while(p->_next_ != NULL){
		p = p->_next_;
	}
	p->_next_ = p2;
	return p1;
}	

//This function backpatches/updates the dangling gotos in the indices of the quad present in the list p with value i.
void backpatch(_list *p,int i)
{
	_list* iter = p;
	char s[33];
	while(iter != NULL){
		sprintf(s,"%d",i);
		Quad_array[iter->_index_]->update(s);
		iter = iter->_next_;
	}
}

//This function checks type between primitive datatypes and performs implicit up-conversions or promotions.
//Valid promotions are char to int,int to double,char to double.
void typecheck(e_attr* E1,e_attr* E2)
{
	if(E1->_type_ == NULL || E2->_type_ == NULL){
		char str[] = "Variable has not been declared at line ";
		char temps[33];
        sprintf(temps,"%d",line_num);
        strcat(str,temps);
        yyerror(str);
		exit(1);
	}
	_type *p,*q;
	p = E1->_type_;
	q = E2->_type_;
	if(!strcmp(p->var_type,"array") || !strcmp(q->var_type,"array")){
		char str[] = "Invalid operation at line ";
		char temps[33];
        sprintf(temps,"%d",line_num);
        strcat(str,temps);
        yyerror(str);
		exit(1);
	}
	if(p->_next_ == NULL && q->_next_ == NULL){
		if(!strcmp(p->var_type,q->var_type)){
			return;
		}
		else if(!strcmp(p->var_type,"int")){
			if(!strcmp(q->var_type,"double")){
				convint2double(E1);
				return;
			}
			else if(!strcmp(q->var_type,"char")){
				convchar2int(E2);
				return;
			}
		}
		else if(!strcmp(p->var_type,"char")){
			if(!strcmp(q->var_type,"int")){
				convchar2int(E1);
				return;
			}
			else if(!strcmp(q->var_type,"double")){		
				convchar2int(E1);
				convint2double(E1);
				return;
			}
		}
		else if(!strcmp(p->var_type,"double")){
			if(!strcmp(q->var_type,"int")){	
				convint2double(E2);
				return;
			}
			else if(!strcmp(q->var_type,"char")){
				convchar2int(E2);
				convint2double(E2);
				return;
			}
		}
	}
}

//This function converts an integer expression into a double expression and updates the type and size/width of the expression.
//If the expression is an array, the case is handled seperately as for array, we have to dereference.
void convint2double(e_attr* E)
{
	if(E->is_array_id == 1){
		symtab* temp = curr_symtab->gentemp();
        emit(temp->_name_,E->array->_name_,_ARRAY_DEREFERENCE,E->loc->_name_);
        E->loc = temp;
        E->is_array_id = 0;
	}
	symtab* t = curr_symtab->gentemp();
	emit(t->_name_,E->loc->_name_,_INT_TO_DOUBLE);
	E->loc = t;
	E->_type_->var_type = strdup("double");
	E->width = 8;
	curr_symtab->update(E->loc,E->_type_,8,curr_symtab->offset);
	curr_symtab->offset = curr_symtab->offset + 8;
}

//This function converts a character expression into an integer expression and updates the type and size/width of the expression.
//If the expression is an array, the case is handled seperately as for array, we have to dereference.
void convchar2int(e_attr* E)
{
	if(E->is_array_id == 1){
		symtab* temp = curr_symtab->gentemp();
        emit(temp->_name_,E->array->_name_,_ARRAY_DEREFERENCE,E->loc->_name_);
        E->loc = temp;
        E->is_array_id = 0;
	}
	symtab* t = curr_symtab->gentemp();
	emit(t->_name_,E->loc->_name_,_CHAR_TO_INT);
	E->loc = t;
	E->width = 4;
	E->_type_->var_type = strdup("int");
	curr_symtab->update(E->loc,E->_type_,4,curr_symtab->offset);
	curr_symtab->offset = curr_symtab->offset + 4;		
}

//This function converts a double expression into an integer expression and updates the type and size/width of the expression.
//If the expression is an array, the case is handled seperately as for array, we have to dereference.
void convdouble2int(e_attr* E)
{
	if(E->is_array_id == 1){
		symtab* temp = curr_symtab->gentemp();
        emit(temp->_name_,E->array->_name_,_ARRAY_DEREFERENCE,E->loc->_name_);
        E->loc = temp;
        E->is_array_id = 0;
	}
	symtab* t = curr_symtab->gentemp();
	emit(t->_name_,E->loc->_name_,_DOUBLE_TO_INT);
	E->loc = t;
	E->_type_->var_type = strdup("int");
	E->width = 4;
	curr_symtab->update(E->loc,E->_type_,4,curr_symtab->offset);
	curr_symtab->offset = curr_symtab->offset + 4;
}

//This function converts an integer expression into a double expression and updates the type and size/width of the expression.
//If the expression is an array, the case is handled seperately as for array, we have to dereference.
void convint2char(e_attr* E)
{	
	if(E->is_array_id == 1){
		symtab* temp = curr_symtab->gentemp();
        emit(temp->_name_,E->array->_name_,_ARRAY_DEREFERENCE,E->loc->_name_);
        E->loc = temp;
        E->is_array_id = 0;
	}
	symtab* t = curr_symtab->gentemp();
	emit(t->_name_,E->loc->_name_,_INT_TO_CHAR);
	E->loc = t;
	E->width = 1;
	E->_type_->var_type = strdup("char");
	curr_symtab->update(E->loc,E->_type_,1,curr_symtab->offset);
	curr_symtab->offset = curr_symtab->offset + 1;		
}

//This function converts a boolean expression into an integer expression by backpatching the truelists and the falselists
//and if boolean value is true, then new value is 1 else 0 (if it is false).
void convbool2int(e_attr* E)
{
	E->loc = curr_symtab->gentemp();
	E->_type_->var_type = strdup("int");
	E->width = 4;
	curr_symtab->update(E->loc,E->_type_,4,curr_symtab->offset);
	curr_symtab->offset = curr_symtab->offset + 4;
	backpatch(E->truelist,nextinstr);
	E->truelist = NULL;
	emit(E->loc->_name_,1);
	char s[33];
	sprintf(s,"%d",nextinstr + 2);
	emit(_GOTO,s);
	backpatch(E->falselist,nextinstr);
	E->falselist = NULL;
	emit(E->loc->_name_,0);
}

//This function converts any expression to a boolean expression,
// if it is not equal to 0 then it is true else it is false.
void conv2bool(e_attr* E)
{
	E->falselist = makelist(nextinstr);
	char str[] = "...";
	emit(str,E->loc->_name_,_IF_NOT_EXPRESSION);
	E->truelist = makelist(nextinstr);
	emit(_GOTO,str);
	E->_type_->var_type = strdup("bool");
	E->_type_->_next_ = NULL;
}

//This function makes a paramter list with the symboltable entry of the parameter, type and size of the parameter of a function.
func_list* make_func_list(symtab* sym_entry,_type* t,int width)
{
	func_list* new_list = new func_list;
	new_list->loc = sym_entry;
	_type *p,*q;
	p = new _type;
	new_list->_type_ = p;
	q = t;
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
	new_list->width = width;
	new_list->_next_ = NULL;
	return new_list;
}

//This function merges two parameter lists by concatenating p2 into func_list p1.
func_list* merge_func_list(func_list* p1,func_list* p2)
{
	if(p1 == NULL){
		return p2;
	}
	if(p2 == NULL){
		return p1;
	}
	func_list* p = p1;
	while(p->_next_ != NULL){
		p = p->_next_;
	}
	p->_next_ = p2;
	return p1;
}	

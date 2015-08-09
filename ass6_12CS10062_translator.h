#ifndef __ASS5_12CS10062_TRANSLATOR_H
#define __ASS5_12CS10062_TRANSLATOR_H

#define MAX_SIZE 100000

//enum for Op_codes for Quad array.
typedef enum{
	//binary operators.
	_PLUS = 1,
	_MINUS,
	_MULT,
	_DIVIDE,
	_AND,
	_MODULO,
	_SHIFT_LEFT,
	_SHIFT_RIGHT,
	_XOR,
	_OR,
	_LOGICAL_AND,
	_LOGICAL_OR,
	_LESS,
	_GREATER,
	_IS_EQUAL,
	_NOT_EQUAL,
	_LESS_EQUAL,
	_GREATER_EQUAL,

	//unary operators.
	_UNARY_MINUS,
	_UNARY_PLUS,
	_COMPLEMENT,
	_NOT,

	//Conditional jump operators.
	_IF_LESS,
	_IF_GREATER,
	_IF_LESS_EQUAL,
	_IF_GREATER_EQUAL,
	_IF_IS_EQUAL,
	_IF_NOT_EQUAL,
	_IF_EXPRESSION,
	_IF_NOT_EXPRESSION,
	//Unconditional jump.
	_GOTO,

	//assignment operator.
	_COPY,

	//Array Access and Dereferencing.
	_ARRAY_ACCESS,
	_ARRAY_DEREFERENCE,

	//Procedure Call.
	_PARAM,
	_CALL,

	//Return Value
	_RETURN_VOID,
	_RETURN,

	//Address and Pointer Assignment Instructions.
	_REFERENCE,
	_DEREFERENCE,
	_POINTER_ASSIGNMENT,

	//Type Conversions.
	_INT_TO_DOUBLE,
	_CHAR_TO_INT,
	_DOUBLE_TO_INT,
	_INT_TO_CHAR,

	//Function opcodes.
	_FUNCTION_START,
	_FUNCTION_END,

	//Inc and Dec operators.
	_INCREMENT,
	_DECREMENT
	
}OPCODE;

//class Quad with private members opcode, argument1 , argument2 and result.
class Quad{

public :

	OPCODE op_code;
	char *result,*arg1,*arg2;


	Quad(OPCODE op,char* result1,char* argument1,char* argument2 = 0); //Quad Constructor for binary or unary operations.
	Quad(OPCODE op,char* result1,int int_num); //Quad for assignment of integer into result variable.
	Quad(OPCODE op,char* result1,double double_num); //Quad for assignment of double into result variable.
	Quad(OPCODE op,char* result1); //Quad for opcodes like GOTO and Return.

	void update(char* result1); //Update function for backpatching result in opcode _GOTO.
	void print(); //Print function which prints a quad.
};

//A linked_list structure for storing type. member var_type stores base type like int,char,double,ptr or array.
//member size is used for arrays to store the size/index of the array and member next points to a _type object.
typedef struct _type{
	char* var_type;
	int size;
	struct _type* _next_;
}_type;

typedef union init{
	int int_value;
	double double_value;
	char* string_lit;
}init_value;

//forward declaration of symboltable.
class symboltable;
class Activation_Record;

//struct for a symboltable entry. name stores the name of the variable it stores.
// _type_ stores the type of the variable it stores. _size_ stores the size of the variable type.
// _offset_ stores the offset of the variable in the symboltable. _nested_table_ stores the symboltable
// of the function if this variable is a function, else it is NULL. num_params stores number of parameters
// if this variable is a function. init_val stores the initialization value of the variable.
typedef struct symtab{
	char* _name_;
	_type* _type_;
	int num_params;
	init_value _init_val_;
	int _size_;
	int _offset_;
	symboltable* _nested_table_;
	Activation_Record* _activation_record_;
}symtab;

//Structure for constant table.
typedef struct Constant_Table{
	char* label;
	char* constant;
	struct Constant_Table* next;
}constant_table;

//symboltable class which contains an array of symboltable entries and num_entries_ is the number of entries in it.
//offset stores the current offset of the symboltable.
class symboltable{
public : 
	symtab _symboltable_[MAX_SIZE];
	int _num_entries_;
	int offset;
	constant_table* _constant_table_;

	symboltable();
	symtab* lookup(char* s);      // function lookup is used for getting the symboltable entry with variable name s.
	symtab* lookup_new(char* s);  // function lookup_new is used for inserting a new variable into the symboltable
								  // after checking if it is declared for the first time.
	symtab* gentemp();            // function for generating and inserting a temporary variable in the symboltable.
	void print();                 // function for printing the symboltable.
	void update(symtab* symtab_entry,_type* t,int width,int offset); // function for updating different parameters 
								  // of a symboltable entry.
	void update(symtab* symtab_entry,int int_val);//To initiliaze init_value with an integer value.
	void update(symtab* symtab_entry,double double_val);//To initiliaze init_value with a double value.
	void update(symtab* symtab_entry,char* char_val);//To initiliaze init_value with a character value.
	void update(char* s,Activation_Record* ac_record_);
	void insert(char* s,_type* t,int width); // function for inserting a new variable with name s and type *t and 
								  // size width.
	void insert(char* s,_type* t,int num_params,symboltable* symbol_table); // function for inserting a function into
								  // a symboltable with num_params and symboltable of the function.
	char* generate_constant_label(char* s); // Generate a label for each new string literal.
};

//Structure for each activation record entry.
typedef struct Activation_Record_entry{
	char* _name_;
	_type* _type_;
	int _offset_;
	int _width_;
}activ_record_entry;

//Activation record class having total offset, return label of the function and constant table
//and the activation records.
class Activation_Record {

public : 

	activ_record_entry _activation_record[MAX_SIZE];
	int _total_offset_;
	char* return_label;
	constant_table* _constant_table;

	void generate_activation_record(symboltable* symtab,int num_params);
	int get_variable_offset(char* var_name);
	int get_variable_width(char* var_name);
	activ_record_entry* get_variable(char* var_name);
};

extern symboltable* Global_symtab; // Global Symboltable.
extern symboltable* curr_symtab;   // Current symboltable.
extern Quad* Quad_array[MAX_SIZE]; // Quad Array of size MAX_SIZE.
extern int nextinstr;              // Global variable nextinstr storing the count of Quads in Quad Array.
extern int line_num;			   // Global variable line_num storing the line number of the input program.
extern void yyerror(char* s);      // Function yyerror for printing an error.
extern _type* global_type;		   // Global variable global_type used for storing type while declaration.
extern int global_width;		   // Global variable global_width used for storing width while declaration.	

// structure list used for truelist, falselist and nextlist where _index_ stores the index of Quad Array and _next_
// points to the next object in the list.
typedef struct _list_{
	int _index_;
	struct _list_* _next_;
}_list;

// structure func_list used for parameter_list where loc stores the symboltable entry of the parameter,
// _type_ stores the type of the parameter, width stores the width of the parameter and _next_
// points to the next object in the parameter list.
typedef struct func_list{
	symtab* loc;
	_type* _type_;
	int width;
	struct func_list* _next_;
}func_list;

//loc stores a pointer to the symboltable entry of the variable it is referring to.
//_type_ is a pointer to a _type object storing the type of the variable it is referring to.
//width is the size of the variable it is referring to.
//is_l_val = 0 => it is a l-value , is_l_val = 1 => it is a r-value.
//is_array_id = 1 => it is an array . is_array_id = 0 => the postfix_expression is not an array.
//array stores a pointer to the symboltable entry of the array identifier.
//num_params stores the number of parameters if it is a function/parameter_list attribute.
//instr stores the nextinstruction for M type.
//parameter_list stores the list of parameters if it is a function call.
//symbol_table_ stores the symboltable while declaration/definition of the function.
//truelist stores the dangling indices of the symboltable entries which have same exits as the true exit of this expression.
//falselist stores the dangling indices of the symboltable entries which have same exits as the false exit of this expression.
//nextlist stores the dangling indices of the symboltable entries which have same exits as the exit of this statement.
//int_val stores integer value,double_val stores double value,strng is used for storing the name of the identifier (looked up later).
//is_pointer_type is a flag used for checking if the assignment is a pointer dereferencing assignment.
//pointer stores the symboltable entry of the pointer which has to be dereferenced.
typedef struct expression_attributes{
	symtab* loc;
	_type* _type_;
	_list *truelist;
	_list *falselist;
	_list *nextlist;
	int width;
	symtab* array;
	int is_array_id;
	int is_l_val;
	int num_params;
	int instr;
	func_list* parameter_list;
	symboltable* symbol_table_; 
	int is_pointer_type;
	symtab* pointer;
	int int_val;
	double double_val;
	char* strng;
	char* char_val;
}e_attr;

//Function emit() for binary 3-address codes.
void emit(char *result,char* arg1,OPCODE op,char* arg2);

//Function emit() for unary 3-address codes.
void emit(char *result,char* arg1,OPCODE op);

//Function emit() for copy 3-address code.
void emit(char* result,char* arg1);
void emit(char* result,int int_num);
void emit(char* result,double double_num);

//Function emit() for instructions which only have result like goto, param and return.
void emit(OPCODE op,char* result);

_list* makelist(int i); // Makes a list having index as i.
_list* merge(_list* p1,_list* p2); // Returns a merged list of two lists p1 and p2.
void backpatch(_list *p,int i); //backpatches indices in the list with value i.
void typecheck(e_attr* E1,e_attr* E2); //Checks type between E1 and E2 expressions (only up conversions done).
void convint2double(e_attr* E); //Converts expression E from int to double.
void convchar2int(e_attr* E); //Converts expression E from char to int.
void convbool2int(e_attr* E); //Converts expression E from bool to int.
void convdouble2int(e_attr* E); //Converts expression E from double to int.
void convint2char(e_attr* E); //Converts expression E from int to char.
void conv2bool(e_attr* E); //Converts expression E to bool.
_type* gettype(symtab* sym_entry); //Returns the type of variable stored in sym_entry of the current symboltable.
int getwidth(symtab* sym_entry); //Returns the width of variable stored in sym_entry of the current symboltable.
func_list* make_func_list(symtab* sym_entry,_type* t,int width); //Makes a func_list/parameter_list with a parameter having type t
											// and size width and symboltable entry sym_entry.
func_list* merge_func_list(func_list* p1,func_list* p2); //Merges two func_lists p1 and p2 and returns the merged func_list.

#endif
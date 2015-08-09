#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <map>
#include "ass6_12CS10062_translator.h"
#include "y.tab.h"

using namespace std;

//Global declarations.
Activation_Record* curr_activation_record;
Activation_Record* Global_activation_record = new Activation_Record; 
int goto_label_id = 0;
vector<pair<int,char *> > goto_labels; 
int num_functions = 0;
int parameters_size = 0;
vector<int> parameter_stack;

//A function that creates a new goto label for a quad instruction.
char* gengotolabel()
{
   char* s;
   char t[33];
   s = strdup(".L");
   sprintf(t,"%d",goto_label_id);
   goto_label_id++;
   strcat(s,t);
   return s; 
}

//This function searches if there is any goto label associated with Quad's index line_num.
int find_goto_label(int line_num)
{
	for(int i = 0;i < goto_labels.size();i++){
		if(goto_labels[i].first == line_num){
			return i;
		}
	}
	return -1;
}

//This function generates the corresponding activation record for a symboltable.
//Each entry in the activation record stores the variable name, its type,its size/width, 
//and its offset. Each parameter have a positive offset and size of 4.
//Each local/temporary variable have a negative offset.
//Return address has an offset of +4 and previous value of ebp has an offset of 0.
//The constant table of the symboltable is passed to the activation record.
void Activation_Record::generate_activation_record(symboltable* symtab_,int num_params)
{
	symtab* sp;
	int j = 0;
	sp = symtab_->_symboltable_;
	int parameter_offset = 8,local_offset = 0;
	for(int i = 0;sp < &(symtab_->_symboltable_[MAX_SIZE]) && i < num_params;i++){
		if(sp->_name_){	
			this->_activation_record[j]._name_ = strdup(sp->_name_);
			this->_activation_record[j]._type_ = gettype(sp);
			this->_activation_record[j]._width_ = sp->_size_;
			this->_activation_record[j]._offset_ = parameter_offset;
			parameter_offset = parameter_offset + 4;
			j++;
		}
		else {
			i--;
		}
		sp++;
	}
	char str[] = "return_address";
	this->_activation_record[j]._name_ = strdup(str);
	this->_activation_record[j]._width_ = 4;
	this->_activation_record[j]._offset_ = 4;
	j++;
	char str2[] = "base_pointer";
	this->_activation_record[j]._name_ = strdup(str2);
	this->_activation_record[j]._width_ = 4;
	this->_activation_record[j]._offset_ = 0;
	j++;
	for(;sp < &(symtab_->_symboltable_[MAX_SIZE]);sp++){
		if(sp->_name_){	
			this->_activation_record[j]._name_ = strdup(sp->_name_);
			this->_activation_record[j]._type_ = gettype(sp);
			local_offset = local_offset - sp->_size_;
            this->_activation_record[j]._offset_ = local_offset;
			this->_activation_record[j]._width_ = sp->_size_;
			j++;
		}
		else {
			
		}
	}	
	this->_total_offset_ = -local_offset;
	//Assign a new return label for the Activation Record for function epilogue.
    char* s;
	char t[33];
	s = strdup(".LE");
	sprintf(t,"%d",num_functions);
    //num_functions stores the number of functions encountered till now.
	num_functions++;
	strcat(s,t);
	this->return_label = strdup(s);
	this->_constant_table = symtab_->_constant_table_; 	
}

//This function returns the offset of the variable in the activation record
//if it is present in it.
int Activation_Record::get_variable_offset(char* var_name)
{
	activ_record_entry* ac;
	for(ac = this->_activation_record;ac < &(this->_activation_record[MAX_SIZE]);ac++){
		if(ac->_name_ && !strcmp(ac->_name_,var_name)){
          return ac->_offset_;
		}
	}
	char str[] = "The symbol doesnot exist\n";	
	yyerror(str);
	exit(1);
}

//This function returns the size of the variable in the activation record
//if it is present in it.
int Activation_Record::get_variable_width(char* var_name)
{
	activ_record_entry* ac;
	for(ac = this->_activation_record;ac < &(this->_activation_record[MAX_SIZE]);ac++){
		if(ac->_name_ && !strcmp(ac->_name_,var_name)){
          return ac->_width_;
		}
	}	
	char str[] = "The symbol doesnot exist\n";
	yyerror(str);
	exit(1);
}

//This function returns a pointer to the activation record entry of the variable
//in the activation record if it is present in it else it returns NULL.
activ_record_entry* Activation_Record::get_variable(char* var_name)
{
	activ_record_entry* ac;
	for(ac = this->_activation_record;ac < &(this->_activation_record[MAX_SIZE]);ac++){
		if(ac->_name_ && !strcmp(ac->_name_,var_name)){
          return ac;
		}
	}	
	return NULL;	
}

//This function translates the Three Address code into x86-assembly code.
void translate_into_assembly()
{
	for(int i = 1;i < nextinstr;i++){
        //If this line is a target label, print it.
        int line_num = find_goto_label(i);
        if(line_num != -1){
        	printf("%s : \n",goto_labels[line_num].second);
        }
        switch(Quad_array[i]->op_code){
        	//If the operation is addition, move arg1 into eax, move arg2 into edx and 
            //add the value of eax and edx and store in eax and move the value in eax to 
            //the location of the result. Cases for character handled separately.
            case _PLUS : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		activ_record_entry* ac_record = curr_activation_record->get_variable(Quad_array[i]->arg2);
        		if(ac_record == NULL){
        			int val = atoi(Quad_array[i]->arg2);
        			printf("\tmovl\t$%d, %%edx\n",val);
        		}
        		else if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\taddl\t%%edx, %%eax\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
        			printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		break;
        	}
            //If the operation is subtraction, move arg1 into eax, move arg2 into edx and 
            //subtract the value of edx from eax and store in eax and move the value in eax to 
            //the location of the result. Cases for character handled separately.
        	case _MINUS : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		activ_record_entry* ac_record = curr_activation_record->get_variable(Quad_array[i]->arg2);
        		if(ac_record == NULL){
        			int val = atoi(Quad_array[i]->arg2);
        			printf("\tmovl\t$%d, %%edx\n",val);
        		}
        		else if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\tsubl\t%%edx, %%eax\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
        			printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}		
        		break;
        	}
            //If the operation is multiplication, move arg1 into eax, move arg2 into edx and 
            //multiply the value of eax and edx and store in eax and move the value in eax to 
            //the location of the result. Cases for character handled separately.
        	case _MULT : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		activ_record_entry* ac_record = curr_activation_record->get_variable(Quad_array[i]->arg2);
        		if(ac_record == NULL){
        			int val = atoi(Quad_array[i]->arg2);
        			printf("\tmovl\t$%d, %%edx\n",val);
        		}
        		else if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\timull\t%%edx, %%eax\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
        			printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		break;
        	}
            //If the operation is divition, move arg1 into eax, move arg2 into ecx and 
            //divide the value of ecx from eax and move the value in eax(quotient) to 
            //the location of the result. Cases for character handled separately.
        	case _DIVIDE : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%ecx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%ecx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\tcltd\n");
        		printf("\tidivl\t%%ecx\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
        			printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		break;
        	}
            //If the operation is modulo, move arg1 into eax, move arg2 into ecx and 
            //divide the value of ecx from eax and move the value in edx(remainder) to 
            //the location of the result. Cases for character handled separately.
        	case _MODULO : {
      			if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
        			printf("\tmovsbl\t%d(%%ebp), %%ecx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%ecx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\tcltd\n");
        		printf("\tidivl\t%%ecx\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovl\t%%edx, %%eax\n");
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
        			printf("\tmovl\t%%edx, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}  		
        		break;
        	}
            //If the operation is unary minus, move arg1 into eax, negate the value and 
            //store in eax and move the value in eax to the location of the result. 
            //Cases for character handled separately.
        	case _UNARY_MINUS : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		printf("\tnegl\t%%eax\n");
        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
      				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));  		
        		}
        		break;
        	}
            //If the operation is copy, the cases of assignment to integer constant, character constant and string literals
            //are handled separately(they do not have any entry in activation record).
            //Copy the value from arg1 to eax and store the value in eax to the location in result.
        	case _COPY : {
        		activ_record_entry* ac_record = curr_activation_record->get_variable(Quad_array[i]->arg1);
        		if(ac_record == NULL){
        			if(Quad_array[i]->arg1[0] == '\''){
        				char str;
        				int j;
        				str = Quad_array[i]->arg1[1];
        				printf("\tmovb\t$%d, %d(%%ebp)\n",str,curr_activation_record->get_variable_offset(Quad_array[i]->result));
        			}
        			else if(Quad_array[i]->arg1[0] == '.'){
                        printf("\tmovl\t$%s, %d(%%ebp)\n",Quad_array[i]->arg1,curr_activation_record->get_variable_offset(Quad_array[i]->result));
        			}
        			else {
        				int val = atoi(Quad_array[i]->arg1);
        				printf("\tmovl\t$%d, %d(%%ebp)\n",val,curr_activation_record->get_variable_offset(Quad_array[i]->result));
        			}
        		}
        		else {	
	        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
	        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
	        		}
	        		else {
	        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
	        		}
	        		if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
	        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
	        		}
	        		else {
	        			printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
	        		}
	        	}	
        		break;
        	}
            //If the operation is if a < b goto L, move arg1 into eax and compare arg2 with eax and 
            //print jl result. Cases for character handled separately.
        	case _IF_LESS : {
        		if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        		printf("\tjl\t\t%s\n",Quad_array[i]->result);
        		break;
        	}
            //If the operation is if a > b goto L, move arg1 into eax and compare arg2 with eax and 
            //print jg result. Cases for character handled separately.
        	case _IF_GREATER : {
        	   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        	    printf("\tjg\t\t%s\n",Quad_array[i]->result);	
        	    break;
        	}
            //If the operation is if a <= b goto L, move arg1 into eax and compare arg2 with eax and 
            //print jle result. Cases for character handled separately.
			case _IF_LESS_EQUAL : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        	    printf("\tjle\t\t%s\n",Quad_array[i]->result);	
			    break;
			}
            //If the operation is if a >= b goto L, move arg1 into eax and compare arg2 with eax and 
            //print jge result. Cases for character handled separately.
			case _IF_GREATER_EQUAL : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        	    printf("\tjge\t\t%s\n",Quad_array[i]->result);
			    break;	
			}
            //If the operation is if a == b goto L, move arg1 into eax and compare arg2 with eax and 
            //print je result. Cases for character handled separately.
			case _IF_IS_EQUAL : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        	    printf("\tje\t\t%s\n",Quad_array[i]->result);	
			    break;
			}
            //If the operation is if a != b goto L, move arg1 into eax and compare arg2 with eax and
            //then print jne result. Cases for character handled separately.
			case _IF_NOT_EQUAL : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
        			printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1 && curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
					printf("\tcmpb\t%d(%%ebp), %%al\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));	
				}
				else {        		
        			printf("\tcmpl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
        		}
        	    printf("\tjne\t\t%s\n",Quad_array[i]->result);
			    break;	
			}
            //If the operation is if a == 0 goto L, compare arg1 with 0 and
            //print je result. Cases for character handled separately.
			case _IF_EXPRESSION : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
			   	   printf("\tcmpb\t$0, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
			   }
			   else {	
			   	   printf("\tcmpl\t$0, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        	   }
        	   printf("\tjne\t\t%s\n",Quad_array[i]->result);
			   break;
			}
            //If the operation is if a != 0 goto L, compare arg1 with 0 and
            //print jne result. Cases for character handled separately.
			case _IF_NOT_EXPRESSION : {
			   if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
			   	   printf("\tcmpb\t$0, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
			   }
			   else {	
			   	   printf("\tcmpl\t$0, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        	   }
        	   printf("\tje\t\t%s\n",Quad_array[i]->result);
			   break;
			}
            //If the operation is goto, emit jmp and the label stored in result field of Quad array. 
			case _GOTO : {
			   printf("\tjmp\t\t%s\n",Quad_array[i]->result);	
			   break;
			}
            //If the operation is array access. Two cases are the array is a parameter and 
            //the array is a local variable.
			case _ARRAY_ACCESS : {
				//If the array is a parameter variable to the function. Move the base address
                //of array stored in result into eax, move the offset of the array stored in arg1
                //into edx and add edx into eax, to get the address of the location of the index 
                //of the array stored in edx. Move the value in arg2 into edx.
                //Move the value of edx into (eax) (i.e. memory location of address stored in eax).
                if(curr_activation_record->get_variable_offset(Quad_array[i]->result) > 0){
					printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
						printf("\tmovsbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}
					printf("\taddl\t%%edx,%%eax\n");
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
						printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[i]->result);
					_type* p = ac_record_entry->_type_;
					while(p != NULL && (!strcmp(p->var_type,"array") || !strcmp(p->var_type,"ptr"))){
						p = p->_next_;
					}
					if(!strcmp(p->var_type,"char")){
						printf("\tmovb\t%%dl, (%%eax)\n");
					}
					else {
						printf("\tmovl\t%%edx, (%%eax)\n");
					}
				}
                //If the array is a local variable, move the array offset into eax and move the arg2 into edx
                //Move the contents of edx into the offset of eax of the array stored in result.
				else {
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
						printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}	
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
						printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[i]->result);
					_type* p = ac_record_entry->_type_;
					while(p != NULL && !strcmp(p->var_type,"array")){
						p = p->_next_;
					}
					if(!strcmp(p->var_type,"char")){
						printf("\tmovb\t%%dl, %d(%%ebp,%%eax)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
					}
					else {
						printf("\tmovl\t%%edx, %d(%%ebp,%%eax)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
					}
				}		
				break;
			}
            //If the operation is array dereference. Two cases if the array is a parameter variable 
            //or a local variable.
			case _ARRAY_DEREFERENCE : {
				//If the array is a parameter variable to the function. Move the base address
                //of array stored in arg1 into eax, move the offset of the array stored in arg2
                //into edx and add edx into eax, to get the address of the location of the index 
                //of the array stored in edx. Move the value stored in address of eax into eax.
                //Move the value of eax into location of result.
                if(curr_activation_record->get_variable_offset(Quad_array[i]->arg1) > 0){
					printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
						printf("\tmovsbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					printf("\taddl\t%%edx,%%eax\n");
					printf("\tmovl\t(%%eax), %%eax\n");
					if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
						printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
					}
					else {
						printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
					}
				}
                //If the array is a local variable, move the array offset into eax and move the value stored in offset
                //eax of the array into eax and move the value stored in eax into the location of the result.
				else {
					if(curr_activation_record->get_variable_width(Quad_array[i]->arg2) == 1){
						printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					else {
						printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg2));
					}
					activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[i]->arg1);
					_type* p = ac_record_entry->_type_;
					while(p != NULL && !strcmp(p->var_type,"array")){
						p = p->_next_;
					}
					if(!strcmp(p->var_type,"char")){
						printf("\tmovzbl\t%d(%%ebp,%%eax), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}
					else {
						printf("\tmovl\t%d(%%ebp,%%eax), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
					}
					if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
	        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
	        		}
	        		else {
	      				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));  		
	        		}
	        	}	
        		break;
			}
            //Move the address of arg1 into edx and move the address from eax
            //to location of the result.
			case _REFERENCE : {
				printf("\tleal\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				break;
			}
            //Move the value of arg1 into eax and store the value in address stored in eax into eax
            //Move the value from eax into location of result.
			case _DEREFERENCE : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[i]->arg1);
				_type* p = ac_record_entry->_type_;
				if(p != NULL && !strcmp(p->var_type,"ptr")){
					p = p->_next_;
				}
				if(!strcmp(p->var_type,"char")){
					printf("\tmovzbl\t(%%eax), %%eax\n");
				}
				else {
				    printf("\tmovzbl\t(%%eax), %%eax\n");	
				}
				if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
        			printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
        		}
        		else {
      				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));  		
        		}
				break;
			}
            //Move the value of address stored in result into eax and move the value to be stored
            //in arg2 into edx and store the value of edx into the 
            //location (eax) (i.e. address pointed to by eax).
			case _POINTER_ASSIGNMENT : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				if(curr_activation_record->get_variable_width(Quad_array[i]->arg1) == 1){
        			printf("\tmovzbl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
        		}
        		else {
      				printf("\tmovl\t%d(%%ebp), %%edx\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));  		
        		}
        		activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[i]->result);
				_type* p = ac_record_entry->_type_;
				if(p != NULL && !strcmp(p->var_type,"ptr")){
					p = p->_next_;
				}
				if(!strcmp(p->var_type,"char")){
					printf("\tmovb\t%%dl, (%%eax)\n");
				}
				else {
					printf("\tmovl\t%%edx, (%%eax)\n");
				}
				break;
			}
            //Copy the variable from arg1 to eax and eax to result. Type conversions not supported.
			case _INT_TO_DOUBLE : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				break;
			}
            //Copy the variable from arg1 to eax and eax to result. Type conversions not supported.
			case _CHAR_TO_INT : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				break;
			}
            //Copy the variable from arg1 to eax and eax to result. Type conversions not supported.
			case _DOUBLE_TO_INT : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				break;
			}
            //Copy the variable from arg1 to eax and eax to result. Type conversions not supported.
			case _INT_TO_CHAR : {
				printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->arg1));
				printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				break;
			}
            //If the operation is param. Enter the parameter into the parameter stack
            //as it has to be printed in reverse order.
			case _PARAM : {
			   parameter_stack.push_back(i); 
        	   break;
			}
            //If the operation is call, push the parameters into the stack(esp)
            //after moving into eax in reverse order.
			case _CALL : {
			    parameters_size = 0;
                //Push the parameters into stack in reverse order.
			    for(int k = parameter_stack.size() - 1;k >= 0;k--){
			   	  //If the parameter is a local variable.
                  if(curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result) <= 0){
                    activ_record_entry* ac_record_entry = curr_activation_record->get_variable(Quad_array[parameter_stack[k]]->result);
				    _type* p = ac_record_entry->_type_;
                    //If the parameter is of type array, copy the address of the array into eax
                    //and push into the stack.
				    if(p != NULL && !strcmp(p->var_type,"array")){
				  	  printf("\tleal\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result));
        	      	  parameters_size += 4;
				    }
                    //If the param is a string literal.
                    else if(Quad_array[parameter_stack[k]]->result[0] == '.'){
                      printf("\tmovl\t$%s, %%eax\n",Quad_array[parameter_stack[k]]->result);
                      parameters_size += 4;
                    } 
                    //If the param is a character.
                    else if(curr_activation_record->get_variable_width(Quad_array[parameter_stack[k]]->result) == 1){
                      printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result));
                      parameters_size += 4;
                    }
                    else {    
                      printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result));
                      parameters_size += 4;
                    }
                  }
                  //If the parameter is a local variable.
				  else {
                    //If the param is a string literal.
                    if(Quad_array[parameter_stack[k]]->result[0] == '.'){
				  	  printf("\tmovl\t$%s, %%eax\n",Quad_array[parameter_stack[k]]->result);
			   	  	  parameters_size += 4;
    				}
                    //If the param is a character.	
    			   	else if(curr_activation_record->get_variable_width(Quad_array[parameter_stack[k]]->result) == 1){
    			   	  printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result));
    			   	  parameters_size += 4;
    			   	}
    			   	else {	
    			   	  printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[parameter_stack[k]]->result));
            	      parameters_size += 4;
            	    }
                  }
                  //Push the parameter into the stack.
        	      printf("\tpushl\t%%eax\n");
        	    }
        	    parameter_stack.clear();
				printf("\tcall\t%s\n",Quad_array[i]->arg1);
				//Add the parameter size pushed into the stack to make the 
                //stack point to the previous location.
                if(parameters_size > 0){
					printf("\taddl\t$%d, %%esp\n",parameters_size);
				}
                //Move the return value stored in eax into the location of the result.
				if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
					printf("\tmovb\t%%al,%d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				}   
				else {
					printf("\tmovl\t%%eax,%d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));	
				}
				parameters_size = 0;
				break;
			}
            //If the operation is return, move the return value into eax and jump to return label
            //of the function(epilogue).
			case _RETURN : {
				if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
					printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				}
				else {
					printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
				}
				printf("\tjmp\t\t%s\n",curr_activation_record->return_label);
				break;
			}
            //If the operation is return void, jump to return label
            //of the function(epilogue).
			case _RETURN_VOID : {
				printf("\tjmp\t\t%s\n",curr_activation_record->return_label);
				break;	
			}
            //Function prologue.
        	case _FUNCTION_START : {
        	  symtab* temporary_loc = curr_symtab->lookup(Quad_array[i]->result);	
        	  curr_activation_record = temporary_loc->_activation_record_;
        	  curr_symtab = temporary_loc->_nested_table_;
        	  //Print the constants in the read only section from the constant table.
              if(curr_activation_record->_constant_table != NULL){
        	  	constant_table* constants = curr_activation_record->_constant_table;
        	  	printf("\t.section\t\t.rodata\n");
        	  	while(constants != NULL){
        	  		printf("%s: \n",constants->label);
        	  		printf("\t.string\t%s\n",constants->constant);
        	  		constants = constants->next;
        	  	}
        	  }
              //Push the ebp and allocate the total offset in the stack and allign 
              //stack to 16-byte boundary.
        	  printf("\t.text \n");
        	  printf("\t.globl %s \n",Quad_array[i]->result);
        	  printf("\t.type %s, @function \n",Quad_array[i]->result);
        	  printf("%s : \n",Quad_array[i]->result);
        	  printf("\tpushl\t%%ebp\n");
        	  printf("\tmovl\t%%esp,%%ebp\n");
              printf("\tandl\t$-16, %%esp\n");
        	  if(curr_activation_record->_total_offset_ > 0){
        	  	printf("\tsubl\t$%d,%%esp\n",curr_activation_record->_total_offset_);
        	  }
        	  break;
        	}
            //Function Epilogue.
        	case _FUNCTION_END : {
        		//Restore the previous stack value stored in base pointer(ebp).
                //Pop ebp and return from the function.
                printf("%s : \n",curr_activation_record->return_label);
        		printf("\tmovl\t%%ebp,%%esp\n");
                printf("\tpopl\t%%ebp\n");
                printf("\tret\n");
        		printf("\t.size %s, .-%s \n",Quad_array[i]->result,Quad_array[i]->result);
        		curr_activation_record = Global_activation_record;
        		curr_symtab = Global_symtab;
        		break;
        	}
            //Move the value to be incremented in eax and increment eax and move the incremented
            //value into the location of result. Cases for character handled separately.
            case _INCREMENT : {
                if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
                    printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                    printf("\tincl\t%%eax\n");
                    printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                }
                else {
                    printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                    printf("\tincl\t%%eax\n");
                    printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                }
                break;
            }
            //Move the value to be decremented in eax and decrement eax and move the decremented
            //value into the location of result. Cases for character handled separately.
            case _DECREMENT : {
                if(curr_activation_record->get_variable_width(Quad_array[i]->result) == 1){
                    printf("\tmovsbl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                    printf("\tdecl\t%%eax\n");
                    printf("\tmovb\t%%al, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                }
                else {
                    printf("\tmovl\t%d(%%ebp), %%eax\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                    printf("\tdecl\t%%eax\n");
                    printf("\tmovl\t%%eax, %d(%%ebp)\n",curr_activation_record->get_variable_offset(Quad_array[i]->result));
                } 
                break;  
            }
        }
    }
}
 
int main(int argc,char* argv[])
{
	#ifdef YYDEBUG
  	//yydebug = 1;
	#endif
    //Enter the functions printi, prints and readi in the Global symboltable.
	symboltable* symbol_table = new symboltable;
	_type* _type_ = new _type;
	_type_->var_type = strdup("int");
	_type_->_next_ = NULL;
	char s1[] = "i";
    symbol_table->insert(s1,_type_,4);
    char str[] = "ret_val";
    symbol_table->insert(str,_type_,4);
    _type_ = new _type;
	_type_->var_type = strdup("function");
	_type_->_next_ = NULL;
	char s2[] = "printi";
    Global_symtab->insert(s2,_type_,1,symbol_table);
    symbol_table = new symboltable;
	_type_ = new _type;
	_type_->var_type = strdup("ptr");
	_type_->_next_ = new _type;
	_type_->_next_->var_type = strdup("char");
	_type_->_next_->_next_ = NULL;
	char s3[] = "s";
    symbol_table->insert(s3,_type_,4);
    _type_ = new _type;
	_type_->var_type = strdup("int");
	_type_->_next_ = NULL;
    symbol_table->insert(str,_type_,4);
    _type_ = new _type;
	_type_->var_type = strdup("function");
	_type_->_next_ = NULL;
	char s4[] = "prints";
    Global_symtab->insert(s4,_type_,1,symbol_table);
    symbol_table = new symboltable;
	_type_ = new _type;
	_type_->var_type = strdup("ptr");
	_type_->_next_ = new _type;
	_type_->_next_->var_type = strdup("int");
	_type_->_next_->_next_ = NULL;
	char s5[] = "ep";
    symbol_table->insert(s5,_type_,4);
    _type_ = new _type;
	_type_->var_type = strdup("int");
	_type_->_next_ = NULL;
    symbol_table->insert(str,_type_,4);
    _type_ = new _type;
	_type_->var_type = strdup("function");
	_type_->_next_ = NULL;
	char s6[] = "readi";
    Global_symtab->insert(s6,_type_,1,symbol_table);
	
    //Parse the file to check for syntax errors.
	if(yyparse()){
		printf("Syntax error at line number %d\n",line_num);
		exit(1);
	}
    if(argc >= 3){
       freopen(argv[2],"w",stdout);  
    }
    else {
       freopen("ass6_12CS10062_quads.out","w",stdout);
    }
    //Print the Quads.
	for(int i = 1;i < nextinstr;i++){
        Quad_array[i]->print();
    }
    if(argc >= 4){
       freopen(argv[3],"w",stdout);  
    }
    else {
       freopen("ass6_12CS10062_symboltables.out","w",stdout);
    }
    vector<pair<char *,symboltable *> > symbol_tables;
    vector<int> num_params_;
    vector<pair<symboltable *,Activation_Record *> > symtab_acrecords;
    symbol_tables.push_back(make_pair(strdup("Global"),Global_symtab));
    num_params_.push_back(0);
    symtab* sp;
	for(sp = Global_symtab->_symboltable_;sp < &(Global_symtab->_symboltable_[MAX_SIZE]);sp++){
		if(!sp->_name_){
			break;
		}
		if(sp->_nested_table_ == NULL){
		
		}
		else {
			symbol_tables.push_back(make_pair(sp->_name_,sp->_nested_table_));
			num_params_.push_back(sp->num_params);
		}
	}
	Activation_Record* ac_record;
    //Print the symboltables and generate the activation records for the symboltable.
	for(int i = 0;i < symbol_tables.size();i++){
		printf("\nSymbol Table of %s\n",symbol_tables[i].first);
		symbol_tables[i].second->print();
		ac_record = new Activation_Record;
		ac_record->generate_activation_record(symbol_tables[i].second,num_params_[i]);
		if(i > 0){
			Global_symtab->update(symbol_tables[i].first,ac_record);
		}
		else {
			Global_activation_record = ac_record;		
		}
	}
    if(argc >= 2){
       freopen(argv[1],"w",stdout);  
    }
    else {
	   freopen("ass6_12CS10062.s","w",stdout);
	}
    //Assign the goto labels after generating new labels for each quad 
    //which is pointed to by a goto.
    for(int i = 1;i < nextinstr;i++){
		if(Quad_array[i]->op_code >= _IF_LESS && Quad_array[i]->op_code <= _GOTO){
			char* s = strdup(Quad_array[i]->result);
			int line_number = atoi(s);
			line_number = find_goto_label(line_number);
			if(line_number != -1){
				Quad_array[i]->result = strdup(goto_labels[line_number].second);	
			}
			else {
				char* str = strdup(gengotolabel());
				goto_labels.push_back(make_pair(atoi(s),str));
				Quad_array[i]->result = strdup(str);
			}
		}
	}	
	curr_symtab = Global_symtab;
	curr_activation_record = Global_activation_record;
    //Translate the Three Address code into x86-assembly code.
	translate_into_assembly();
	return 0;
}
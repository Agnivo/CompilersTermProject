// Assignment 2
// File Name - ass2_12CS10062.c
// Name - Agnivo Saha
// Roll Number - 12CS10062

#include "myl.h"

#define MAX_INT_BUFF 40
#define MAX_FLOAT_BUFF 200
#define ERR 1
#define OK 0

// This function prints a string.
int prints(char *str)
{
	int bytes = 0;
	// Find the number of bytes to print excluding the null character.
	while(str[bytes] != '\0'){     
		bytes++;
	}

	// %eax <-- 4 which is to call write function. %ebx <-- 1 which is to indicate stdout,
	// i.e. write to stdout. %ecx <-- str , the string to print . %edx <-- bytes , number of bytes to print.
	__asm__ __volatile__ (
		"movl $4, %%eax \n\t"
		"movl $1, %%ebx \n\t"
		"int $128 \n\t"
		:
		:"c"(str), "d"(bytes)
	) ;

	// Return the number of characters printed.
	return bytes;
}

// This function prints an integer.
int printi(int n)
{
	char buffer[MAX_INT_BUFF],temp;
	int index = 0,bytes,digit,front,back;
	// if n = 0 , store 0 in buffer.
	if(n == 0){
		buffer[index++] = '0';
	}
	// If n < 0, store '-' in first location in buffer and make n = -n. 
	if(n < 0){
		buffer[index++] = '-'; 
		n = -n;
	}
	// Extract the digits in n in reverse order.
	while(n > 0){
		digit = n % 10;
		n /= 10;
		buffer[index++] = (char)('0' + digit);
	}
	// If n < 0, the starting position is 1st location, else the 0th location.
	if(buffer[0] == '-'){
		front = 1;
	}
	else {
		front = 0;
	}
	// back stores the end of the buffer.
	back = index - 1;

	// Reverse the buffer to store the correct value of integer n.
	while(front < back){
		temp = buffer[front];
		buffer[front++] = buffer[back];
		buffer[back--] = temp;
	}

	// Number of bytes to be printed is same as the length of buffer obtained.
	bytes = index;

	// %eax <-- 4 which is to call read function. %ebx <-- 1 which is to indicate stdout,
	// i.e. write to stdout. %ecx <-- buffer , the string (containing integer) to print . %edx <-- bytes , 
	// number of bytes to print.
	__asm__ __volatile__ (
		"movl $4, %%eax \n\t"
		"movl $1, %%ebx \n\t"
		"int $128 \n\t"
		:
		:"c"(buffer), "d"(bytes)
	) ;

	// Return the number of characters printed.
	return index;
}

// This function reads an integer and notifies when the input is not an integer.
// ep stores ERR if error occurs, else it stores OK.
int readi(int *eP){
	int byte = 1,index = 0,sign = 0,i = 0,num = 0;
	
	char temp[1];
	char buffer[MAX_INT_BUFF];

	*eP = OK;
       
    // %eax <-- 3 which is to call read function. %ebx <-- 1 which is to indicate stdin,
	// i.e. read from stdin. %ecx <-- buffer , the string where to read. %edx <-- bytes , 
	// number of bytes to read.
	// read from buffer until a valid charater (other than whitespace) is read, ignore the invalid whitespaces.    
	while(1){
		__asm__ __volatile__ (
			"movl $3, %%eax \n\t"
			"movl $0, %%ebx \n\t"
			"int $128 \n\t"
			:
			:"c"(temp), "d"(byte)
		) ;

		if(temp[0] != '\n' && temp[0] != ' ' && temp[0] != '\t'){
			buffer[index++] = temp[0];
			break;
		}
		
    }
    
	// read into the buffer the integer given as input until a whitespace is encountered.
	while(1){
		__asm__ __volatile__ (
			"movl $3, %%eax \n\t"
			"movl $0, %%ebx \n\t"
			"int $128 \n\t"
			:
			:"c"(temp), "d"(byte)
		) ;

		if(temp[0] == '\n' || temp[0] == ' ' || temp[0] == '\t'){
			break;
		}
		buffer[index++] = temp[0];
	}
	
	// Store the integer read in buffer into integer num and check if there are errors.
	while(i < index){
		// Check if the integer is negative, then store that in the sign flag.
		if(i == 0 && buffer[i] == '-'){
			sign = 1;
		}
		else if(buffer[i] >= '0' && buffer[i] <= '9'){
			num = num * 10 + (buffer[i] - '0');
		}
		else {
			*eP = ERR;
			break;
		}
		i++;
	}

	// If integer is negative, make num = -num.
	if(sign == 1){
		num = -num;
	}
	// Return the read integer.
	return num;
}

// This function reads a floating point number.
// It returns ERR if there is any error in input, else it returns OK.
int readf(float *fP)
{
	int byte = 1,index = 0,sign = 0,flag = 0,i = 0;
	char temp[1],buffer[MAX_FLOAT_BUFF];
	float tmp = 0.1;
	
	// %eax <-- 3 which is to call read function. %ebx <-- 1 which is to indicate stdin,
	// i.e. read from stdin. %ecx <-- buffer , the string where to read. %edx <-- bytes , 
	// number of bytes to read.
	// read from buffer until a valid charater (other than whitespace) is read, ignore the invalid whitespaces.
	while(1){
		__asm__ __volatile__ (
			"movl $3, %%eax \n\t"
			"movl $0, %%ebx \n\t"
			"int $128 \n\t"
			:
			:"c"(temp), "d"(byte)
		) ;

		if(temp[0] != '\n' && temp[0] != ' ' && temp[0] != '\t'){
			buffer[index++] = temp[0];
			break;
		}
    }

    // read into the buffer the floating point number given as input until a whitespace is encountered.
	while(1){
		__asm__ __volatile__ (
			"movl $3, %%eax \n\t"
			"movl $0, %%ebx \n\t"
			"int $128 \n\t"
			:
			:"c"(temp), "d"(byte)
		) ;
 
        
		if(temp[0] == '\n' || temp[0] == ' ' || temp[0] == '\t'){
			break;
		}
		buffer[index++] = temp[0];
	}

	// Check if the number is negative, set the sign flag accordingly.
	// Check if the characters inputted is valid or not. If it is valid,add to the integral part of the number.
	// If we encounter a '.' , set the flag and break. If an invalid character is encounter, return ERR.
	*fP = 0;
	while(i < index){
		if(i == 0 && buffer[i] == '-'){
			sign = 1;
		}    
		else if(buffer[i] >= '0' && buffer[i] <= '9'){
			*fP = (*fP) * 10 + (buffer[i] - '0');
		}    
		else if(buffer[i] == '.'){
			flag = 1;
			i++;
			break;
		}    
		else { 
            if(sign == 1){
            	*fP = -(*fP);
            }
            return ERR;
		}
		i++;
	}
	// We adjust the digits of the floating point number after the decimal point and return ERR on any invalid input.
	if(flag == 1){
		while(i < index){
			if(buffer[i] >= '0' && buffer[i] <= '9'){
				*fP = *fP + ((buffer[i] - '0') * tmp);
				tmp /= 10;
			}
			else {
				if(sign == 1){
					*fP = -(*fP);
				}
				return ERR;
			}
			i++;
		}
	}

	// If sign flag is set, make *fp store the negative of the current value.
	if(sign == 1){
		*fP = -(*fP);
	}
	//If there are no errors, return OK.
	return OK;
}

// This function prints a floating point number and returns the number of characters printed.
int printd(float f)
{
	float temp;
	double tempp = 1,temp_non_dec = 0;
	char buffer[MAX_FLOAT_BUFF];
	int index = 0,bytes,digit,num_digits = 0,count;

	// If f is negative, store '-' in the 0th location of buffer and make f positive.
	if(f < 0){
		buffer[index++] = '-';
		f = -f;
	}
	temp = f;
	// Find the power of 10 which is just greater than f and the number of digits in f.
	while(tempp <= temp && num_digits < 40){
		tempp *= 10;
		num_digits++;
	}
	if(f >= 0 && f < 1){
		buffer[index++] = '0';
	}
	// find the power of 10 which is just less or equal to f.
	if(tempp > f){
		tempp /= 10;
	}	

	// If f is more than range of float, print "INF" or infinity and return 3.
	if(num_digits == 40){
		prints("INF");
		return 3;
	}
	
	// Extract the integral part of the floating point number.
	while(num_digits > 0){
        digit = (int)(temp/tempp);
		buffer[index++] = (char)(digit + '0');
		temp = temp - (digit * tempp);
		temp_non_dec = temp_non_dec + (digit * tempp);
		tempp /= 10;
		num_digits--;
	}
	
	// Store the decimal point.
	buffer[index++] = '.';
	temp = f - temp_non_dec;
	count = 0;
	// Extract 6 digits after the decimal place.
	while(count < 6){
		digit = (int)(temp * 10);
		buffer[index++] = (char)(digit + '0');
		temp *= 10;
		temp = temp - digit;
		count++;
	}
	
	bytes = index;

	// %eax <-- 4 which is to call read function. %ebx <-- 1 which is to indicate stdin,
	// i.e. write to stdout. %ecx <-- buffer , the string (containing floating point number) to print . 
	// %edx <-- bytes , number of bytes to print.
	__asm__ __volatile__ (
		"movl $4, %%eax \n\t"
		"movl $1, %%ebx \n\t"
		"int $128 \n\t"
		:
		:"c"(buffer), "d"(bytes)
	) ;
	
	// Return the number of characters printed.
	return index;
}
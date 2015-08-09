a.out: lex.yy.o ass6_12CS10062_translator.o ass6_12CS10062_target_translator.o y.tab.o
	g++ -g lex.yy.o ass6_12CS10062_translator.o ass6_12CS10062_target_translator.o y.tab.o -lfl

lex.yy.o: lex.yy.c y.tab.h 
	g++ -g -c lex.yy.c
    
lex.yy.c: ass6_12CS10062.l y.tab.h 
	flex ass6_12CS10062.l

y.tab.o:  y.tab.c 
	g++ -g -c y.tab.c

y.tab.c:  ass6_12CS10062.y 
	yacc -dtv ass4_12CS10062.y

y.tab.h: ass6_12CS10062.y 
	yacc -dtv ass6_12CS10062.y

ass6_12CS10062_translator.o : ass6_12CS10062_translator.cxx ass6_12CS10062_translator.h
	g++ -g -c ass6_12CS10062_translator.cxx

ass6_12CS10062_target_translator.o : ass6_12CS10062_target_translator.cxx ass6_12CS10062_translator.h
	g++ -g -c ass6_12CS10062_target_translator.cxx

test1: a.out ass6_12CS10062_test1.c 
	./a.out < ass6_12CS10062_test1.c ass6_12CS10062_1.s ass6_12CS10062_quads1.out ass6_12CS10062_symbolatbles1.out 
	gcc -m32 -c ass6_12CS10062_1.s
	gcc -m32 ass6_12CS10062_1.o -L. -lass2_12CS10062 -o test1.out
	./test1.out

test2: a.out ass6_12CS10062_test2.c	
	./a.out < ass6_12CS10062_test2.c ass6_12CS10062_2.s ass6_12CS10062_quads2.out ass6_12CS10062_symbolatbles2.out
	gcc -m32 -c ass6_12CS10062_2.s
	gcc -m32 ass6_12CS10062_2.o -L. -lass2_12CS10062 -o test2.out
	./test2.out

test3: a.out ass6_12CS10062_test3.c	
	./a.out < ass6_12CS10062_test3.c ass6_12CS10062_3.s ass6_12CS10062_quads3.out ass6_12CS10062_symbolatbles3.out 
	gcc -m32 -c ass6_12CS10062_3.s
	gcc -m32 ass6_12CS10062_3.o -L. -lass2_12CS10062 -o test3.out
	./test3.out

test4: a.out ass6_12CS10062_test4.c	
	./a.out < ass6_12CS10062_test4.c ass6_12CS10062_4.s ass6_12CS10062_quads4.out ass6_12CS10062_symbolatbles4.out 
	gcc -m32 -c ass6_12CS10062_4.s
	gcc -m32 ass6_12CS10062_4.o -L. -lass2_12CS10062 -o test4.out
	./test4.out

test5: a.out ass6_12CS10062_test5.c	
	./a.out < ass6_12CS10062_test5.c ass6_12CS10062_5.s ass6_12CS10062_quads5.out ass6_12CS10062_symbolatbles5.out 
	gcc -m32 -c ass6_12CS10062_5.s
	gcc -m32 ass6_12CS10062_5.o -L. -lass2_12CS10062 -o test5.out
	./test5.out

test: a.out 	
	gcc -m32 -c ass6_12CS10062.s
	gcc -m32 ass6_12CS10062.o -L. -lass2_12CS10062 -o test.out
	./test.out

clean: 
	rm a.out ass6_12CS10062_translator.o ass6_12CS10062_target_translator.o lex.yy.o lex.yy.c y.tab.h y.tab.c y.tab.o y.output test.out test1.out test2.out test3.out test4.out test5.out

help: 	
	@echo "make recursive_factorial : For running the factorial program"
	@echo "make error_check : For running the error checking program"
	@echo "make binary_search : For running binary search program"
	@echo "make recursion_with_memoization_dp : For running memoized dp program"
	@echo "make loops_breaks_continue: For running loops, break and continue program"
	@echo "make ternary_operators: For running ternary operator program"
	@echo "make complex_expressions: For running a program expression program"
	@echo "make multi_dimensional_array : For running multi dimesnional array program" 
	@echo "make function_calls : For running example containing function calls" 
	@echo "make conditional_statements : For running multi dimesnional array program" 
	@echo "make strings : For running program handling strings" 
	@echo "make block_and_scope : For running program with block scopes"
	@echo "make all : For compiling the files"
	@echo "make clean : For removing the compiled files"

all:
	@ bison -d -Wno-yacc -Wnone -v parser.y
	@ lex tok.l
	@ gcc  -c -g parser.tab.c lex.yy.c AST.c assembly.c
	@ gcc  -o out parser.tab.o lex.yy.o AST.o assembly.o		

recursive_factorial: 
	@ make all --no-print-directory
	@ ./out < test_programs/recursive_factorial_program.see

ifeq (,$(wildcard target.s))
	@ spim -file target.s
endif
	@ make clean --no-print-directory

error_check:
	@ make all --no-print-directory
	@ ./out < test_programs/error_check_program.see

ifeq ("$(wildcard target.s))","")
	spim -file target.s
endif
	@ make clean --no-print-directory

binary_search:
	@ make all --no-print-directory
	@ ./out < test_programs/binary_search_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

recursion_with_memoization_dp:
	@ make all --no-print-directory
	@ ./out < test_programs/recursion_with_memoization_dp_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

loops_breaks_continue:
	@ make all --no-print-directory
	@ ./out < test_programs/loops_breaks_continue_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

ternary_operators:
	@ make all --no-print-directory
	@ ./out < test_programs/ternary_operators_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory


complex_expressions:
	@ make all --no-print-directory
	@ ./out < test_programs/complex_expressions_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory


multi_dimensional_array:
	@ make all --no-print-directory
	@ ./out < test_programs/multi_dimensional_array_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

function_calls:
	@ make all --no-print-directory
	@ ./out < test_programs/function_calls_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

conditional_statements:
	@ make all --no-print-directory
	@ ./out < test_programs/conditional_statements_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

strings:
	@ make all --no-print-directory
	@ ./out < test_programs/strings_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory

block_and_scope:
	@ make all --no-print-directory
	@ ./out < test_programs/block_and_scope_program.see
ifeq (,$(wildcard target.s))
	spim -file target.s
endif
	@ make clean --no-print-directory
	
clean:
	@ rm *.o -f
	@ rm parser.tab.c parser.tab.h parser.output y.tab.c lex.yy.c y.output y.tab.h target.s out -f
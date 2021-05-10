%{
#include "AST.h" 				// Function Tree Nodes, Abstract Syntax Tree, symbol table,  Function scope tree structures
int yylex(void);
void yyerror (char*);

/*
	Returns the type of expression from the token integer value passed from flex
*/
char* typeReturn(int type){
	char* etype; 
	if(type == 285) etype = strdup("CHAR");
	else if(type == 286) etype = strdup("INT");
	else if(type == 287) etype = strdup("VOID");
	else if(type == 288) etype = strdup("STRING");
	else etype = strdup ("Garbage Value");
	return etype; 
}

// ANSI escape codes for coloring the output
#define WHITE   "\x1b[0m"
#define PINK 	"\e[1;95m"
#define RED 	"\e[1;91m"
#define GREEN 	"\e[1;92m"
#define YELLOW 	"\e[1;93m"
#define BLUE 	"\e[1;94m"
#define CYAN 	"\e[1;96m"
#define BOLDWHITE "\e[1;37m"

/*
	Scope changes when: 
	-  Function definations starts or ends  
	-  If elseif begins and ends 
	-  For loop begins and ends  
	-  While loop begins and ends
	-  Ternary opearators begins and ends 
*/

int jumpcount; // Global variable keeping track of current scope. It is Increase/Decrease while entering or exiting a scope
int returntype; // global variable to store returntype of current function
int prevJump; // will be set to 1 iff scope is inside "for" or "while", this is used to detect if a while/for loop exists outside while doing "break" or "continue", this helps in error detection

%}
/*
	Structure to store different types of values of tokens, It also maintains line number and character position for error handling. 
*/
%code requires{ 
	typedef struct _multivalue{
		char *text;
		int type;
		int yylineno; 
		int charPos;
	}  multivalue;
}

/*
	All token used in the compiler
*/

%token <val> IDENTIFIER NUM_CHAR ASSIGN SEMICOLON LBRACKET RBRACKET COMMA LPAREN RPAREN STRINGVAL NEWLINE
%token <val> LE GE EQ NE LBRACE RBRACE IF ELSE WHILE FOR CONTINUE BREAK RETURN INPUT OUTPUT TERNERY
%token <val> AND OR CHAR INT VOID STRING LT GT BITAND BITOR NOT MINUS PLUS MUL DIV MOD XOR COLON

%union{
         struct _ASTNode *node;	
		 multivalue val;
}

/*
	Defining the types of grammar symbols and their associativity
*/
%type <node> identifiers identifiersList type declStmt declArg 
%type <node> customFunc stmt loopStmt ifelseStmt controlflowStmt multiAccess
%type <node> exprStmt callArg unaryOperator unaryExpr arithmeticExpr expression multiDim
%type <node> stmts funDeclStmt prog funName decScope incScope incScopeFor

%left AND OR BITAND BITOR
%nonassoc EQ LE GE NE LT GT
%left PLUS MINUS
%left MUL DIV
%left MOD 

%%

prog: declStmt 			{
								// declStmt is a tree with each child node as identifier node and first left child as type of identifier
								// this tree deleted previously after putting everything into symbol table
								$$ = Create_Node(0);
								$$->type = NONE;			 
								strcpy($$->lexeme,"dec");
							}
| funDeclStmt				{
								// already put in function list so skip
								astTree = $1;
								$$ = $1;  
							}
| declStmt prog  			{
								// skip declaration statement because already put in symbol tree
								astTree = $2;
								$$ = $2; 
							}
| funDeclStmt prog 	  		{
								// continue program AST tree to the right node with function as left node
								$$ = Create_Node(2); 
								$$->type=FUNCTION_STMT; 
								strcpy($$->lexeme,"@");
								$$->child[0] = $1; 		
								$1->parent = $$;	
								$$->child[1] = $2; 
								$2->parent = $$;
								astTree = $$;	
							}
;

declStmt: type identifiersList SEMICOLON 	{
												// put all child nodes in the symbol table
												// child nodes contains the identifier nodes
												// all will get deleted after putting into symbol table
												if($1->type==STRING){
													getStrings($2);
												}
											 	putSym($1->type,$2,currSymNode);
											}
;

type: INT 		{
					// assign corresponding type, return node
					$$ = Create_Node(0);
					$$->type = $1.type;
					strcpy($$->lexeme,$1.text);
				}
| CHAR     		{
					// assign corresponding type, return node
					$$ = Create_Node(0); 
					$$->type = $1.type; 
					strcpy($$->lexeme,$1.text);
				}

| VOID			{
					// assign corresponding type, return node
					$$ = Create_Node(0); 
					$$->type = $1.type; 
					strcpy($$->lexeme,$1.text);
				}
| STRING		{
					// assign corresponding type, return node
					$$ = Create_Node(0); 
					$$->type = $1.type; 
					strcpy($$->lexeme,$1.text);
				}
;

identifiersList: identifiers 				{ 
												// leaf node of tree
												$$ = $1; 
											}	
| identifiersList COMMA identifiers        	{
												// constructing a tree of the list of created variables in this statement
												// left child contains more identifiers
												// tree is left skewed
												$$ = Create_Node(2);
												$$->type = EXPRESSION_IDEN; // identifier tree node
												strcpy($$->lexeme,$2.text); 
												$$->child[0] = $1;
												$1->parent = $$; 
												$$->child[1] = $3; 
												$3->parent = $$;  
											}
;

identifiers: IDENTIFIER					{
											// identifier leaf node
											$$ = Create_Node(0); 		
											$$->type = $1.type;
											strcpy($$->lexeme,$1.text);
											$$->progType = _IDENTIFIER_; // type identifer
										}	

| IDENTIFIER multiDim	{	
											// array identifier leaf node
											$$ = Create_Node(0); 
											$$->type = $1.type; 
											strcpy($$->lexeme,$1.text);
											$$->progType = ARRAY; 		// type array
											$$->arrDim = $2->arrDim; // get dimension of array
										}
;

multiDim: multiDim LBRACKET NUM_CHAR RBRACKET 	 {
													// Multidimensional array declaration. The indices can only be fixed integers
													// that can be determined at the compile time. Row major form is used. The idea is
													// to flatten the list and predetermining the space required by the array, and allocating it on the stack. 
													$$ = Create_Node(0);
													$$->arrDim = ($1->arrDim* atoi($3.text)) + atoi($3.text); 
											 	 }
| LBRACKET NUM_CHAR RBRACKET {	
								// setting the array dimension 
								$$ = Create_Node(0);
								$$->arrDim = atoi($2.text); 
							}
;

funDeclStmt: funName incScope LPAREN declArg RPAREN LBRACE stmts RBRACE decScope 	{
																						$$ = $1;					// function name node used as the main ASTnode further
																						$$->child[1] = $7; 			// tree of statements inside function
																						$7->parent = $$;			
																						funTree->children[funTree->numberOfChilds] = ( functionTreeNode *)malloc(sizeof( functionTreeNode));
																						functionTreeNode *local = funTree->children[funTree->numberOfChilds];
																						local->numberOfChilds = 0;
																						local->children = ( functionTreeNode **) malloc(sizeof( functionTreeNode *));
																						strcpy(local->functionName,$1->lexeme);
																						local->astNode = $$;		// the main list of functions adds this function and its AST
																						local->argNode = $4;		// arguments of this function
																						local->funcScopeNode = currSymNode->child[currSymNode->currChildNumber - 1];	
																						funTree->numberOfChilds+=1;				
																					}
| funName incScope LPAREN RPAREN LBRACE stmts RBRACE decScope	{
																		$$ = $1;
																		$$->child[1] = $6; 
																		$6->parent = $$;															
																		funTree->children[funTree->numberOfChilds] = ( functionTreeNode *)malloc(sizeof( functionTreeNode));
																		functionTreeNode *local = funTree->children[funTree->numberOfChilds];
																		local->numberOfChilds = 0;
																		local->children = ( functionTreeNode **) malloc(sizeof( functionTreeNode *));
																		funTree->numberOfChilds+=1;
																		strcpy(local->functionName,$1->lexeme);
																		local->astNode = $$; // the main list of functions adds this function and its AST
																		local->argNode = NULL; // function with no arguments
																		local->funcScopeNode = currSymNode->child[currSymNode->currChildNumber - 1];
																}				
;

funName: type IDENTIFIER  		{
									// putting name of function in symbol table
									$$ = Create_Node(2); 
									$$->type = $2.type; 
									strcpy($$->lexeme,$2.text);
									$$->child[0] = $1;  // return type
									$1->parent = $$;	
									$$->progType = FUNCTION_NAME;
									putSym($1->type,$$,currSymNode);	// function name put in symbol table
									returntype = $1->type;	// global variable return type used to check if actual returned variable matches the return type of function
								}
;

declArg: declArg COMMA type identifiers  				{		
															// put "identifiers" in symbol table, declArg's identifiers have already been put
															// right child contains type of "identifiers"
															// left child contains more types
															// tree is left skewed
															$$ = Create_Node(2); 
															$$->type = EXPRESSION_IDEN; 
															strcpy($$->lexeme,$2.text);
															$$->child[0] = $1; 
															$1->parent = $$;
															$$->child[1] = $3; 
															$3->parent = $$;															
															putSym($3->type,$4,currSymNode);
														}
| type identifiers										{ 
															// base case
															$$ = $1; 
															putSym($1->type,$2,currSymNode);
														}
;

stmt: incScope LBRACE stmts RBRACE decScope					{$$ = $3;}
| controlflowStmt   									{$$ = $1;}
| loopStmt   											{$$ = $1;}
| ifelseStmt   											{$$ = $1;}
| declStmt     											{
															$$=Create_Node(0); 
															$$->type = NONE;
															strcpy($$->lexeme,"dec");
														}
| customFunc 											{$$ = $1;}	 
| exprStmt  											{$$ = $1;}
;

controlflowStmt:  BREAK SEMICOLON 		{ 
											// break statement check if inside loop
											// node will further help to have required jump statement in code generation
											$$ = Create_Node(0); 
											$$->type = $1.type; 
											strcpy($$->lexeme,$1.text);
											if(prevJump == -1){
												printf("%sError %sLine %d: Position %d: %sBREAK without loopStmt\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
												numberOfErrors++;
											}
										}
| CONTINUE SEMICOLON					{ 
											// continue statement check if inside loop
											// node will further help to have required jump statement in code generation
											$$ = Create_Node(0);
											 $$->type = $1.type; 
											 strcpy($$->lexeme,$1.text);
											if(prevJump == -1){
												printf("%sError %sLine %d: Position %d: %sCONTINUE without loopStmt\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
												numberOfErrors++;
											}
										}		
| RETURN SEMICOLON 						{
											// return statement in a function
											// here returning void
											// node will further help to have required jump statement in code generation 
											$$ = Create_Node(0); 
											$$->type = $1.type; 
											strcpy($$->lexeme,$1.text);
											if(returntype != VOID ){
												printf("%sError %sLine %d: Position %d: %sInvalid Return Type: VOID\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
												numberOfErrors++;
											}	
        								}
| RETURN expression SEMICOLON      		{ 
											// return statement in a function
											// here returning argument with type checking of return value
											// node will further help to have required jump statement in code generation 
											$$ = Create_Node(1); 
											$$->type = $1.type; 
											strcpy($$->lexeme,$1.text);
											$$->child[0] = $2; 
											$2->parent = $$;
											if(returntype != $2->type){
												char* etype;
												etype = strdup(typeReturn($2->type));
												printf("%sError %sLine %d: Position %d: %sInvalid Return Type: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,etype,WHITE);
												numberOfErrors++;
											}
										}
;

loopStmt: FOR incScopeFor LPAREN exprStmt exprStmt expression RPAREN LBRACE stmts RBRACE decScope 
																											{																												
																												prevJump = -1; // reset prevJump while exiting for loop
																												$$ = Create_Node(4); 
																												$$->type = $1.type; 
																												strcpy($$->lexeme,$1.text);
																												$$->child[0] = $4; $4->parent = $$; 
																												$$->child[1] = $5; $5->parent = $$;
																												$$->child[2] = $6; $6->parent = $$;
																												$$->child[3] = $9; $9->parent = $$;
																												$$->progType = FOR_TYPE_TWO;				
																												$$->astScopeNode = $9->astScopeNode;
																											}

| FOR incScopeFor LPAREN exprStmt exprStmt RPAREN LBRACE stmts RBRACE decScope
																											{
																												prevJump = -1; // reset prevJump while exiting for loop
																												$$ = Create_Node(3); 
																												$$->type = $1.type; 
																												strcpy($$->lexeme,$1.text);
																												$$->child[0] = $4; $4->parent = $$; 
																												$$->child[1] = $5; $5->parent = $$;
																												$$->child[2] = $8; $8->parent = $$;
																												$$->progType = FOR_TYPE_ONE;				
																												$$->astScopeNode = $8->astScopeNode;
																											}
| WHILE incScopeFor LPAREN expression RPAREN LBRACE stmts RBRACE decScope 					
																											{
	 																											prevJump = -1; // reset prevJump while exiting while loop
																												$$ = Create_Node(2); 
																												$$->type = $1.type; 		// type is while
																												strcpy($$->lexeme,$1.text);	
																												$$->child[0] = $4; $4->parent = $$;  // expression tree
																												$$->child[1] = $7; $7->parent = $$;  // statements tree
																												$$->progType = WHILE_LOOP;			
																												$$->astScopeNode = $7->astScopeNode; // scope of loop is statements
																											}
;

incScopeFor: {
				// set prevJump and increment scope jumpcount
				// prevJump is used to determine if there are any control flow statements out side loop or not
				prevJump = 1;
				jumpcount++; 
				currSymNode = alterScope(currSymNode,"INCREMENT");
			}
;

incScope:	{ 	
				jumpcount++;  // increment scope 
				currSymNode = alterScope(currSymNode,"INCREMENT");
			}
;

decScope:	{ 
				currSymNode = alterScope(currSymNode,"DECREMENT"); 
				jumpcount--; // decrement scope 
			}
;

ifelseStmt: IF LPAREN expression RPAREN incScope LBRACE stmts RBRACE decScope	{
																					$$ = Create_Node(2);  // create node with 2 childs. One for code generation of expression and one for code generation of statements 
																					$$->type = $1.type; 
																					strcpy($$->lexeme,$1.text);
																					$$->child[0] = $3; $3->parent = $$; 
																					$$->child[1] = $7; $7->parent = $$;
																					$$->progType = IF_TYPE_ONE;				 // If type one for if without else
																				}
| IF LPAREN expression RPAREN incScope LBRACE stmts RBRACE decScope ELSE stmt 	{
																					$$ = Create_Node(3);  // create node with 3 childs. One for code generation of expression and two for code generation of if and else statements respectively
																					$$->type = $1.type; 
																					strcpy($$->lexeme,$1.text);
																					$$->child[0] = $3; $3->parent = $$; 
																					$$->child[1] = $7; $7->parent = $$;
																					$$->child[2] = $11; $11->parent = $$;
																					$$->progType = IF_TYPE_TWO;			// If type two for if with else	 
																				}
| arithmeticExpr incScope TERNERY expression COLON expression decScope {
																			// ternery operator, same as if and else
																			$$ = Create_Node(3); 
																			$$->type = $3.type; 
																			strcpy($$->lexeme,$3.text);
																			$$->child[0] = $1; $1->parent = $$; 
																			$$->child[1] = $4; $4->parent = $$;
																			$$->child[2] = $6; $6->parent = $$;
																			$$->progType = IF_TYPE_TWO;				
																		}
;

customFunc: INPUT LPAREN type COMMA IDENTIFIER RPAREN SEMICOLON {
																	$$ = Create_Node(2); 
																	$$->type = INPUT_OUTPUT_STMT; 
																	strcpy($$->lexeme,$1.text);
																	$$->child[0] = $3; $3->parent = $$;
																	$$->child[1] = Create_Node(0); 
																	strcpy($$->child[1]->lexeme,$5.text);
																	$$->child[1]->type = $5.type;
																	$$->child[1]->parent = $$;

																	// find variable to take input
																	symbolTable *temp = getSymbolTable($5.text,$$);
																	if(temp==NULL){
																		printf("%sError %sLine %d: Position %d: %sVariable Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$5.text,WHITE);
																		numberOfErrors++;
																	} 
																	else if(temp->type != $3->type) {
																		char* etype;
																		etype = strdup(typeReturn($3->type)); 
																		printf("%sError %sLine %d: Position %d: %sINPUT Type Mismatch: %s\n",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE, etype);
																		numberOfErrors++;
																	}
																} 
| OUTPUT LPAREN type COMMA IDENTIFIER RPAREN SEMICOLON			{
																	$$ = Create_Node(2); 
																	$$->type = INPUT_OUTPUT_STMT; 
																	strcpy($$->lexeme,$1.text);
																	$$->child[0] = $3; $3->parent = $$;
																	$$->child[1] = Create_Node(0); 
																	strcpy($$->child[1]->lexeme,$5.text);
																	$$->child[1]->type = $5.type;
																	$$->child[1]->parent = $$;

																	// find variable to be output
																	symbolTable *temp = getSymbolTable($5.text,$$);
																	if(temp==NULL){
																		printf("%sError %sLine %d: Position %d: %sVariable Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$5.text,WHITE);
																		numberOfErrors++; 
																	}	
																	else if(temp->type != $3->type){
																		char* etype;
																		etype = strdup(typeReturn($3->type)); 
																		printf("%sError %sLine %d: Position %d: %sOUTPUT Type Mismatch: %s\n",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE, etype);
																		numberOfErrors ++;
																	}				
																}
| NEWLINE LPAREN RPAREN SEMICOLON	{
										$$ = Create_Node(0);
										$$->progType = INPUT_OUTPUT_STMT;
										strcpy($$->lexeme,$1.text);
									}
;

/* ### Expressions ### */

exprStmt: expression SEMICOLON	    {$$ = $1;}
| SEMICOLON						{
									$$ = Create_Node(0); 
									$$->type = EXPRESSION_IDEN; 
									strcpy($$->lexeme,$1.text);
								}
;

expression: arithmeticExpr	 	{$$=$1;}
| STRINGVAL 					{
									$$=Create_Node(0);
									$$->type=STRING;
									strcpy(ConstantStrings[ConstantStringInd++],$1.text);
									sprintf($$->lexeme,"%d",ConstantStringInd-1);
									$$->progType  = STRINGVAL;
								}
| unaryExpr ASSIGN expression  	{ 			
									$$ = Create_Node(2); 
									$$->type = EXPRESSION_IDEN; 
									strcpy($$->lexeme, $2.text); 
									$$->child[0] = $1; $1->parent = $$;
									$$->child[1] = $3; $3->parent = $$;
									// type check
									if($1->progType==ARRAY_SINGLE_DIM && $3->type==STRING){
										$$->type = MUTATE_STRING;
									}
									else if($1->type==STRING && $3->type==STRING_ASSIGN_CONCAT){
										$$->type = STRING_ASSIGN_CONCAT;
									}
									else if($1->type==STRING && $3->progType!=STRINGVAL){
										$$->type = STRING_ASSIGN_VAR;
									}
									else if($1->type != $3->type){
										char* e1type, *e2type;
										e1type = strdup(typeReturn($1->type)); 
										e2type = strdup(typeReturn($3->type)); 
										printf("%sError %s Line %d: Position %d: %sInvalid Operand For: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
										numberOfErrors++;
									}
									else $$->type = $1->type;
								}
;

callArg: expression						{$$=$1; }
| callArg COMMA expression 		{
									// right child contains current expression
									// left child contains more expressions
									// tree is left skewed
									$$ = Create_Node(2); 
									$$->type = EXPRESSION_IDEN; 
									strcpy($$->lexeme,$2.text);
									$$->child[0] = $1; $1->parent = $$;
									$$->child[1] = $3; $3->parent = $$;
							}
;

unaryOperator: MINUS 	{	
							// unary expression for minus 
							$$=Create_Node(0); 
							$$->type = EXPRESSION_IDEN; 
							strcpy($$->lexeme,$1.text); 
						}
| NOT 					{
							// unary expression for not
							$$=Create_Node(0); 
							$$->type = EXPRESSION_IDEN; 
							strcpy($$->lexeme,$1.text); 
						}
;

unaryExpr: IDENTIFIER 				{
										$$ = Create_Node(0); 
										$$->type = $1.type; 
										strcpy($$->lexeme,$1.text);
        								symbolTable *temp = getSymbolTable($1.text,$$);
        								if(temp==NULL){
											// variable not found
											printf("%sError %sLine %d: Position %d: %sVariable Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$1.text,WHITE);
											numberOfErrors++;
										}
        								else $$->type = temp->type;
        								$$->progType = IDEN_RELATED;
        							}
| NUM_CHAR 							{	
										// number or character 
										$$ = Create_Node(0); 
										$$->type = $1.type; 
										strcpy($$->lexeme,$1.text);
										$$->type = $1.type;
										$$->progType  = CONSTANTS; 
									}
| STRINGVAL                         {
										// String value 
										$$ = Create_Node(0); 
										$$->type = $1.type; 
										strcpy($$->lexeme,$1.text);
										$$->type = $1.type;
										$$->progType  = CONSTANTS;
									}
| LPAREN expression RPAREN        	{
										$$ = $2;
									}				
| IDENTIFIER LPAREN RPAREN 			{	
										// calling a function with no arguments 
										$$=Create_Node(0); 
										$$->type = $1.type; 
										strcpy($$->lexeme,$1.text);
										$$->progType = FUNCTION_WITHOUT_ARGUMENT;
										symbolTable *temp = getSymbolTable($1.text,$$);
										
										if(temp==NULL){
											printf("%sError %sLine %d: Position %d: %sFunction Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$1.text,WHITE);
											numberOfErrors++;
										}
										else $$->type = temp->type;
										int check = typeCheck($1.text,NULL); 
										if(check == -1){
											printf("%sError %sLine %d: Position %d: %sFunction Definition Type and Input Arguments Type Dont Match\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
											numberOfErrors++;
										}
										if(check == -2){
											printf("%sError %sLine %d: Position %d: %sNumber of Arguments Dont Match\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
											numberOfErrors++;
										}
									}
| IDENTIFIER LPAREN callArg RPAREN  		{	
												// calling a function with arguments 
												$$=Create_Node(1); 
												$$->type = $1.type; 
												strcpy($$->lexeme,$1.text);
											 	$$->progType = FUNCTION_WITH_ARGUMENT; 
												$$->child[0]= $3; $3->parent = $$;
										 		symbolTable *temp = getSymbolTable($1.text,$$);
        								 		if(temp==NULL){
													 printf("%sError %sLine %d: Position %d: %sFunction Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$1.text,WHITE);
													 numberOfErrors++;
												}
        								 		else $$->type = temp->type;
												int check = typeCheck($1.text,$3); 
												if(check == -1){
													printf("%sError %sLine %d: Position %d: %sFunction Definition Type and Input Arguments Type Dont Match\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
													numberOfErrors++;
												}
												if(check == -2){
													printf("%sError %sLine %d: Position %d: %sNumber of Arguments Dont Match\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
													numberOfErrors++;
												}
											}
| unaryOperator unaryExpr 			{
										$$=Create_Node(1); 	
										strcpy($$->lexeme,$1->lexeme);
										$$->child[0]=$2; $2->parent = $$; 
										$$->type = $2->type;
									}
| IDENTIFIER LBRACKET expression RBRACKET 	{
												// single dimension array access. The array index can be any kind of expression 
												$$=Create_Node(0); 
												$$->type = $1.type;
												strcpy($$->lexeme,$1.text);
												$$->child[0] = $3; 
												$3->parent = $$; 
												$$->progType = ARRAY_SINGLE_DIM;	
												symbolTable *temp = getSymbolTable($1.text,$$);
												if(temp==NULL){
													// array not declared
													printf("%sError %sLine %d: Position %d: %sVariable Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$1.text,WHITE);
													numberOfErrors++;
												}
												else{
													// array index must be integer
													if($3->type != INT){
														printf("%sError %sLine %d: Position %d: %sArray Index Must Be Integer\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
														numberOfErrors++;
													}
													else
														$$->type = temp->type;	
												}
											} 
| IDENTIFIER multiAccess {
							// Multidimensional array. The array indices can only be integers or values that can be determined at compile time
							$$=Create_Node(0); 
							$$->type = $1.type;
							strcpy($$->lexeme,$1.text);
							$$->child[0] = $2; 
							$2->parent = $$; 
							$$->progType = ARRAY_SINGLE_DIM;	
							symbolTable *temp = getSymbolTable($1.text,$$);
							if(temp==NULL){
								// array not declared
								printf("%sError %sLine %d: Position %d: %sVariable Not Declared: %s\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,$1.text,WHITE);
								numberOfErrors++;
							}
							else{
								// array index must be integer
								if($2->type != INT){
									printf("%sError %sLine %d: Position %d: %sArray Index Must Be Integer\n%s",RED,BLUE,$1.yylineno,$1.charPos,BOLDWHITE,WHITE);
									numberOfErrors++;
								}
								else
									$$->type = temp->type;	
							}
						} 
;

multiAccess: multiAccess LBRACKET NUM_CHAR RBRACKET  { 	
														$$ = Create_Node(0); 
														$$->type = $3.type; 
														int temp = atoi($1->lexeme)* atoi($3.text) + atoi($3.text); 
														sprintf($$->lexeme,"%d",temp);
														$$->type = $3.type;
														$$->progType  = CONSTANTS;
													}
| LBRACKET NUM_CHAR RBRACKET 	{
									$$ = Create_Node(0); 
									$$->type = $2.type; 
									strcpy($$->lexeme,$2.text);
									$$->type = $2.type;
									$$->progType  = CONSTANTS;
								}
;

arithmeticExpr: unaryExpr					{$$=$1;}
| arithmeticExpr MUL arithmeticExpr  {
										$$=Create_Node(2);	
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if(($1->type != $3->type)){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For Multiplication: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
											numberOfErrors++;
										}		
										else	
										$$->type = $1->type;
									}
| arithmeticExpr DIV arithmeticExpr	{
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if(($1->type != $3->type)){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For Division: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = $1->type;					 
							 		}
| arithmeticExpr MOD arithmeticExpr  {
										$$=Create_Node(2);	
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if(($1->type != INT || $3->type != INT)){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For Modulus: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
											numberOfErrors++;
										}else{
											$$->type = $1->type;
										}
									}
| arithmeticExpr PLUS arithmeticExpr  {
										$$=Create_Node(2);	
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type==STRING && $3->type==STRING){
											$$->type = STRING_ASSIGN_CONCAT;
										}
										else if($1->type != $3->type)	{
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For Addition: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
											numberOfErrors++;
										}	
										else	
										$$->type = $1->type; 
									}
| arithmeticExpr MINUS arithmeticExpr  {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type != $3->type){
											numberOfErrors++;
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For Substraction: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,e1type,e2type,WHITE);
											numberOfErrors++;
										}	
										else	
										$$->type = $1->type;
									}						 	
| arithmeticExpr LE arithmeticExpr  {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = INT;

									}
| arithmeticExpr GE arithmeticExpr  {
										$$=Create_Node(2);	
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = INT;
							}
| arithmeticExpr LT arithmeticExpr   {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = INT;
							 	}
| arithmeticExpr GT arithmeticExpr   {
										$$=Create_Node(2);	
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = INT;
									}
| arithmeticExpr EQ arithmeticExpr 	{
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else $$->type = INT;
									}
| arithmeticExpr NE arithmeticExpr 	{
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type != $3->type){
											char* e1type, *e2type;
											e1type = strdup(typeReturn($1->type)); 
											e2type = strdup(typeReturn($3->type)); 
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: %s and %s\n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,e1type,e2type,WHITE);
											numberOfErrors++;
										}
										else	
										$$->type = INT;											
									}
| arithmeticExpr BITAND arithmeticExpr {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type != INT || $3->type != INT){
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: \n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,WHITE);
											numberOfErrors++;
										}else{
											$$->type = INT;
										}
									}
| arithmeticExpr XOR arithmeticExpr  {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != INT || $3->type != INT){
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: \n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,WHITE);
											numberOfErrors++;
										}else{
											$$->type = INT;
										}
									}
| arithmeticExpr BITOR arithmeticExpr {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;	
										// type check
										if($1->type != INT || $3->type != INT){
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: \n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,WHITE);
											numberOfErrors++;
										}
										else{
											$$->type = INT;
										}
									}
| arithmeticExpr AND arithmeticExpr {
										$$=Create_Node(2); 
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check
										if($1->type != INT || $3->type != INT){
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: \n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,WHITE);
											numberOfErrors++;
										}
										else $$->type = INT;
									}
| arithmeticExpr OR arithmeticExpr	{
										$$=Create_Node(2);
										strcpy($$->lexeme,$2.text);
										$$->child[0]=$1; $1->parent = $$;
										$$->child[1]=$3; $3->parent = $$;
										// type check	
										if($1->type != INT || $3->type != INT){
											printf("%sError %sLine %d: Position %d: %sInvalid Operand For %s: \n%s",RED,BLUE,$2.yylineno,$2.charPos,BOLDWHITE,$2.text,WHITE);
											numberOfErrors++;
										}
										else $$->type = INT;
									}
;


stmts: stmt   					{$$=$1;}
| stmts stmt      				{ 
									// right child contains current node
									// left child contains more nodes 
									// tree is left skewed
									$$ = Create_Node(2); 
									$$->type =STMT_TYPE; 
									strcpy($$->lexeme,";");
									$$->child[0] = $1; if($1 != NULL) $1->parent = $$;
									$$->child[1] = $2;  if($2 != NULL) $2->parent = $$;
								}
;



%%

/*
	Prints if there is error while parsing
*/
void yyerror(char  *s)
{
        fflush(stdout);
		printf("%sParse Error %s\n%s", RED,s,WHITE);
		return ;
}


int main()
{
	// initialize variables
	jumpcount=0; // Initialize scope to zero 
	returntype=0; // no return type
	prevJump=-1; // previous scope. This is set only program enters into while/for loop
	numberOfErrors=0; // zero errors in beginning

	// initialize symbol table node
	currSymNode = (tableNode*)malloc(sizeof(tableNode));
	currSymNode->symrec = NULL;
	currSymNode->scope = 0;
	currSymNode->currChildNumber = 0;
	currSymNode->parent = NULL;
	currSymNode->tableSize = 0;

	// set global symbol table node to current node
	globalSymNode = currSymNode;

	// Function node to store functions defined in global scope including main
	// This is the global function tree node. All other function will be child of this tree 
	funTree = ( functionTreeNode *) malloc(sizeof( functionTreeNode));
	funTree->children = ( functionTreeNode **) malloc(sizeof( functionTreeNode *));
	funTree->numberOfChilds = 0;
	
	yyparse();	 // start parsing 
	
	globalSymNode->sizeSum=globalSymNode->tableSize;	
	setSumSize(globalSymNode);	 // set sizes in all nodes in the tree
	
	// If there are errors, do not generate assembly code other wise, generate the assembly code
	if(numberOfErrors>0) {	
		printf("%sTotal errors: %d\n%s",RED,numberOfErrors,WHITE);		
		return 0; // do not generate assembly code if errors in compilation
	} else {		
		if(checkMain()==0){
			printf("%sError : %sMain Function Does Not Exist.\n%s",RED,BOLDWHITE,WHITE);			
			return 0; // exit if main function does not exists
		}		
		createAssembly(); // generate assembly code
	}
	return 0;
		// main stack pointer sp 
	// t2 is current stack pointer location for each pointer
	// t9 to get the location of identifier wrt sp 
	// t4 is generally used to load values of identifiers from t9 with the help of offset 
	// t0 is the local pointer used to subtract size from sp 
	// t3 is the local pointer used to subtract size from t2
	// return values are passed via $v0
	// Top of stack is sp 
	// Stack pointer is $t2 
}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Defining constants
#define MAXARGS 50
#define MAX_LEXEME_LENGTH 150
#define MAX_LABEL_LENGTH 100
#define MAX_NAME_LENGTH 100
#define MAX_CHILDREN_NUMBER 20
#define MAX_NUMBER_OF_LABELS 2
#define STMT_TYPE 101
int numberOfErrors; // total number of errors
int isSame ;       // for type checking 
char strings[100][100];  // for handling string data type
char ConstantStrings[100][100];
int ConstantStringInd;
int stringInd;

// types of nodes
enum nodeType {
	_IDENTIFIER_,ARRAY,FUNCTION_WITHOUT_ARGUMENT,FUNCTION_WITH_ARGUMENT,WHILE_LOOP,FOR_TYPE_ONE,
	FOR_TYPE_TWO,IF_TYPE_ONE,IF_TYPE_TWO,FUNCTION_NAME,CONSTANTS,IDEN_RELATED,ARRAY_SINGLE_DIM,STRING_ASSIGN_VAR,STRING_ASSIGN_CONCAT,MUTATE_STRING, NEW_LINE
};

// types of statements
enum stmtType { 
	NONE,EXPRESSION_IDEN,FUNCTION_STMT,INPUT_OUTPUT_STMT,STRING_
};

// Structure for symbol table please refer to diagram given in read me to get deeper understanding of all the structures 

typedef struct _symbolTable{
	char name[MAX_NAME_LENGTH];
	int offset;
	int size;
	int type;
	struct _symbolTable* next;
	struct _tableNode* parentTableNode;
	
} symbolTable;

typedef struct _tableNode{
	int sizeSum;
	int scope;					
	int tableSize;
	int currChildNumber;		
	struct _tableNode* parent;
	struct _tableNode* child[MAX_CHILDREN_NUMBER];	
	struct _symbolTable* symrec;
} tableNode;

typedef struct _ASTNode{
	char lexeme[MAX_LEXEME_LENGTH];
	enum stmtType type;
	int arrDim; 
	enum nodeType progType;
	char labels[MAX_NUMBER_OF_LABELS][MAX_LABEL_LENGTH];	
	struct _tableNode* astScopeNode;
 	struct _ASTNode* parent;
	struct _ASTNode** child;
} ASTNode;

typedef struct _functionTreeNode {	
	char functionName[MAX_NAME_LENGTH];
	int numberOfChilds;
	struct _functionTreeNode *parent;
	struct _functionTreeNode **children;
	struct _ASTNode *astNode, *argNode;
	struct _tableNode *funcScopeNode;
} functionTreeNode; 



tableNode* currSymNode, *globalSymNode;
ASTNode* astTree;
functionTreeNode *funTree;

symbolTable * getSymbolTable(char *lexeme, ASTNode* rootNode); // return the symbol table given astnode and the lexeme of the variable 
tableNode* alterScope(tableNode *rootNode, char* changeType);  // Function to change the scope of the program
ASTNode * Create_Node(int num);  // Function to create an ASTNODE given the number of children
int typeCheck();                 // Function to check the type
void setSumSize();          

void putSym(int type,ASTNode *nodeToPut,tableNode* currSymNode);   // Function to put symbol in symbol table
void createAssembly();                                           // function to start bulding assembly using the function tree 
void getStrings(ASTNode *curr_node); 							 // function to get strings
int checkMain();                                                 // Function to check if main exists 
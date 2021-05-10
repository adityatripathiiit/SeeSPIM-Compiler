#include "AST.h"
#include "parser.tab.h"

#define OPERATORS_COUNT 17

const char operators[OPERATORS_COUNT][3] = {"+","-","*","/","%",">","<","&","^","|",">=","<=","!=","==","&&","||","!"};
const char instruction_for_operators[OPERATORS_COUNT][4] = {"add","sub","mul","div","rem","sgt","slt","and","xor","or","sge","sle","sne","seq","and","or"};

int checkIfOperator(char* lexeme);
void getNewLabel(char *s);
void generateCode(FILE *fp,ASTNode *currASTNode);
void loadFromStack(FILE *fp,char *reg,symbolTable *currSymbolNode,tableNode *currTableNode,int isArr);
void spill(FILE *fp,char *reg,symbolTable *currSymbolNode,tableNode *currTableNode,int isArr);
void operationsCode(FILE *fp,char *s);
void load_spill_array_identifier(FILE *fp,ASTNode*curr_node,int type);
ASTNode * getClosestForOrWhile(ASTNode *currASTNode);
void processFunctionArguments(FILE *fp,ASTNode *currASTNode);
int calculateChildrenCount(ASTNode* currASTNode);
int findIndexInFunTree(ASTNode* currASTNode);
int current_scope;
int global_labels_count;
int current_function_index;
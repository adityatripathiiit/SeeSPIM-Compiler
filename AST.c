#include "AST.h"
#include "parser.tab.h"


/*
	Searches in linked list of symbol tables of current scope table
	If not found then go to parent scope table and continue
	Returns symbolTable node corresponding to the lexeme else return NULL if not found
*/
symbolTable * getSymbolTable(char *lexeme,ASTNode* curr_node){	

	tableNode* tree_node = curr_node->astScopeNode;
	
	while(tree_node != NULL){
		symbolTable *table = tree_node->symrec;
		while(table != NULL){
			if(strcmp(table->name,lexeme)==0){
				return table;
			}
			// go to next symbol table node in linked list
			table = table->next;
		}
		// searched all symbol table nodes in current table node
		// now search further in parent nodes
		tree_node = tree_node->parent;
	}
	// lexeme not found
	return NULL;
}

/*
	Increments or Decrements scope while entering loops, functions and conditional statements
	Returns the next scope to be used - inner scope node if increment, outer scope node if decrement
*/
tableNode* alterScope(tableNode* rootNode, char* changeType){
	if(!strcmp(changeType,"INCREMENT")){
		// make new node if going inside a new scope and return new node
		tableNode* currNode;
		rootNode->child[rootNode->currChildNumber] = (tableNode*)malloc(sizeof( tableNode));
		currNode = rootNode->child[rootNode->currChildNumber];
		(rootNode->currChildNumber)++;
		currNode->currChildNumber = 0;
		currNode->tableSize = 0;
		currNode->symrec = NULL;
		currNode->scope = rootNode->scope + 1;
		currNode->parent = rootNode;
		return currNode;
	}
	else if(!strcmp(changeType,"DECREMENT")){
		// return the parent scope node
		return rootNode->parent;
	}
}

/*
	Recursively checks if types defined in defineNode match with types defined in currNode
*/
void findArgsType( ASTNode* defineNode,  ASTNode* currNode){

	// base case

	if(currNode->child[0]==NULL && defineNode->child[0] == NULL ){
		// printf("%d \n",1);
		if(currNode->type != defineNode->type) isSame = -1; 
		return;
	}
	int i=0;
	while(defineNode->child[i] != NULL && currNode->child[i]!=NULL){
		findArgsType(defineNode->child[i],currNode->child[i]);
		i++;
	}
	if(isSame != -1 && defineNode->child[i] != currNode->child[i]) isSame = -2;
}

/*
	Validates return value and argument type of function	
*/
int typeCheck(char *function_name, ASTNode *curr_node)
{
	int is_found = 0; 
	int i = 0; 
	for(i=0;i<funTree->numberOfChilds;i++){
		if(strcmp(funTree->children[i]->functionName,function_name)==0){
			is_found = 1;
			break;
		}
	}
	if(is_found != 1) return -3;
	isSame = 0;
	if(funTree->children[i]->argNode == NULL && curr_node == NULL) return isSame;
	if(funTree->children[i]->argNode == NULL && curr_node != NULL) return -2;
	if(funTree->children[i]->argNode != NULL && curr_node == NULL) return -2;
	findArgsType(funTree->children[i]->argNode, curr_node);
	return isSame; 
}

/*
	Initializes and return a newly created astnode
*/
ASTNode * Create_Node(int num){
	ASTNode * node = ( ASTNode*)malloc(sizeof( ASTNode));
	node->parent = NULL;
	node->child = ( ASTNode**)malloc(num*sizeof( ASTNode *));
	node->progType = _IDENTIFIER_;
	node->arrDim =0;	
	node->astScopeNode = currSymNode;
	return node;
}

/*
	Deletes ASTNode and puts offset and size information in table node and symbol table node
*/
void putSym(int type,ASTNode *nodeToPut,tableNode* currSymNode){
	int progType = nodeToPut->progType;

	if((nodeToPut->child[0] == NULL && nodeToPut->type == IDENTIFIER ) || progType == FUNCTION_NAME){

		// base case

		symbolTable *search = currSymNode->symrec;

		// Search for multiple definitions
		while(search != NULL){
			if(strcmp(search->name,nodeToPut->lexeme)==0){
				printf("Multiple definitions of %s\n",nodeToPut->lexeme);
				numberOfErrors++;
			}
			search = search->next;
		}

		symbolTable *curr_node = ( symbolTable *)malloc(sizeof( symbolTable));
		strcpy(curr_node->name,nodeToPut->lexeme); curr_node->offset = 0; curr_node->type = type; curr_node->size = 0;

		// set size according to the type
		if(type == INT || type == CHAR){
			if(progType == 0)
				curr_node->size = 4;
			else if(progType==1)
				curr_node->size = 4 * nodeToPut->arrDim;
		}
		else if(type==STRING){
			curr_node->size = 100;
		}

		// increment size
		currSymNode->tableSize += curr_node->size;
		curr_node->parentTableNode = currSymNode;

		// set offset
		if(currSymNode->symrec == NULL) curr_node->offset = 0;
		else curr_node->offset = currSymNode->symrec->offset + currSymNode->symrec->size ;

		curr_node->next = currSymNode->symrec; 
		currSymNode->symrec = curr_node;

		if(progType == FUNCTION_NAME) return;
		
		free(nodeToPut);
		return;

	} else {
		
		// recursive case
				
		int i=0;
		while(nodeToPut->child[i]!=NULL){
			putSym(type,nodeToPut->child[i],currSymNode);
			i++;
		}		
		free(nodeToPut);
		return;	
	}
}

/*
	Recursively sets sizeSum for each tableNode to be sum of sizeSum of all nodes in path from root to that node and the sizeSum of that node
*/
void setSumSize(tableNode*curr_table_node){
	for(int i=0;i<curr_table_node->currChildNumber;i++){
		// set sizeSum to be current sizeSum + value of parent
		curr_table_node->child[i]->sizeSum = curr_table_node->child[i]->tableSize + curr_table_node->sizeSum ;
		setSumSize(curr_table_node->child[i]);
	}
}

/*
	Puts all strings in an array by traversing down the tree
*/
void getStrings(ASTNode *nodeToPut){
	if(strcmp(nodeToPut->lexeme,",")!=0){
		strcpy(strings[stringInd++],nodeToPut->lexeme);
		return;
	}
	ASTNode *temporaryAST = (ASTNode *)malloc(sizeof(ASTNode));
	temporaryAST = nodeToPut;
	if(temporaryAST->child[0]==NULL){		
		strcpy(strings[stringInd++],temporaryAST->lexeme);
	}
	while(temporaryAST->child[0]!=NULL){
		strcpy(strings[stringInd++],temporaryAST->child[1]->lexeme);
		temporaryAST = temporaryAST->child[0];
	}
	temporaryAST=nodeToPut;
	while(strcmp(temporaryAST->lexeme,",")==0){
		temporaryAST = temporaryAST->child[0];
	}
	strcpy(strings[stringInd++],temporaryAST->lexeme);
}

/*
	Checks if main functions exists in global functions
*/
int checkMain(){	
	for(int i=0;i<funTree->numberOfChilds;++i) 
		if(!strcmp(funTree->children[i]->functionName,"main")) return 1;
	return 0;
}
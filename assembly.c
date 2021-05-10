#include "assembly.h"


/*
	Recursively generates code for an astnode
*/
void generateCode(FILE *fp,ASTNode *currASTNode){
	// base case
	if(currASTNode==NULL) return;
	int numberOfChildren = calculateChildrenCount(currASTNode);
	int isScopeChanged = 0;
	int current_scope_previous;
	if(currASTNode->astScopeNode->scope > current_scope){
		isScopeChanged = 1;
		fprintf(fp,"\tli $t0, %d\n\tsub $sp, $sp, $t0\n\tmove $t2, $sp\n",currASTNode->astScopeNode->tableSize);
		current_scope_previous = current_scope;
		current_scope = currASTNode->astScopeNode->scope;		
	}
	
	if(currASTNode->progType >= IDEN_RELATED){		
		load_spill_array_identifier(fp,currASTNode,0);
	} 
	else if(currASTNode->progType == CONSTANTS ){
		if(currASTNode->type == INT){
			fprintf(fp,"\tli $t1, %s\n",currASTNode->lexeme);	  //load number
		} else if(currASTNode->type == CHAR){			
			fprintf(fp,"\tli $t1, %d\n",currASTNode->lexeme[1]); // load character
		} else if(currASTNode->type == STRING){			
			fprintf(fp,"\tla $t1, %d\n",currASTNode->lexeme[1]); // load character
		}												
		
		// decrement current stack pointer $t2
		fprintf(fp,"\tli $t3,4\n\tsub $t2,$t2,$t3\n\tsw $t1,0($t2)\n\n");	// store result in $t2
	}
	else if(!strcmp(currASTNode->lexeme,"output")){
		symbolTable* curr_table  = getSymbolTable(currASTNode->child[1]->lexeme,  currASTNode);
		loadFromStack(fp,"$a0",curr_table,currASTNode->child[1]->astScopeNode,0);
		if(currASTNode->child[0]->type == INT){
			fprintf(fp,"\tli $v0,1\n\tsyscall\n\tli $a0,32\n\tli $v0,11\n\tsyscall\n");
		} else if(currASTNode->child[0]->type == CHAR){
			fprintf(fp,"\tli $v0,11\n\tsyscall\n\tli $a0,32\n\tsyscall\n");
		} else if(currASTNode->child[0]->type == STRING){
			fprintf(fp,"\tli $v0,4\n\tla $a0,%s\n\tsyscall\n",currASTNode->child[1]->lexeme);
		}
	}
	else if(!strcmp(currASTNode->lexeme,"input")){
		if(currASTNode->child[0]->type == INT){
			fprintf(fp,"\tli $v0,5\n\tsyscall\n");
		}
		else if(currASTNode->child[0]->type == CHAR){
			fprintf(fp,"\tli $v0,12\n\tsyscall\n");
		}
		else if(currASTNode->child[0]->type == STRING){
			fprintf(fp,"\tli $v0,8\n\t\n\tla $a0, %s\n\tsyscall\n",currASTNode->child[1]->lexeme);
		}
		
		symbolTable* curr_table  = getSymbolTable(currASTNode->child[1]->lexeme, currASTNode); 
		spill(fp,"$v0",curr_table,currASTNode->child[1]->astScopeNode,0);
	}
	else if(numberOfChildren == 2 && checkIfOperator(currASTNode->lexeme)==1 ) {
		for(int child_index=0;child_index<numberOfChildren;child_index++) generateCode(fp,currASTNode->child[child_index]);
		fprintf(fp,"\tlw $t1,0($t2)\n\tlw $t0,4($t2)\n\tli $t3,4\n\tadd $t2,$t2,$t3\n");		// right operand  $t1, left operand   $t0,  t3 temp stack for calculations
		operationsCode(fp,currASTNode->lexeme);
		fprintf(fp,"\tsw $t1,0($t2)\n\n");
	}
	else if(numberOfChildren == 1 && checkIfOperator(currASTNode->lexeme)==1 ){
		generateCode(fp,currASTNode->child[0]);
		fprintf(fp,"\tlw $t1,0($t2)\n");
		if(strcmp(currASTNode->lexeme, "-") == 0){
				fprintf(fp,"\tsub $t1,$0,$t1\n");
		}
		else{
			fprintf(fp,"\tseq $t1,$0,$t1\n");
		}
		fprintf(fp,"\tsw $t1,0($t2)\n\n");
	}
	else if(!strcmp(currASTNode->lexeme,"Newline")){
		fprintf(fp,"\n\tmove $s1,$a0\n\tla $a0, newline_FIXED\n\tli $v0,4\n\tsyscall\n\tmove $a0,$s1\n\t");
	}
	else if(currASTNode->type==STRING_ASSIGN_CONCAT){
			char labelHere[100];
			getNewLabel(labelHere);
			fprintf(fp,"\n\tla $s1, %s\n\tli $t6,10\n\tla $s2, %s\n\tloop%s:\n\tlb $t5, 0($s1)\n\tbeqz $t5, next%s\n\tbeq $t5, $t6, next%s\n\tsb $t5, 0($s2)\n\taddi $s1,$s1,1\n\taddi $s2,$s2,1\n\tj loop%s\n\tnext%s:\n\tla $s1, %s\n\tloop2%s: \n\tlb $t5, 0($s1) \n\tbeqz $t5, next2%s \n\tbeq $t5, $t6 next2%s\n\tsb $t5, 0($s2) \n\taddi $s1,$s1,1\n\taddi $s2,$s2,1\n\tj loop2%s\n\tsb $zero,0($s2)\n\tnext2%s:\n\tsb $zero,0($s2)\n\t",currASTNode->child[1]->child[0]->lexeme,currASTNode->child[0]->lexeme,labelHere,labelHere,labelHere,labelHere,labelHere,currASTNode->child[1]->child[1]->lexeme,labelHere,labelHere,labelHere,labelHere,labelHere);
	}
	else if(!strcmp(currASTNode->lexeme,"=")){		 
		if(currASTNode->type==MUTATE_STRING){
			fprintf(fp,"\n\tla $s1, %s\n\tla $t6, constant%s\n\taddi $s1,$s1,%s\n\tlb $t5,0($t6)\n\tsb $t5,0($s1)\n\t",currASTNode->child[0]->lexeme,currASTNode->child[1]->lexeme,currASTNode->child[0]->child[0]->lexeme);
		}
		else if(currASTNode->type==STRING_ASSIGN_VAR){
			char labelHere[100];
			getNewLabel(labelHere);
			fprintf(fp,"\n\tli $s2,0\n\tla $t5, %s\n\tla $s1, %s\n\tloopss%s:\n\tlb   $t6, 0($t5)\n\tsb   $t6, 0($s1)\n\taddi $t5, $t5,1\n\taddi $s1,$s1,1\n\taddi $s2,$s2,1\n\tblt  $s2, 100, loopss%s\n",currASTNode->child[1]->lexeme,currASTNode->child[0]->lexeme,labelHere,labelHere);
		}
		else if(currASTNode->child[0]->type==STRING){
			char labelHere[100];
			getNewLabel(labelHere);
			fprintf(fp,"\n\tli $s2,0\n\tla $t5, constant%s\n\tla $s1, %s\n\tloop%s:\n\tlb   $t6, 0($t5)\n\tsb   $t6, 0($s1)\n\taddi $t5, $t5,1\n\taddi $s1,$s1,1\n\taddi $s2,$s2,1\n\tblt  $s2, 100, loop%s\n",currASTNode->child[1]->lexeme,currASTNode->child[0]->lexeme,labelHere,labelHere);
		}
		else{
			generateCode(fp,currASTNode->child[1]);
			fprintf(fp,"\tlw $t1,0($t2)\n");	
			load_spill_array_identifier(fp,currASTNode->child[0],1);
			if(strcmp(currASTNode->parent->lexeme,currASTNode->lexeme)){
				fprintf(fp,"\tadd $t2,$t2,4\n" );
			}
		}
	}
	else if(currASTNode->progType == WHILE_LOOP){
		char while_expression[100],while_body_outer[100];// these should not leave anything in 0($t2)
		getNewLabel(while_expression);
		getNewLabel(while_body_outer);
		strcpy(currASTNode->labels[0],while_expression);
		strcpy(currASTNode->labels[1],while_body_outer);
		fprintf(fp,"%s:\n",while_expression);
		generateCode(fp,currASTNode->child[0]);		// generate code for expression evaluation
		fprintf(fp,"\tlw $t0,0($t2)\n\tbeq $0, $t0,%s\n",while_body_outer);
		generateCode(fp,currASTNode->child[1]);		// generate code for body of the loop
		fprintf(fp,"b %s\n%s:\n",while_expression,while_body_outer);
	}						
	else if(currASTNode->progType == FOR_TYPE_ONE || currASTNode->progType==FOR_TYPE_TWO){
		char for_condition[100],for_body_outer[100];
		getNewLabel(for_condition);					
		getNewLabel(for_body_outer);	
		strcpy(currASTNode->labels[0],for_condition);	
		strcpy(currASTNode->labels[1],for_body_outer); 
		generateCode(fp,currASTNode->child[0]); // for declaration
		fprintf(fp,"%s:",for_condition);
		generateCode(fp,currASTNode->child[1]);      // for condition code generation          
		fprintf(fp,"\tlw $t1,0($t2)\n\tadd $t2,$t2,4\n\tbeq $t1,$0,%s\n",for_body_outer);       // if false leave out of for         
		if(currASTNode->progType==FOR_TYPE_ONE) generateCode(fp,currASTNode->child[2]); // for loop body
		else {
			generateCode(fp,currASTNode->child[3]); // for loop body
			generateCode(fp,currASTNode->child[2]); // for loop increment / decrement expression
		}
		fprintf(fp,"\tb %s\n%s:\n",for_condition,for_body_outer); // go back to for condition , for outer body
	}
	else if(currASTNode->progType == IF_TYPE_ONE || currASTNode->progType == IF_TYPE_TWO){
		char if_body_outer[100]; // to go out of in if(){} 
		char else_body[100];// to go inside else of if(){}else{}
		getNewLabel(if_body_outer);
		getNewLabel(else_body);
		generateCode(fp,currASTNode->child[0]);
		fprintf(fp,"\tlw $t0,0($t2)\n\tadd $t2,$t2,4\n");
		if(currASTNode->progType == IF_TYPE_ONE){		
			fprintf(fp,"\tbeq $0, $t0,%s\n",if_body_outer); // in if(){} type of statements go out of 'if' if condition is false
		} else {
			fprintf(fp,"\tbeq $0, $t0,%s\n",else_body); // in if(){}else{} type of statements go to 'else' if condition is false
		}
		generateCode(fp,currASTNode->child[1]); // if body	
		if(currASTNode->progType == IF_TYPE_TWO){				
			fprintf(fp,"\tb %s\n%s:\n",if_body_outer,else_body); // do not go in else part if coming from 'if' part
			generateCode(fp,currASTNode->child[2]);			
		}	
		fprintf(fp,"%s:\n",if_body_outer);	
	}
	else if(currASTNode->type == CONTINUE || currASTNode->type == BREAK){
		int label_index = 0; // 0-> go to next iteration label
		if(currASTNode->type == BREAK) label_index = 1; // 1-> exit while/for loop label
		ASTNode *for_or_while_loop = getClosestForOrWhile(currASTNode);
		if(for_or_while_loop!=NULL){
			fprintf(fp,"\tb %s\n",for_or_while_loop->labels[label_index]);
		}
	}
	else if(currASTNode->type == RETURN){
		if(numberOfChildren == 1){
			generateCode(fp,currASTNode->child[0]);
			fprintf(fp,"\tlw $v0,0($t2)\n");
		}
		int sizeDifference = currASTNode->astScopeNode->sizeSum - globalSymNode->sizeSum;
		fprintf(fp,"\tadd $sp, $sp, %d\n\tmove $t2, $sp\n\tjr $ra\n",sizeDifference);
	}
	else if(currASTNode->progType == FUNCTION_WITHOUT_ARGUMENT){			//function calls 
		fprintf(fp,"\tli $t0,4\n\tsub $sp,$sp,$t0\n\tsw $ra,0($sp)\n\tmove $t2,$sp\n\tjal %s\n\n",currASTNode->lexeme);
		fprintf(fp,"\tlw $ra,0($sp)\n\tadd $sp,$sp,4\n\tmove $t2,$sp\n");
		if(currASTNode->type != VOID){
			fprintf(fp,"\tli $t0,4\n\tsub $t2,$t2,$t0\n\tsw $v0,0($t2)\n");
		}
	}
	else if(currASTNode->progType == FUNCTION_WITH_ARGUMENT){
		processFunctionArguments(fp,currASTNode->child[0]);
		fprintf(fp,"\tli $t0,4\n\tsub $sp,$sp,$t0\n\tsw $ra,0($sp)\n\tmove $t2,$sp\n\tli $t0,12\n\tsub $sp,$sp,$t0\n");
		fprintf(fp,"\tjal %s\n\n\tadd $sp,$sp,12\n\tlw $ra,0($sp)\n\tadd $sp,$sp,4\n\tmove $t2,$sp\n",currASTNode->lexeme);
		
		if(currASTNode->type != VOID){
			fprintf(fp,"\tli $t0,4\n\tsub $t2,$t2,$t0\n\tsw $v0,0($t2)\n");
		}
	}
	else {
		for(int child_index=0;child_index<numberOfChildren;child_index++) 
			generateCode(fp,currASTNode->child[child_index]);
	}

	if(isScopeChanged == 1){
			fprintf(fp,"\tli $t0, %d\n\tadd $sp, $sp, $t0\n\tmove $t2, $sp\n",currASTNode->astScopeNode->tableSize);	
			current_scope = current_scope_previous;
	}
}

/*
	Generates code for instructions that perform mathematical operations
*/
void operationsCode(FILE *fp,char *s){	
	for(int index=0;index<OPERATORS_COUNT;index++){		
		if(strcmp(s,operators[index])==0){			
			if((strcmp(s,"&&") == 0) || (strcmp(s,"||") == 0)) {
				fprintf(fp,"\t%s $t9,$t0,$t1\n\tsne $t1,$t9,$0\n",instruction_for_operators[index]);
			} else {
				fprintf(fp,"\t%s $t1,$t0,$t1\n",instruction_for_operators[index]);
			} 
			return;						
		}
	}		
}

void spill(FILE *fp,char *reg,symbolTable *currSymbolNode,tableNode *currTableNode,int isArr){
	if(currSymbolNode->parentTableNode->scope == 0){
		fprintf(fp,"\tla $t9,global\n\tadd $t9,$t9,%d\n",currSymbolNode->offset);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n"); // to add the base address of array
		fprintf(fp,"\tsw %s, 0($t9)\n",reg); // otherwise there is no offset
	}	
	else if(currTableNode->scope == currSymbolNode->parentTableNode->scope){
		fprintf(fp,"\tadd $t9,$sp,%d\n",currSymbolNode->offset);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n");
		fprintf(fp,"\tsw %s, 0($t9)\n",reg);
	}
	else{
		int sizeDifference =  currTableNode->sizeSum + currSymbolNode->offset - currSymbolNode->parentTableNode->sizeSum  ;
		fprintf(fp,"\tadd $t9,$sp,%d\n",sizeDifference);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n"); 
		fprintf(fp,"\tsw %s, 0($t9)\n",reg);	
	}	
}

void loadFromStack(FILE *fp,char *reg,symbolTable *currSymbolNode,tableNode *currTableNode,int isArr){			
	if(currSymbolNode->parentTableNode->scope == 0){
		fprintf(fp,"\tla $t9,global\n\tadd $t9,$t9,%d\n",currSymbolNode->offset);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n");
		fprintf(fp,"\tlw %s, 0($t9)\n",reg);
	}
	else if(currTableNode->scope == currSymbolNode->parentTableNode->scope){
		fprintf(fp,"\tadd $t9,$sp,%d\n",currSymbolNode->offset);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n");
		fprintf(fp,"\tlw %s, 0($t9)\n",reg);
	}
	else{
		int sizeDifference =  currTableNode->sizeSum - currSymbolNode->parentTableNode->sizeSum + currSymbolNode->offset;
		fprintf(fp,"\tadd $t9,$sp,%d\n",sizeDifference);
		if(isArr==1) fprintf(fp,"\tadd $t9,$t9,$t8\n");
		fprintf(fp,"\tlw %s, 0($t9)\n",reg);
	}
}

void load_spill_array_identifier(FILE *fp,ASTNode*curr_node,int type){	// 0 == loadFromStack from stack , 1 == store to stack
		int offset;	// there is value in $t1 ,, save before calling generateCode
		if(curr_node->progType==IDEN_RELATED){
			offset = 0;
			if(type==0){
				fprintf(fp,"\tli $t3,4\n\tsub $t2,$t2,$t3\n");
				symbolTable* curr_table  = getSymbolTable(curr_node->lexeme, curr_node);
				loadFromStack(fp,"$t4",curr_table,curr_node->astScopeNode,offset);	
				fprintf(fp,"\tsw $t4,0($t2)\n\n" );
			}	
		}
		else if(curr_node->progType == ARRAY_SINGLE_DIM){
			fprintf(fp,"move $s0,$t1\n");
			generateCode(fp,curr_node->child[0]);
			fprintf(fp,"move $t1,$s0\n\tlw $t8,0($t2)\n\tli $t9,4\n\tmul $t8,$t8,$t9\n");	// add $t8 in offset
			offset = 1;
			if(type==0){
				symbolTable* curr_table  = getSymbolTable(curr_node->lexeme,curr_node);
				loadFromStack(fp,"$t4",curr_table,curr_node->astScopeNode,offset);	//	load variable from sp and put on current stack pointed by $t3								
				fprintf(fp,"\tsw $t4,0($t2)\n\n");
			}
			if(type==1)
				fprintf(fp,"\tadd $t2,$t2,4\n");
		}
		if(type == 1){
			symbolTable* curr_table  = getSymbolTable(curr_node->lexeme, curr_node);		
			spill(fp,"$t1",curr_table,curr_node->astScopeNode,offset);
		}	
}

/*
	Generates code for putting all arguments in place
*/
void processFunctionArguments(FILE *fp,ASTNode *currASTNode){

	// arguments is a tree like (ifmultiple arguments)-

			//               node
			//             /     \
			//           node   arg4
			//         /     \	
			//       node   arg3
			//      /     \
			//    arg1   arg2 

	// arguments is a tree like (if one)-

			//               arg1			
 
	ASTNode *currArgumentNode=currASTNode;	
	int index = findIndexInFunTree(currASTNode);	

	// assuming index!=-1	
	
	// go to leftmost child i.e. first argument
	while(strcmp(currArgumentNode->lexeme,",")==0)
		currArgumentNode = currArgumentNode->child[0];

	int recordSpace = 0;
	int recordSize;
	int is_first_argument = 1;

	if(currASTNode == currArgumentNode){
		// case when only one argument
		generateCode(fp,currArgumentNode);
		// size of activation record
		recordSize = funTree->children[index]->funcScopeNode->tableSize - recordSpace + 16;			
		fprintf(fp,"\tmove $t0,$sp\n\tli $t1, %d\n\tsub $t0,$t0,$t1\n\tlw $t4,0($t2)\n",recordSize);
		recordSpace += 4; 
		fprintf(fp,"\tsw $t4,0($t0)\n");
	} 
	else{
		while(currArgumentNode != currASTNode->parent){
			if(is_first_argument==0){	
				// rest of the arguments from 2 are right child of the node			
				generateCode(fp,currArgumentNode->child[1]);
			} 
			else {
				// first argument is the node itself
				generateCode(fp,currArgumentNode);	
				is_first_argument=0;			
			}
			recordSize = funTree->children[index]->funcScopeNode->tableSize - recordSpace  + 16;
			fprintf(fp,"\tmove $t8,$sp\n\tli $t7, %d\n\tsub $t8,$t8,$t7\n\tlw $t4,0($t2)\n\tadd $t2,$t2,4\n",recordSize);
			recordSpace += 4;
			fprintf(fp,"\tsw $t4,0($t8)\n");
			// go to next argument, travel up the tree
			currArgumentNode = currArgumentNode->parent;
		}
	}
}

/*
	Calculates count of children in astnode
*/
int calculateChildrenCount(ASTNode* currASTNode){	
	int index = 0;
	while(currASTNode->child[index]!=NULL) index++;
	return index;
}

/*
	Generates a new label
*/
void getNewLabel(char *s){		
	sprintf(s,"%s_%d",funTree->children[current_function_index]->functionName,global_labels_count++);	
}

/*
	Checks if lexeme if one of the operators defined
*/
int checkIfOperator(char* lexeme){			
	for(int index=0;index<OPERATORS_COUNT;index++){
		if(strcmp(lexeme, operators[index])==0) return 1;
	}
	return 0;
}

/*
	Finds index of a function from funTree that stores all global functions
*/
int findIndexInFunTree(ASTNode* currASTNode){
	for(int index=0;index<funTree->numberOfChilds;index++){
		if(strcmp(currASTNode->parent->lexeme,funTree->children[index]->functionName)==0){
			return index;			
		}
	}
	return -1;
}

/*
	Returns the astnode for closest outside for or while loop
*/
ASTNode * getClosestForOrWhile(ASTNode *currASTNode){
	ASTNode* iteration_node = currASTNode;
	while(iteration_node!=NULL){
		if((strcmp(iteration_node->lexeme, "for")==0) || (strcmp(iteration_node->lexeme, "while")==0)) return iteration_node;
		// check in parent node
		iteration_node = iteration_node->parent;			
	}
	return NULL;
}

/* 
	Generates MIPS code into a file
*/
void createAssembly(){	
	FILE *fp = fopen("target.s","w");	

	global_labels_count = 0;	// assign unique labels
	current_scope = 0;			// scope level
		
	// Initial code
	fprintf(fp,".data\n");

	// allocate space for strings
	fprintf(fp,"\n\tnewline_FIXED: .asciiz \"\n\"\n");
	for(int i=0;i<stringInd;i++){
		fprintf(fp,"\t%s: .space 100\n",strings[i]);
	}
	for(int i=0;i<ConstantStringInd;i++){
		fprintf(fp,"\tconstant%d: .asciiz %s\n",i,ConstantStrings[i]);
	}
	fprintf(fp,"global: .word %d\n",globalSymNode->tableSize);
	fprintf(fp,".text\n");

	// for each function generate individual code
	for(int i=0;i<funTree->numberOfChilds;++i){
		current_function_index = i;
		// start function by creating the stack frame of the total size of all variable, store sp in t2
		fprintf(fp,"%s:\n\tli $t0, %d\n\tsub $sp, $sp, $t0\n\tmove $t2, $sp\n",funTree->children[i]->functionName,funTree->children[i]->funcScopeNode->tableSize);
		current_scope = funTree->children[i]->funcScopeNode->scope;	
		// generate code for this function, second child or child[1] contains the tree of statements inside function
		generateCode(fp,funTree->children[i]->astNode->child[1]);		
		// remove stack frame, jump back to the address in return address register
		fprintf(fp,"\tli $t0, %d\n\tadd $sp, $sp, $t0\n\tmove $t2, $sp\n\tjr $ra\n",funTree->children[i]->funcScopeNode->tableSize);
	}
	fclose(fp);	
}

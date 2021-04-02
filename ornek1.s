;*******************************************************************************
;@file				 Main.s
;@project		     Microprocessor Systems Term Project
;@date
;
;@PROJECT GROUP
;@groupno
;@member1
;@member2
;@member3
;@member4
;@member5
;*******************************************************************************
;*******************************************************************************
;@section 		INPUT_DATASET
;*******************************************************************************

;@brief 	This data will be used for insertion and deletion operation.
;@note		The input dataset will be changed at the grading. 
;			Therefore, you shouldn't use the constant number size for this dataset in your code. 
				AREA     IN_DATA_AREA, DATA, READONLY
IN_DATA			DCD		0x10, 0x20, 0x15, 0x65, 0x25, 0x01, 0x01, 0x12, 0x65, 0x25, 0x85, 0x46, 0x10, 0x00
END_IN_DATA

;@brief 	This data contains operation flags of input dataset. 
;@note		0 -> Deletion operation, 1 -> Insertion 
				AREA     IN_DATA_FLAG_AREA, DATA, READONLY
IN_DATA_FLAG	DCD		0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x00, 0x02 
END_IN_DATA_FLAG


;*******************************************************************************
;@endsection 	INPUT_DATASET
;*******************************************************************************

;*******************************************************************************
;@section 		DATA_DECLARATION
;*******************************************************************************

;@brief 	This part will be used for constant numbers definition.
NUMBER_OF_AT	EQU		20									; Number of Allocation Table
AT_SIZE			EQU		NUMBER_OF_AT*4						; Allocation Table Size   				;80 byte 640 bit 


DATA_AREA_SIZE	EQU		AT_SIZE*32*2						; Allocable data area					
															; Each allocation table has 32 Cell
															; Each Cell Has 2 word (Value + Address)
															; Each word has 4 byte
ARRAY_SIZE		EQU		AT_SIZE*32							; Allocable data area
															; Each allocation table has 32 Cell
															; Each Cell Has 1 word (Value)
															; Each word has 4 byte
LOG_ARRAY_SIZE	EQU     AT_SIZE*32*3						; Log Array Size
															; Each log contains 3 word
															; 16 bit for index
															; 8 bit for error_code
															; 8 bit for operation
															; 32 bit for data
															; 32 bit for timestamp in us

;//-------- <<< USER CODE BEGIN Constant Numbers Definitions >>> ----------------------															
							


;//-------- <<< USER CODE END Constant Numbers Definitions >>> ------------------------	

;*******************************************************************************
;@brief 	This area will be used for global variables.
				AREA     GLOBAL_VARIABLES, DATA, READWRITE		
				ALIGN	
TICK_COUNT		SPACE	 4									; Allocate #4 byte area to store tick count of the system tick timer.
FIRST_ELEMENT  	SPACE    4									; Allocate #4 byte area to store the first element pointer of the linked list.
INDEX_INPUT_DS  SPACE    4									; Allocate #4 byte area to store the index of input dataset.
INDEX_ERROR_LOG SPACE	 4									; Allocate #4 byte aret to store the index of the error log array.
PROGRAM_STATUS  SPACE    4									; Allocate #4 byte to store program status.
															; 0-> Program started, 1->Timer started, 2-> All data operation finished.
;//-------- <<< USER CODE BEGIN Global Variables >>> ----------------------															
							
ALLOCATED_AREA  SPACE	 4 									; Allocated area counter

;//-------- <<< USER CODE END Global Variables >>> ------------------------															

;*******************************************************************************

;@brief 	This area will be used for the allocation table
				AREA     ALLOCATION_TABLE, DATA, READWRITE		
				ALIGN	
__AT_Start
AT_MEM       	SPACE    AT_SIZE							; Allocate #AT_SIZE byte area from memory.
__AT_END

;@brief 	This area will be used for the linked list.
				AREA     DATA_AREA, DATA, READWRITE		
				ALIGN	
__DATA_Start
DATA_MEM        SPACE    DATA_AREA_SIZE						; Allocate #DATA_AREA_SIZE byte area from memory.
__DATA_END

;@brief 	This area will be used for the array. 
;			Array will be used at the end of the program to transform linked list to array.
				AREA     ARRAY_AREA, DATA, READWRITE		
				ALIGN	
__ARRAY_Start
ARRAY_MEM       SPACE    ARRAY_SIZE							; Allocate #ARRAY_SIZE byte area from memory.
__ARRAY_END

;@brief 	This area will be used for the error log array. 
				AREA     ARRAY_AREA, DATA, READWRITE		
				ALIGN	
__LOG_Start
LOG_MEM       	SPACE    LOG_ARRAY_SIZE						; Allocate #DATA_AREA_SIZE byte area from memory.
__LOG_END

;//-------- <<< USER CODE BEGIN Data Allocation >>> ----------------------															
							


;//-------- <<< USER CODE END Data Allocation >>> ------------------------															

;*******************************************************************************
;@endsection 	DATA_DECLARATION
;*******************************************************************************

;*******************************************************************************
;@section 		MAIN_FUNCTION
;*******************************************************************************

			
;@brief 	This area contains project codes. 
;@note		You shouldn't change the main function. 				
				AREA MAINFUNCTION, CODE, READONLY
				ENTRY
				THUMB
				ALIGN 
__main			FUNCTION
				EXPORT __main
				BL	Clear_Alloc					; Call Clear Allocation Function.
				BL  Clear_ErrorLogs				; Call Clear ErrorLogs Function.
				BL	Init_GlobVars				; Call Initiate Global Variable Function.
				BL	SysTick_Init				; Call Initialize System Tick Timer Function.
				LDR R0, =PROGRAM_STATUS			; Load Program Status Variable Addresses.
LOOP			LDR R1, [R0]					; Load Program Status Variable.
				CMP	R1, #2						; Check If Program finished.
				BNE LOOP						; Go to loop If program do not finish.
STOP			B	STOP						; Infinite loop.
				
				ENDFUNC
			
;*******************************************************************************
;@endsection 		MAIN_FUNCTION
;*******************************************************************************				

;*******************************************************************************
;@section 			USER_FUNCTIONS
;*******************************************************************************

;@brief 	This function will be used for System Tick Handler
SysTick_Handler	FUNCTION	
				EXPORT SysTick_Handler
;//-------- <<< USER CODE BEGIN System Tick Handler >>> ----------------------															
				PUSH{LR} ;
				
				
				;TICK COUNT INCREASE;
				LDR R1, =TICK_COUNT		
				LDR R0, [R1]  					; Load the tick count to r0
				ADDS R0,R0,#1					; TICK_COUNT++
				STR R0,[R1]						;
				;XXXXXXXXXXXXXXXXXXX;
				
				;R6 = index, R5 = Operation Flag,R0 
				LDR R5, =IN_DATA_FLAG			; Load the address of IN_DATA_FLAG to R5
				LDR R6, =INDEX_INPUT_DS			; Load the address of INDEX_INPUT_DS (variable) to R6
				LDR R6,[R6]						; Load the value of INDEX_INPUT_DS to R6
				LDR R5,[R5,R6]					; R5 <-- IN_DATA_FLAG(i)
				
				CMP R5,#0						; If flag is 0, remove
				BEQ remove_this	
				CMP R5,#1						; If flag is 1, insert
				BEQ insert_this
				CMP R5,#2						; If flag is 2, transfer to array
				BEQ array_transfer
				B no_command					; If flag is something else, error code : 6
			

remove_this	

				LDR R7,=IN_DATA					; Load the address of IN_DATA address
				LDR R0,[R7,R6]					; R0 <--IN_DATA(i)
				PUSH{R6,R0,R5}					; R6 = Index , R0 = Data , R5 = Op Flag
				BL Remove
				CMP R0,#0						; Check if success
				BEQ continue_pop					; No error
				
				MOVS R1,R0						; R1 <- Error Code
				POP{R6,R0,R5}					; Restore registers
				MOVS R0,R6						; R0 <- Index
				MOVS R2,R5						; R2 <- Op Flag
				MOVS R3,R0						; R3 <- Data
				BL WriteErrorLog				; Call function
				B continue
				
				
				
insert_this		

				LDR R7,=IN_DATA					; Load the address of IN_DATA address
				LDR R0,[R7,R6]					; R0 <--IN_DATA(i)
				PUSH{R6,R0,R5}					; R6 <- Index , R0 <- Data , R5 = Op Flag
				BL Insert
				CMP R0,#0						; Check success
				BEQ continue_pop				; No error

				MOVS R1,R0						; R1 <- Error Code
				POP{R6,R0,R5}					; Restore registers
				MOVS R0,R6						; R0 <- Index
				MOVS R2,R5						; R2 <- Op Flag
				MOVS R3,R0						; R3 <- Data
				BL WriteErrorLog				; Call function
				B continue




array_transfer	
				
				LDR R7,=IN_DATA					; Load the address of IN_DATA address
				LDR R0,[R7,R6]					; R0 <--IN_DATA(i)
				PUSH{R6,R0,R5}					; R6 <- Index , R0 <- Data , R5 = Op Flag
				BL LinkedList2Arr 
				CMP R0,#0						; Check success
				BEQ continue_pop				; No error
				
				MOVS R1,R0						; R1 <- Error Code
				POP{R6,R0,R5}					; Restore registers
				MOVS R0,R6						; R0 <- Index
				MOVS R2,R5						; R2 <- Op Flag
				MOVS R3,R0						; R3 <- Data
				BL WriteErrorLog				; Call function
				B continue
				

no_command		LDR R3,=IN_DATA					; Load the address of IN_DATA address
				LDR R3,[R3]						; R3 <- Data
				MOVS R0,R6						; R0 <- Index
				MOVS R1,#6						; R1 <- Error Code : 6
				MOVS R2,R5						; R1 <- Op Flag
				BL WriteErrorLog				; Call function
				B continue
							
	
continue_pop	POP	{R6,R0,R5}					; Clear Stack

continue		LDR R7, =IN_DATA				; Start address of IN_DATA array
				LDR R6,=INDEX_INPUT_DS			;Load the address of INDEX_INPUT_DS
				LDR R6,[R6]						;Load the value of INDEX_INPUT_DS
				ADDS R7,R7,R6 					; R7 <-- Start Address of IN_DATA + Current Iteration = Previous Address of current node
				ADDS R7,R7,#4					; Address of Current Node
				LDR R5,=END_IN_DATA				; R5 <-- Address of last element of IN_DATA
				CMP R7,R5						
				BEQ	program_finish						; Stop timer interrupt
				


				LDR R3,=INDEX_INPUT_DS			;Load the address of INDEX_INPUT_DS
				LDR R6,[R3]						;Load the value of INDEX_INPUT_DS
				ADDS R6,R6,#4					; Index++
				STR R6,[R3]						; Update INDEX_INPUT_DS
				B 	iter_finish

program_finish	BL SysTick_Stop
		


iter_finish 	POP{PC}				
;//-------- <<< USER CODE END System Tick Handler >>> ------------------------				
				ENDFUNC
			
				
;*******************************************************************************				

;@brief 	This function will be used to initiate System Tick Handler
SysTick_Init	FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Timer Initialize >>> ----------------------															

				LDR R1, =0xE000E010 			; Load Control and Status Register Adress to R1.
				LDR R0, =318   					; Load Reload Value to R0
				STR R0, [R1,#4]					; Store Reload Value to Reload Value Register.
				MOVS R0, #0
				STR R0, [R1,#8]					; Current Value Register is initially 0.
				MOVS R0, #7						; 
				STR R0, [R1]					; Flags are 111
				MOVS R0, #1						
				LDR R1, =PROGRAM_STATUS			; Load the address of program_status to r1
				STR R0, [R1]					; Set the program_status to 1
				
				BX LR

;//-------- <<< USER CODE END System Tick Timer Initialize >>> ------------------------				
				ENDFUNC

;*******************************************************************************				

;@brief 	This function will be used to stop the System Tick Timer
SysTick_Stop	FUNCTION			
;//-------- <<< USER CODE BEGIN System Tick Timer Stop >>> ----------------------	
				
				LDR R1, =0xE000E010 			; Load Control and Status Register Adress to R1.
				MOVS R0, #0						
				STR R0, [R1]					; Timer stops
				LDR R1, =PROGRAM_STATUS
				MOVS R0, #2
				STR R0, [R1]					; PROGRAM_STATUS = 2 
				LDR R0, =PROGRAM_STATUS			;Return PROGRAM_STATUS from R0
				B LOOP
				
;//-------- <<< USER CODE END System Tick Timer Stop >>> ------------------------				
				ENDFUNC

;*******************************************************************************				

;@brief 	This function will be used to clear allocation table
Clear_Alloc		FUNCTION	
				
;//-------- <<< USER CODE BEGIN Clear Allocation Table Function >>> ----------------------															
	
				MOVS R2,#0 						; Index of Allocation Table					
loop			MOVS R0,#0						; Set R0 to 0
				LDR R1, =AT_MEM					; Load AT_MEM address to R1
				STR R0,[R1,R2]					; Write 0 to selected address
				ADDS R2,R2,#4					; Increase index by 1
				LDR R3, =AT_SIZE				; Load AT_SIZE value to R3
				CMP R2,R3						; Check if index has reached the end of the table
				BEQ return_main2				; Branch to return_main2
				B loop							; Go to loop
return_main2	BX LR							; Return Clear_Alloc


;//-------- <<< USER CODE END Clear Allocation Table Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************		

;@brief 	This function will be used to clear error log array
Clear_ErrorLogs	FUNCTION			
;//-------- <<< USER CODE BEGIN Clear Error Logs Function >>> ----------------------															


				MOVS R2,#0 						; Index of Error Logs												
loop2			MOVS R0,#0						; Set R0 to 0
				LDR R1, =LOG_MEM				; Load LOG_MEM address to R1
				STR R0,[R1,R2]					; Write 0 to selected address
				ADDS R2,R2,#4					; Increase index by 1
				LDR R3, =LOG_ARRAY_SIZE			; Load LOG_ARRAY_SIZE value to R3
				CMP R2, R3   					; Check if index has reached the end of the memory
				BEQ return_main					; Branch to return_main
				B loop2							; Go to loop
return_main		BX LR							; Return Clear_ErrorLogs
				
				
;//-------- <<< USER CODE END Clear Error Logs Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************

;@brief 	This function will be used to initialize global variables
Init_GlobVars	FUNCTION			
;//-------- <<< USER CODE BEGIN Initialize Global Variables >>> ----------------------															
				
				LDR R1, =TICK_COUNT				;
				MOVS R2, #0						;
				STR R2,[R1]						;

				LDR R1, =FIRST_ELEMENT				
				STR R2,[R1]

				LDR R1, =INDEX_INPUT_DS
				STR R2,[R1]

				LDR R1, =INDEX_ERROR_LOG
				STR R2,[R1]

				LDR R1, =PROGRAM_STATUS
				STR R2,[R1]

				LDR R1, =ALLOCATED_AREA			; Allocated area is 0 for startup
				STR R2,[R1]
				

				BX LR
				
				
;//-------- <<< USER CODE END Initialize Global Variables >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************	

;@brief 	This function will be used to allocate the new cell 
;			from the memory using the allocation table.				
;@return     R0 <- The allocated area address
Malloc            FUNCTION
;//-------- <<< USER CODE BEGIN System Tick Handler >>> ----------------------

				MOVS R7,#0						; Bitwise index of allocation table
                MOVS R3, #1 					; 00000001 is loaded to compare by bits
                LDR R1, =AT_MEM					; Load R1 with AT_MEM address
Malloc_loop     LDR R2, [R1]					; Load the value at R1
				PUSH {R2}						; Push R2
                ANDS R2, R2, R3					; Compare R2 with the selected bit in R3
                CMP R2, #0						; If bit is 0 return
                POP {R2}						; Pop R2
                BEQ Malloc_return
				ADDS R7,R7,#1					; Increase allocation table index
                LSLS R3, #1						; Switch to next bit
                CMP R3, #0						; If R3 is 0 go to Malloc_branch 
                BEQ Malloc_branch
                B Malloc_loop					; Goto Malloc_loop
Malloc_branch   ADDS R1, #1						; Switch to next byte in Allocation table
				MOVS R3, #1						; 00000001 is loaded to compare by bits
                B Malloc_loop					; Goto Malloc_loop
Malloc_return
	
				LDR R4,[R1]						; Load R4 with allocation table value at R1
				ADDS R4,R4,R3					; Update allocation table 
				STR R4,[R1]						; Store R4
				
				LDR R5,=DATA_MEM				; Load R5 with DATA_MEM
				MOVS R6,#8						; Set R6 to 8
                MULS R7,R6,R7					; Multiply Allocation table index by 8
				ADDS R0,R5,R7					; Get the next free area in DATA_MEM
				
				LDR R5,=ALLOCATED_AREA 			; Load Allocated Area address to r5
				LDR R4,[R5]						; Load Current Allocated area to r4
				ADDS R4,R4,#8					; Allocated Area Size += 8 
				STR R4,[R5]						; Update ALLOCATED_AREA		
				
				BX LR							; return
						
;//-------- <<< USER CODE END System Tick Handler >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used for deallocate the existing area
;@param		R0 <- Address to deallocate
Free			FUNCTION			
;//-------- <<< USER CODE BEGIN Free Function >>> ----------------------
				
				LDR R7,=DATA_MEM			;Load the start address of DATA_MEM to R7
				SUBS R0,R0,R7				;Address to allocate - start address of array = Iteration
				LSRS R0,#3					;To find which bit will be deallocated (Iteration / 8)
				LDR R6,=AT_MEM				;AT_MEM address to R6
				

free_loop		CMP R0,#8					;Compare R0 with 8
				BLO second_loop				;If R0 < 8 , branch second loop
				ADDS R6,R6,#1				;If not, increase allocation table index by 1
				SUBS R0,R0,#8				;R0 = R0 - 8 
				B free_loop					;
				;!At the end of this loop,
				;R6 = Address of the cell in Allocation Table to be edited
				;R0 = The bit to be cleared in the address.

second_loop		MOVS R5,#1					; R5 <- 00000001
				LDR R4,[R6]					; R4 <- Current cell of Allocation Table
				LSLS R5,R0					; Shift R5 by R0
				MVNS R5,R5					; Take complement of R5
				ANDS R4,R4,R5				; Clearing selected bit (masking)
				STR R4,[R6]					; Update allocation table

				LDR R5,=ALLOCATED_AREA 		; Load Allocated Area address to r5
				LDR R4,[R5]					; Load Current Allocated area to r4
				SUBS R4,R4,#8				; Allocated Area Size -= 8 
				STR R4,[R5]					; Update ALLOCATED_AREA

				BX LR			
				
;//-------- <<< USER CODE END Free Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to insert data to the linked list
;@param		R0 <- The data to insert
;@return    R0 <- Error Code
Insert			FUNCTION			
;//-------- <<< USER CODE BEGIN Insert Function >>> ----------------------															
				MOVS R1,R0					; Save the new value in R0
				LDR R7,=ALLOCATED_AREA		; Load allocated area address to R7
				LDR R6,[R7]					; Load allocated area value to r6
				CMP R6,#0					; If linked list is empty,
				BEQ if_empty				; Branch to if_empty
				
				LDR R3,=DATA_AREA_SIZE
				CMP R6,R3					; If linked list is full,
				BEQ	if_full					; Branch to if_full

				
				LDR R3,=FIRST_ELEMENT		; FIRST_ELEMENT (variable) adress
				LDR R3,[R3]					; Get the first element adress
				LDR R4,[R3,#0]				; Get the first value 
				CMP R1,R4					; Compare new value with first node value
				BEQ duplicate_error			; If new value = head value,  duplicate error
				BLO basa_ekle				; If new value < first value, branch
			
				; R3 is traverse pointer  , R1 is new value
		
traverse
				LDR R7,[R3,#0]				; Load the value of current node
				CMP R7,R1					; Compare the new value and current node's value
				BEQ duplicate_error			
				
				LDR R7,[R3,#4] 				; R7 <- next address of current node
				CMP R7,#0 					; Check if next node is NULL (LAST NODE)
				BEQ add_to_end
				
				LDR R7,[R3,#4]				; R7 <- Address of NEXT node
				LDR R7,[R7,#0]				; R7 <- Value of NEXT node
				CMP R1,R7					; Compare New Value and Value of NEXT node
				BLO add_between
				
				LDR R3,[R3,#4] 				; R3 = R3->next
				B traverse
				
add_between		PUSH{R1,R3,LR}
				BL Malloc					; New Node allocated
				POP{R1,R3}
				STR R1,[R0,#0]				; Newnode->Value = New value
				LDR R6,[R3,#4]				; Load NEXT node address of current node to R6
				STR R6,[R0,#4]				; Newnode->Next = Currentnode->next
				STR R0,[R3,#4]				; CurrentNode->Next = Newnode
				
				MOVS R0,#0					; Error Code: 0 (success)
				POP{PC}						; Return
				



add_to_end		PUSH{R1,R3,LR}
				BL Malloc					; new node allocated
				POP{R1,R3}
				STR R1,[R0,#0]				; newnode -> value = new value
				
				
				MOVS R5,#0
				STR R5,[R0,#4]				; newnode -> next = NULL
				STR R0,[R3,#4]				; Current node -> next = Newnode
				MOVS R0,#0					; Error code : 0 (success)
				POP{PC}						; Return




basa_ekle		PUSH{R1,R3,LR}
				BL Malloc
				POP{R1,R3}						; Allocate area 
				STR R1,[r0]					; Newnode-> Value = New value
				STR R3,[r0,#4]				; Newnode->Next = Address of first element
				LDR R3,=FIRST_ELEMENT		; Get the FIRST_ELEMENT address
				STR R0,[R3]					; Update head pointer (FIRST_ELEMENT)
				MOVS R0,#0					; Error code : 0 (Success)
				POP{PC}						; Return

if_empty		

				PUSH {R1,LR}				; Save R1 Value
				BL Malloc					; Allocate area for first element
				
				POP {R1}					; Restore R1 Value				
				LDR R3,=FIRST_ELEMENT		; Load first element adress to r3
				STR R0,[R3]					; FIRST_ELEMENT is the allocated area now.
				STR R1,[R0]					; Store the value to Allocated memory
				
				MOVS R7,#0
				STR R7,[R0,#4]				; Next Node is NULL
				MOVS R0, #0					; Return error code 0  (no error)
				POP{PC}						; Return
				


if_full			MOVS R0,#1 					; Return error code 1 (linked list is full) 
				BX LR						; Return with error code 1

duplicate_error	MOVS R0,#2					; Error code : 2 (Duplicate data)
				BX LR						; Return




;//-------- <<< USER CODE END Insert Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to remove data from the linked list
;@param		R0 <- the data to delete
;@return    R0 <- Error Code
Remove			FUNCTION			
;//-------- <<< USER CODE BEGIN Remove Function >>> ----------------------															

				MOVS R2,R0					; Save the value to R2
				LDR R1,=ALLOCATED_AREA		; Load ALLOCATED_AREA address to R1
				LDR R1,[R1]					; Load "allocated area" value to r1
				CMP R1,#0					; Check if there is no node 
				BEQ	error_empty
				
				LDR R1,=FIRST_ELEMENT		; Load FIRST_ELEMENT address to R1				
				LDR R1,[R1]					; Load the address of "first node" to R1
				
				
				LDR R7,[R1,#0]				; R7 <- Value of first node
				CMP R7,R2					; Compare the value and deleting value
				BEQ remov_from_head
				
				
				; R2 = Value which will be deleted , R6 = Current Node, R1 = Previous Node
				
				
traversee			LDR R6,[R1,#4]				; R6 = Current Node		
				LDR R5,[R6,#4]				;R5 = R6->Next
				CMP R5,#0				; Check if Current node is the last node
				BEQ last_node
				LDR R7,[R6,#0]				; R7 = Value of current node
				CMP R7,R2					; Compare current value and deleting value
				BEQ rem_in_between			; Value found
				
				MOVS R1,R6					; R1 = R1->NEXT
				
				
				B traversee					; Loop back


rem_in_between	
			
				LDR R3,[R6,#4]				; R3 = Currentnode->next
				STR R3,[R1,#4]				; Previousnode->next = currentnode->next
				MOVS R0,R6					; Argument for free()
				PUSH{LR}
				BL Free						; free()
				MOVS R0,#0					; Error code : 0 (success)
				POP{PC}						; Return
				





				
last_node			LDR R3,[R6,#0]				; R3 = Currentnode->Value
				CMP R3,R2				;
				BNE	no_element			; If lastnode-> != seeking value , error
				
				MOVS R4,#0					
				STR R4,[R1,#4]				; Previousnode->next = NULL
				
				MOVS R0,R6					; Argument for free()
				PUSH{LR}					;
				BL Free						; delete current node
				MOVS R0,#0					; Error code:0 (success)
				POP{PC}						;



remov_from_head 
				LDR R5,[R1,#4] 				; R5 = head-> next 				
				MOVS R0,R1					; Argument for free()				
				PUSH{R5,LR}
				BL Free						; delete node
				POP {R5}					; Restore R5 after return
				LDR R1,=FIRST_ELEMENT		; R1 <- Address of FIRST_ELEMENT 
				STR R5,[R1]					; FIRST_ELEMENT = next node
				MOVS R0,#0					; Error Code : 0 (success)
				POP{PC}



no_element		MOVS R0,#4					; Error code:4 (value is not found in the linked list)
				BX LR						; return


error_empty		MOVS R0,#3					; Error code : 3 (Linked List is empty)
				BX LR						; Return
				

;//-------- <<< USER CODE END Remove Function >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to clear the array and copy the linked list to the array
;@return	R0 <- Error Code
LinkedList2Arr	FUNCTION			
;//-------- <<< USER CODE BEGIN Linked List To Array >>> ----------------------															


				MOVS R2,#0              	; Index of ARRAY_MEM
                LDR R1,=ARRAY_MEM			; Load R1 with ARRAY_MEM address

lltar_loop      MOVS R0,#0                  ; Clear ARRAY_MEM
                STR R0,[R1,R2]				; Write 0 to selected address
                ADDS R2,R2,#4				; Increase index by 1
                LDR R3,=ARRAY_SIZE			; Load R3 with ARRAY_SIZE value
                CMP R2,R3					; Check if index has reached to the end of the memory
                BEQ lltar_branch			; Branch to lltar_branch
                B lltar_loop				; goto lltar_loop

lltar_branch    LDR R1,=ALLOCATED_AREA		; Load R1 with ALLOCATED_AREA value
				LDR R1,[R1]
                MOVS R0,#5					; Write error code 5 to r0
                CMP R1,#0					; Check if Linked List is empty
                BEQ lltar_return			; Return

                MOVS R3,#0					; Index of ARRAY_MEM
                LDR R5,=FIRST_ELEMENT		; Load R5 with FIRST_ELEMENT address
				LDR R5,[R5]
                LDR R2,=ARRAY_MEM			; Load R2 with ARRAY_MEM address

lltar_loop2     LDR R1,[R5]					; Load data from link list
                STR R1,[R2]					; Write data to array
                ADDS R2,R2,#4				; Increase array index by 1
                ADDS R5,R5,#4 				; Set R5 to address word
                LDR R4,[R5]					; Load R4 with the value at R5
                MOVS R0,#0					; Set error value to 0 (no errors)
                CMP R4,#0					; Check if linked list has reached to the end node
                BEQ lltar_return			; Return
                MOVS R5,R4					; Load r5 with the next node's address
                B lltar_loop2				; goto lltar_loop2
lltar_return
                BX LR						; Return


;//-------- <<< USER CODE END Linked List To Array >>> ------------------------				
				ENDFUNC
				
;*******************************************************************************				

;@brief 	This function will be used to write errors to the error log array.
;@param		R0 -> Index of Input Dataset Array
;@param     R1 -> Error Code 
;@param     R2 -> Operation (Insertion / Deletion / LinkedList2Array)
;@param     R3 -> Data
WriteErrorLog	FUNCTION			
;//-------- <<< USER CODE BEGIN Write Error Log >>> ----------------------															
				
				LDR R6,=LOG_MEM                ; R6 <- LOG_MEM
                LDR R4,=INDEX_ERROR_LOG        ; Load R4 with INDEX_ERROR_LOG value
				LDR R4,[R4]
                LDR R5,=LOG_ARRAY_SIZE         ; Load R5 with LOG_ARRAY_SIZE value
                CMP R4,R5                      ; Check if Log Area is full
                BEQ wrerrlog_return            ; Return

                LSLS R1,#8                     ; Left shift R1 by 8 bits
                LSLS R0,#16                    ; Left shift R0 by 16 bits
                ADDS R0,R0,R1                  ; Add R0 and R1
                ADDS R0,R0,R2                  ; Add R0 and R2

                STR R0,[R6,R4]                 ; Write Index, ErrorCode and Operation to Error Log 

				LDR R4,=INDEX_ERROR_LOG		   ; Load R4 with INDEX_ERROR_LOG address
                LDR R5,[R4]                    ; Write the value to R5 at INDEX_ERROR_LOG
                ADDS R5,R5,#4                  ; Index += 4
                STR R5,[R4]                    ; Update INDEX_ERROR_LOG

				LDR R4,[R4]					   ; R4 <- INDEX_ERROR_LOG value
                STR R3,[R6,R4]                 ; Write Data to Error Log 

                LDR R4,=INDEX_ERROR_LOG		   ; Load R4 with INDEX_ERROR_LOG address
                LDR R5,[R4]                    ; Write the value to R5 at INDEX_ERROR_LOG
                ADDS R5,R5,#4                  ; Index += 4
                STR R5,[R4]                    ; Update INDEX_ERROR_LOG

				PUSH{LR}
                BL GetNow                      ; Call GetNow function
                LDR R4,[R4]					   ; R4 <- INDEX_ERROR_LOG value			
				STR R0,[R6,R4]                 ; Write current time to Error Log 

                
				LDR R4,=INDEX_ERROR_LOG		   ; Load R4 with INDEX_ERROR_LOG address
                LDR R5,[R4]                    ; Write the value to R5 at INDEX_ERROR_LOG
                ADDS R5,R5,#4                  ; Log Area Size += 4
                STR R5,[R4]                    ; Update INDEX_ERROR_LOG

wrerrlog_return 
				POP{PC}                        ; Return



;//-------- <<< USER CODE END Write Error Log >>> ------------------------				
				ENDFUNC
				
;@brief 	This function will be used to get working time of the System Tick timer
;@return	R0 <- Working time of the System Tick Timer (in us).			
GetNow			FUNCTION			
;//-------- <<< USER CODE BEGIN Get Now >>> ----------------------															
				LDR R1, =0xE000E018          ; Load Current Value Adress to R1
                LDR R1,[R1]                  ;
                LDR R2, =TICK_COUNT
                LDR R2,[R2]                  ; Load Tick Count to R2
                MOVS R3, #3                  ; R3 <- 3
                MULS R1,R3,R1                ; Times past after the last interrupt
                LDR R3,=0x3E6                ; R3 <- 998 (1 interrupt time)
                MULS R2,R3,R2                ; R2 <- Tick count * 1 interrupt time
                ADDS R2,R2,R3                ; R2 <- Total Time passed in microseconds
                MOVS R0,R2                   ; Return from R0
                BX LR                        ; Return
;//-------- <<< USER CODE END Get Now >>> ------------------------
				ENDFUNC
				
;*******************************************************************************	

;//-------- <<< USER CODE BEGIN Functions >>> ----------------------															


;//-------- <<< USER CODE END Functions >>> ------------------------

;*******************************************************************************
;@endsection 		USER_FUNCTIONS
;*******************************************************************************
				ALIGN
				END		; Finish the assembly file
				
;*******************************************************************************
;@endfile 			main.s
;*******************************************************************************				


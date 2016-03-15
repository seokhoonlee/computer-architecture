;>>> Please note that syntax highlighting might not work properly for some keywords - one of the many bugs in ARM/Keil assembler.
;>>> Make sure you do a 'Rebuild All' before you start a debug session () every time you make some changes in code.
;>>> Also note that you do a CPU reset in the simulator, the RAM (memory storing variables) in the simulator might not get reset.
	AREA    MYCODE, CODE, READONLY, ALIGN=9 
		ENTRY
	  
; ------- <code memory (ROM mapped to Instruction Memory) begins>
; Total number of instructions should not exceed 128
		;LDR  R5, variable1_addr ;//does the same as LDR  R5, =variable1 //For illustration only. Can be removed
		;LDR  R5, variable1 //For illustration only. Can be removed
		LDR	 R12, DIPS  	; load address of DIP switches. DO NOT use pseudo-instructions
		LDR  R11, LEDS  	; load address of LEDs
		LDR  R10, UART  	; load address of UART
		LDR  R0, ZERO
		LDR  R1, DELAY_VAL
DELAY
		SUBS R1, #1
		BNE  DELAY			; A simple delay loop. Load R5 with a delay value appropriate for the delay you need and CLK_DIV_BITS used.
;MUL/DIV TEST
		LDR  R2, ONE
		LDR  R3, ZERO
		MUL  R4, R2, R3
		LDR  R2, TWO
		LDR  R3, TWO
		MUL  R4, R2, R3
		LDR  R2, FOUR
		LDR  R3, TWO
		MLA  R4, R2, R3, R0 ; Last operand set to R0 to fulfill SBZ condition for distinguisher
		LDR  R2, TWO
		LDR  R3, TWO
		MLA  R4, R2, R3, R0 ; Last operand set to R0 to fulfill SBZ condition for distinguisher
;Rotated Immediate Test
		LDR  R2, ONE
		LDR  R3, FOUR
		ADD  R2, R3, ROR #31
		LDR  R2, ONE
		LDR  R3, FOUR
		ADD  R2, R3, ROR #1
		LDR  R2, ONE
		LDR  R3, FOUR
		ADD  R2, R3, ROR #3	;Should not set carry flag
		LDR  R2, ONE
		LDR  R3, FOUR
		ADDS  R2, R3, ROR #3	;Should not set carry flag (only 31st bit, not 32nd)
		MOVS  R2, #16		;Should unset carry flag
		MOVS  R2, R2, ROR #5	;Should set carry flag
		MOVS  R2, #16		;Should unset carry flag
;DP TEST
		LDR  R2, ONE
		LDR  R3, ZERO
		AND  R2, R3
		LDR  R2, ONE
		LDR  R3, ONE
		EOR  R2, R3
		LDR  R2, TWO
		LDR  R3, ONE
		SUB  R2, R3
		LDR  R2, TWO
		LDR  R3, ONE
		RSB  R2, R3			; result = INT_MAX and carry
		LDR  R2, INT_MAX
		LDR  R3, ONE
		ADDS  R2, R3			; result = 0 & there will be carry
		LDR  R2, INT_MAX
		LDR  R3, ONE
		ADC  R2, R3			; result == 1 with carry (DONE)
		LDR  R2, TWO
		LDR  R3, ONE
		SBC  R2, R3			; result == 1 since carry = 1 (DONE)
		LDR  R2, ONE
		LDR  R3, TWO
		RSC  R2, R3			; result == 1 (DONE)
		LDR  R2, ONE
		LDR  R3, ONE
		TST  R2, R3			; result == 1
		LDR  R2, ONE
		LDR  R3, ONE
		TEQ  R2, R3			; result == 0
		LDR  R2, TWO
		LDR  R3, ONE
		CMP  R2, R3			; result == 1
		LDR  R2, TWO
		LDR  R3, NEGONE
		CMN  R2, R3			; result == 1
		LDR  R2, ONE
		LDR  R3, ZERO
		ORR  R2, R3			; result == 1
		MOV  R2, #8			; R2 == 8
		LDR  R2, ONE
		LDR  R3, NEGONE
		BIC  R2, R3			; result == 1
		MVN  R2, #-1		; R2 == 0 (DONNNNNNNNNNNNE)
LOOP	LDR  R1, [R12]  	; Read DIP switches
		STR  R1, [R11]		; Display on LEDs
		STR  R1, [R10]		; Display on Console
;		LDR  R1, [R10]  	; Read from Console
;		STR  R1, [R11]		; Display on LEDs
;		STR  R1, [R10]		; Display on Console
		B    LOOP
;halt	
;		B    halt           ; Infinite loop to halt computation. A program should not "terminate" without an operating system to return control to
; ------- <\code memory (ROM mapped to Instruction Memory) ends>


	AREA    CONSTANTS, DATA, READONLY, ALIGN=9 
; ------- <constant memory (ROM mapped to Data Memory) begins>
; Total number of constants (including those inferred by pseudo-instructions) should not exceed 124 (128, 4 are used for peripheral pointers)
; If a variable is accessed multiple times, it is better to store the address in a register and use it rather than to access it using pseudo-instructions
LEDS
		DCD 0x00000C00		; Address of LEDs. Use 0x00000800 while simulating in Keil and change back before compiling for VHDL
DIPS
		DCD 0x00000C04		; Address of DIP switches. Use 0x00000804 while simulating in Keil and change back before compiling for VHDL
PBS
		DCD 0x00000C08		; Address of Push Buttons. Use 0x00000808 while simulating in Keil and change back before compiling for VHDL
UART
		DCD 0x00000C0C		; Address of UART. Use 0x0000080C while simulating in Keil and change back before compiling for VHDL

ONE
		DCD 0x00000001		
TWO
		DCD 0x00000002
FOUR
		DCD 0x00000004
NEGONE
		DCD 0xFFFFFFFF		
INT_MAX
		DCD 0xFFFFFFFF

; All constants should be declared below.
ZERO
		DCD 0x00000000		; Constant zero. Load this to reset a register
DELAY_VAL
		DCD	0x00000004		; DELAY_VAL = 2^(CLK_DIV_BITS-1) to get a delay of the order of 1s (delays 2 cycles for each increment of DELAY_VAL)
;variable1_addr
;		DCD variable1		; address of variable1. Need to do it this way since we are avoiding pseudo-instructions. //For illustration only. Can be removed
;constant1
;		DCD 0xABCD1234		; const int constant1 = 0xABCD1234; //For illustration only. Can be removed
string1_ptr
		DCD	string1
string1   
		DCB  "Hello World!!!!",0	; char string1[] = "Hello World!"; // Assembler will issue a warning if the string size is not a multiple of 4, but the warning is safe to ignore
		
; ------- <constant memory (ROM mapped to Data Memory) ends>	


	AREA   VARIABLES, DATA, READWRITE, ALIGN=9
; ------- <variable memory (RAM mapped to Data Memory) begins>
; All variables should be declared here. 
; No initialization possible in this region. In other words, you should write to a location before you can read from it.
; Note : Reuse variables / memory if your total RAM usage exceeds 128
		
; Rest of the variables
;variable1	; 0x0000080C for simulation
;		DCD 0x00000000		;  int variable1; //For illustration only. Can be removed

; ------- <variable memory (RAM mapped to Data Memory) ends>
		END
		
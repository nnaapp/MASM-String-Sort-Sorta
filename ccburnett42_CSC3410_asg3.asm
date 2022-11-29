.586
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD

.data
s1 DB 'aaaaaa', 0
s2 DB 'cccccc', 0
s3 DB 'bbbbbb', 0
s4 DB 'zzzzz', 0
s5 DB 'ddddd', 0
s6 DB 'ssssss', 0
s7 DB 'ttttttttt', 0
s8 DB 'eeeee', 0
string_array DD s1, s2, s3, s4, s5, s6, s7, s8
array_size DWORD 0
stringorder DWORD 0

.code

; eax : al for outer loop string, ah for inner loop string
; ebx : scratch register, use for anything, overwrite is okay
; ecx : cl for shift, ch for outer string count
; edx : scratch register, use for anything, overwrite is okay
; esi : alphabetically first output from proc
; edi : alphabeticallt second output from proc, overwritten with address of outer loop string
;       for comparison purposes, as the second string is not needed

pushs_off MACRO off                     ; push string to stack with offset arg, typically al/ah here
    MOVZX     ebx, off
	ADD       ebx, esi
	MOV       ebx, [ebx]                ; this is due to the array of strings, must "follow the pointers"
	PUSH      ebx
ENDM

main PROC ; This will work with up to 8 strings, in order to do more you would need a better way or a 64 bit system
    XOR       eax, eax
    MOV       al, -4                    ; array index offset
    MOV       ecx, LENGTHOF string_array; this is for loop count
    LEA       esi, string_array
    _pre_loop:                          ; pre-processing loop for converting every string to uppercase
    CMP       ecx, 0                    ; this is done before to eliminate repeated work in the sort algorithm
    JLE       _end_pre

    ADD       al, 4
    pushs_off al                        ; pushs string from array with al as index offset
    CALL      toUpper

    DEC       ecx                       ; dec and loop until done
    JMP       _pre_loop

    _end_pre:



	XOR       eax, eax
	MOV       al, -4                    ;-4 because initial loop will add 4, making start 0

	_sort_loop:
	ADD       al, 4
	MOV       ah, 0
	XOR       ecx, ecx

	_inner_loop:
	CMP       ah, SIZEOF string_array
	JGE       _end_loop

	PUSH      eax                       ; save counters
	PUSH      ecx

	LEA       esi, string_array

    pushs_off al                        ; push outer string
    pushs_off ah                        ; push inner string
	CALL      a_cmpsb                   ; proc, esi = alphabetically first, edi = alphabetically second
	POP       ecx                       ; restore counters after proc call
	POP       eax

	MOVZX     edi, al                   ; overwrite edi (not needed) with reference to outer loop string
	LEA       ebx, string_array
	ADD       edi, ebx
	MOV       edi, [edi]

	CMP       edi, esi                  ; if outer loop string was the alphabetically first one, inc, otherwise do not
	JNE       _lesser

	INC       ch                        ; inc count, inc inner loop
	ADD       ah, 4
	JMP       _inner_loop

	_lesser:

	ADD       ah, 4                     ; or just inc inner loop
	JMP       _inner_loop

	_end_loop:

	MOVZX     ebx, al                   ; get outer loop index (in multiple of 4)
	MOV       cl, 2
	SHR       ebx, cl                   ; divide by 4 for true index
	INC       ebx                       ; inc for 1-indexed index

	DEC       ch                        ; dec count due to strings self-comparing
	MOV       cl, 4                     ; binary left shift of 4 moves hex digit left one space

	_shift_loop:                        ; shift index in ebx left an amount of times equal to the alphabetically-first count - 1
	CMP       ch, 0                     ; ch contains amount of shifts
	JLE       _end_shift_loop

	SHL       ebx, cl
	DEC       ch
	JMP       _shift_loop
	_end_shift_loop:

	OR        stringorder, ebx          ; add that shifted output onto the output number with OR

	CMP       al, SIZEOF string_array - 4
	JGE       _end
	JMP       _sort_loop                ; loop or end

	_end:
	
	XOR       eax, eax
	MOV       eax, stringorder

    	INVOKE	ExitProcess, 0
main ENDP

a_cmpsb PROC                            ; takes two string addresses as input, outputs alphabetically first string in esi, second in edi
	PUSH      ebp                       ; establish stack frame
	MOV       ebp, esp

	MOV       esi, [ebp + 12]           ; first string
	MOV       edi, [ebp + 8]            ; second string
	PUSH      esi
	PUSH      edi

	PUSH      esi                       ; getting string length for REPE loop below
	CALL      strlen                    ; get length of first string in ecx
	MOV       ecx, ebx

	PUSH      edi
	CALL      strlen                    ; get length of second string in ebx

	CMP       ecx, ebx
	JGE       _first_greater

	MOV       ecx, ebx                  ; swap ebx into ecx if the second string is greater in length

	_first_greater:

	CLD                                 ; CLD to ensure it increments forward
	REPE      CMPSB                     ; compare ecx times, or until different
	JBE     _less_equal                 ; if it makes it to the end, they are equal

	POP       esi                       ; first string in first out
	POP       edi                       ; second string in second out
	JMP       _end

	_less_equal:
	POP       edi                       ; second string in first out
	POP       esi                       ; first string in second out

	_end:

	POP       ebp                       ; restore stack
	RET       8
a_cmpsb ENDP

strlen PROC	                            ; takes string address as input, preserves esi, and outputs string length in ebx
	PUSH      ebp                       ; establish stack frame
	MOV       ebp, esp
	PUSH      esi                       ; preserve esi
	MOV       esi, [ebp + 8]            ; get string ptr in esi

	_loop:                              ; iterate over string, incrementing address 1 byte each time
	INC       esi
	CMP       BYTE PTR [esi], 0         ; if char is equal to 0, null terminator, string over
	JNE       _loop
	
	SUB       esi, [ebp + 8]            ; subtract string start address from current esi address for string size
	MOV       ebx, esi                  ; put in ebx for output
	POP       esi
	POP       ebp                       ; restore stack
	RET       4
strlen ENDP

toUpper PROC                            ; takes string address as input, turns each char to uppercase if lowercase, this is by reference
    PUSH      ebp                       ; WILL EXHIBIT UNEXPECTED BEHAVIOR IF GIVIEN NON-ALPHABETICAL CHARACTERS ABOVE 97 DEC ASCII
    MOV       ebp, esp
    PUSH      esi                       ; preserve registers used in this operation
    PUSH      edi
    PUSH      eax
    MOV       esi, [ebp + 8]            ; load string into esi and edi
    MOV       edi, [ebp + 8]

    _loop:                              ; iterates over every character until null terminator
    CMP       BYTE PTR [esi], 0
    JE        _loop_break

    XOR       eax, eax
    LODSB                               ; load current char

    CMP       eax, 97                   ; if less than 97, not lowercase, jump
    JL        _loop_end

    SUB       eax, 32                   ; lowercase char, subtract 32 to convert to uppercase
        
    _loop_end:

    STOSB                               ; store processed char where it came from

    JMP       _loop

    _loop_break:

    POP       eax                       ; restore registers
    POP       edi
    POP       esi
    POP       ebp
    RET       4
toUpper ENDP

END main
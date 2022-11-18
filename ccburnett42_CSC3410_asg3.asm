.586
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD

.data
s1 DB 'abc', 0
s2 DB 'bca', 0
s3 DB 'bac', 0
string_array DD s1, s2, s3
array_index DWORD 0
index_array DW 1, 2, 3
array_size DWORD 0
stringorder WORD 0
tmpcount WORD 0
index WORD 0

.code
shlcl4 MACRO num
	MOV cl, 4
	SHL num, cl
	MOV cx, num
ENDM

main PROC
	XOR eax, eax
	XOR ebx, ebx

	MOV array_size, LENGTHOF string_array

	LEA esi, string_array
	MOV array_index, esi
	MOV esi, [array_index]
	MOV esi, [esi]

	MOV ecx, 0
	_loop:
	CMP array_size, ecx
	JE _end_loop_dep
	INC ecx

	PUSH esi
	CALL strlen

	MOV ebx, [esi]

	ADD array_index, SIZEOF DWORD
	MOV esi, [array_index]
	MOV esi, [esi]
	JMP _loop

	_end_loop_dep:

	LEA ebx, s1
	LEA edx, s2
	PUSH ebx
	PUSH edx
	CALL a_cmpsb

	XOR eax, eax
	MOV al, -4
	_sort_loop:
	MOV tmpcount, 0
	ADD al, 4
	MOV ah, 0

	_inner_loop:
	CMP ah, SIZEOF string_array
	JGE _end_loop

	PUSH eax
	MOVZX ebx, al
	ADD ebx, string_array
	MOVZX edx, ah
	ADD edx, string_array
	PUSH ebx
	PUSH edx
	CALL a_cmpsb
	POP edx
	POP ebx
	POP eax

	CMP ebx, esi
	JNE _lesser

	INC tmpcount
	ADD ah, 4
	JMP _inner_loop

	_lesser:

	ADD ah, 4
	JMP _inner_loop

	_end_loop:

	MOVZX cx, al
	MOV index, cx
	MOV cl, 2
	SHR index, cl
	INC index

	DEC tmpcount
	MOV ch, BYTE PTR[tmpcount]
	MOV cl, 4
	_shift_loop:
	CMP ch, 0
	JLE _end_shift_loop

	SHL index, cl
	DEC ch
	JMP _shift_loop

	_end_shift_loop:

	MOV cx, index
	OR stringorder, cx

	CMP al, SIZEOF string_array - 4
	JGE _end
	JMP _sort_loop

	_end:
	
	XOR eax, eax
	MOVZX eax, stringorder

	INVOKE ExitProcess, 0
main ENDP

strlen PROC ; after ret, EAX contains strlen, ECX contains string ptr from stack
	PUSH ebp
	MOV ebp, esp
	MOV eax, [esp + 8] ; string ptr
	DEC eax

	_loop:
	INC eax
	CMP BYTE PTR [eax], 0
	JNE _loop
	
	SUB eax, [esp]
	POP ebp
	ret 4
strlen ENDP

a_cmpsb PROC ; after ret, ebx contains first string adr, edx contains second string adr, alphabetically
	PUSH ebp
	MOV ebp, esp

	MOV esi, [esp + 12] ; str1
	MOV edi, [esp + 8]  ; str2
	PUSH esi
	PUSH edi

	MOV ecx, 3
	CLD
	REPE CMPSB
	JECXZ _equal

	MOV bl, BYTE PTR [esi - 1]
	MOV dl, BYTE PTR [edi - 1]

	CMP bl, dl
	JL less

	; esi will always contain the alphabetically first string
	; edi will always contain second string
	; alphabetically

	greater:
	POP esi ; first
	POP edi ; second
	JMP _end

	less:
	POP edi ; second
	POP esi ; first
	JMP _end

	_equal:
	POP esi ; order irrelevant, they are equal
	POP edi

	_end:

	POP ebp
	RET
a_cmpsb ENDP

;bubblesort PROC	
;	LOCAL array_addr:DWORD
;	LOCAL len:DWORD
;	LOCAL index:DWORD
;
;	PUSH ebp
;	MOV ebp, esp
;
;	MOV ebx, [esp + 12]; string array
;	MOV array_addr, ebx
;
;	MOV ecx, [esp + 8] ; array length
;	DEC ecx
;	MOV len, ecx
;	DEC ecx
;
;	_outer_loop:
;	MOV index, 0
;	MOV edx, ecx
;
;	_inner_loop:
;	MOV esi, ebx
;	MOV esi, [esi + eax]
;	MOV edi, ebx
;	MOV edi, [edi + eax + SIZEOF DWORD]
;
;	PUSH ecx
;	PUSH edx
;	PUSH esi
;	PUSH edi
;	CALL a_cmpsb
;	POP edx
;	POP ecx
;	
;
;	POP ebp
;	RET 8
;bubblesort ENDP

END main        ;specify the program's entry point
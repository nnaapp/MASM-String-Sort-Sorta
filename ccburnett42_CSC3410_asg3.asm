.586
.model flat, stdcall
.stack 4096

ExitProcess PROTO, dwExitCode:DWORD

.data
s1 DB 'eebus', 0
s2 DB 'beebus', 0
s3 DB 'deebus', 0
s4 DB 'zzzzz', 0
s5 DB 'yyyyy', 0
s6 DB 'ssssss', 0
s7 DB 'ttttttttt', 0
string_array DD s1, s2, s3, s4, s5, s6, s7
array_size DWORD 0
stringorder DWORD 0
tmpcount WORD 0
index DWORD 0

.code
shlcl4 MACRO num
	MOV cl, 4
	SHL num, cl
	MOV cx, num
ENDM

main PROC ; This will work with up to 4 strings, in order to work with more, "index" would need to be a DWORD
	XOR eax, eax
	MOV al, -4

	_sort_loop:
	ADD al, 4
	MOV ah, 0
	MOV tmpcount, 0

	_inner_loop:
	CMP ah, SIZEOF string_array
	JGE _end_loop

	PUSH eax

	MOVZX ebx, al
	MOVZX edx, ah

	LEA eax, string_array

	ADD ebx, eax
	MOV ebx, [ebx]

	ADD edx, eax
	MOV edx, [edx]

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

	MOVZX ecx, al
	MOV index, ecx
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

	MOV ecx, index
	OR stringorder, ecx

	CMP al, SIZEOF string_array - 4
	JGE _end
	JMP _sort_loop

	_end:
	
	XOR eax, eax
	MOV eax, stringorder

	INVOKE ExitProcess, 0
main ENDP

strlen PROC ; after ret, ESI contains string length, KEEP IT TO 255 OR LESS FOR BYTE SIZE! Store offset value in AH
	PUSH ebp
	MOV ebp, esp
	PUSH eax
	MOV esi, [ebp + 12] ; string ptr
	MOV eax, [ebp + 8]  ; offset
	AND eax, 00000000000000001111111100000000b
	SHR eax, 8
	ADD esi, eax
	DEC esi

	_loop:
	INC esi
	CMP BYTE PTR [esi], 0
	JNE _loop
	
	SUB esi, [esp]
	POP eax
	POP ebp
	ret 8
strlen ENDP

a_cmpsb PROC ; after ret, ebx contains first string adr, edx contains second string adr, alphabetically
	PUSH ebp
	MOV ebp, esp

	MOV esi, [ebp + 12] ; str1
	MOV edi, [ebp + 8]  ; str2
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

END main        ;specify the program's entry point
   ; Registradores : R1-0 , R2=1 , R3=2 , R4=3   16 BITS     , ;segmento codigo 64k , seg pilha 64k 
;   CODIGO       INST
;   00 xx          PUSH   reg       SE X={0,1,2,3}
;   01 xx xx       PUSHc   Const   de 16 bits 
;   02 xx  POP     pop  reg   
;   03  add                          
;   04 sub 
;   05  and 
;   06 or
;   07 xor 
;   08 not 
;   09 bbbb  jmp end 
;   0A bbbb  jz end   , flag zero==1
;   0B bbbb  jnz end  , flag zero<> 1
;   0C bbbb  jl  end  , flag negativo=1
;   0D hlt 
global  codigo
global  regs
global executa   
segment  .data
codigo:times 65536 db 0 
pilha :times 65536 db 0 
FIM_PILHA equ $
regs: times 4 dw 00
 
negativo: db 0 
zero:db 0
;----
; executa a partir do zero.
desvios: dq  $PUSH_OP,$PUSHC_OP,$POP_OP,$ADD_OP,$SUB_OP,$AND_OP,$OR_OP,$XOR_OP,$NOT_OP, $JMP_OP,$JZ_OP,$JNZ_OP,$JL_OP,$HLT_OP 
 
segment .text
    executa: 
          mov rsi, codigo      ; funciona com IP
          mov rdi, $FIM_PILHA  ; funciona com SP
          mov r15, regs       ; r15 aponta para regs
    eterno:
          xor rdx,rdx
          mov dl, byte [rsi]
          cmp dl,0eh   ; instrucao valida < 0xe
          jl execx
          ; invalid instruct
          ; print error return
          ret
     execx:
         jmp qword  [desvios+rdx*8]
;-------------------------------------------------
;------
PUSH_OP:
POP_OP:
; rsi ip / rdi rsp / a instrucao pode ser 
; push r1|r2|r3|r4 com dois bytes 00 e o seg 00,01,02,03
; descubro qual o reg, pego valor e guardo na pilha ou tiro da pilha
   ; pega o dois operandos
   xor rax,rax
   mov al,byte [rsi+1]; codigo reg
   ; para calcular o registrador devo multiplicar por 2 e somar a regs,tenho o ponteiro
   add rax,rax
   ; pego o endereco e coloco em rax  regs esta em r15
   add rax,r15 
   cmp dl,0
     jne tpop
     ;push rax aponta para reg valor
     mov bx,word[rax]
     sub rdi,2  ; espaco na pilha
     mov word[rdi], bx
     add rsi,2 
     jmp eterno
tpop:
     mov bx,word [rdi]
     add  rdi,2
     mov word [rax],bx
     add rsi,2 
     jmp eterno
;-------------------------------------------
;01  PUSHc bb bb coloca word [rsi+1] no topo da pilha
PUSHC_OP:
    mov ax, word [rsi+1]
    ; A Constante esta com parte alta baixa invertida  
    ; se tenho 01FF  deveria estar escrito FF01 
    ; troca orderm 2 bytes
    rol ax,8
    ;
    sub rdi,2 
    mov word [rdi],ax
    add rsi,3
    jmp eterno
    
; 03  add ,  04  sub , 05  and , 06 , 07  xor          
;  operacao com os valores de 16 bits no topo da pilha  sp=rdi, ip=rsi e dl tem o condigo, r15 tem regs
ADD_OP:
SUB_OP:
AND_OP:
OR_OP:
XOR_OP:
   ; pega o dois operandos
     mov r8w,word [rdi]
     add rdi,2
     mov r9w,word[rdi] 
     cmp dl,3
     jne tsub
     add r8w,r9w
     jmp flag1sai
tsub:cmp dl,4
     jne tand
     sub r8w,r9w
     jmp flag1sai
tand:cmp dl,5
     jne tor
     and r8w,r9w
     jmp flag1sai
tor:cmp dl,6
     jne txor
     or r8w,r9w
     jmp flag1sai
txor: xor r8w,r9w
flag1sai:
     mov word [rdi], r8w
     ; seta flags 
     call flags
     ;-ajusta ip
     inc rsi
     jmp eterno
;--------------------------------------
NOT_OP:
   ; pega o  operando
   xor rax,rax
   mov al,byte [rsi+1]; codigo reg
   ; para calcular o registrador devo multiplicar por 2 e somar a regs,tenho o ponteiro
   add rax,rax
   ; pego o endereco e coloco em rax  regs esta em r15
   add rax,r15 
   not  r8w 
   mov word [r15+rax],r8w
   call flags
   inc rsi
   jmp eterno
;------------------------------------------
; em rsi+1 temos a word com o endereco que vai para rsi
;   09 bbbb  jmp end 
;   0A bbbb  jz end   , flag zero==1
;   0B bbbb  jnz end  , flag zero<> 1
;   0C bbbb  jl  end  , flag negativo=1
JZ_OP:
    mov al,byte [zero]
    cmp al,1
    je JMP_OP
 nao_desvia:
    add rsi, 3
    jmp eterno
JNZ_OP:
    mov al,byte [zero]
    cmp al,0
    je JMP_OP
    jmp nao_desvia
JL_OP:
    
    mov al,byte [negativo]
    cmp al,1
    jne nao_desvia
JMP_OP: ; sempre faz
   xor rax,rax
   mov ax,word [rsi+1]
   ;
   ;little endian
   rol ax,8
   ; incondicional ax tem o ajuste dentro do vetor, preciso ajustar
   mov rbx,codigo
   add rbx,rax ; - ponteiro para dentro do vetor codigo em rbx 
   mov rsi,rbx
   jmp eterno

;-------------------------
HLT_OP: 
      ret
;---------------------------------------
;seta flag zero e negativo
flags:
     mov al,0
     jnz setazero
     mov al,1
setazero:
     mov byte [zero],al
     mov al,0
     jge setaneg
     mov al,1
setaneg:
     mov byte [negativo],al  
     ret 

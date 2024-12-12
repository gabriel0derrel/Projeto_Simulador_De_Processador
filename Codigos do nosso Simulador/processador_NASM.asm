; ----------------------- GRUPO ---------------------------------
; Gabriel Derrel Martins Santee
; Guilherme Ponciano Silva
; Lucas Pereira Nunes
; Ronaldo Oliveira de Jesus

; --------- Legenda dos Registradores Utilizados ----------
; RSI -> Aponta para o byte atual na memória (Inalterado)
; RDI -> Aponta para o topo da pilha (Inalterado)
; r15 -> Aponta para o início do vetor de registradores (Inalterado)
; r8 -> Utilizado para chamar a função obter_tamanho_registrador
; r9 -> Aponta para um registrador do vetor de registradores
; r10 -> Aponta para uma posição de memória ou um outro registrador do vetor de registradores


global  memoria
global  regs
global executar
extern negativo, zero, carry
extern getchar
extern printf
segment  .data
     memoria:times 65536 db 0 
     FIM_PILHA equ $ ; aponta para o fim da memoria
     regs: times 8 dd 0000

     invalido_msg: db "Instrução Inválida",0ah
     out_fmt: db "%c",10,0 ; Formatação para o printf -> "%c\n\0"
     
     ; Flags
     negativo: db 0 
     zero:db 0
     carry:db 0
     
     ;----
     ; executa a partir do zero
     desvios: dq  $PUSH_OP,$POP_OP,$LOADC_OP,$LOAD_END_OP,$LOAD_RX_OP,$STORE_END_OP,$STORE_RX_OP,$HALT_OP,$ADD_OP,$SUB_OP,$AND_OP,$OR_OP,$XOR_OP,$NOT_OP,$CMP_OP,$JMP_OP,$JL_OP,$JG_OP,$JLE_OP,$JGE_OP,$JC_OP,$JNC_OP,$IN_OP,$OUT_OP
 
segment .text
    executar: 
          mov rsi, memoria      ; funciona com IP(Ponteiro para a instrucao)
          mov rdi, $FIM_PILHA  ; funciona com SP(Ponteiro para o topo da pilha)
          mov r15, regs       ; r15 aponta para os registradores
    eterno:
          xor rdx,rdx ; limpa rdx
          mov dl, byte [rsi] ; pega o byte da instrucao
          cmp dl, 18h   ; instrucao valida < 0x18
          jl execx
          ret
     execx:
         jmp qword  [desvios+rdx*8]
;-------------------------------------------------

obter_tamanho_registrador:
    tamanho_16_bits:
    cmp r8, qword 1
    ja tamanho_8_bits
    mov r8, qword 16
    ret
    tamanho_8_bits:
    cmp r8, qword 5
    ja tamanho_32_bits
    mov r8, qword 8
    ret
    tamanho_32_bits:
    cmp r8, qword 7
    ja invalid_instruction
    mov r8, qword 32
    ret

invalid_instruction:
     mov rax, 4
     mov rbx, 1
     mov rcx, invalido_msg
     mov rdx, 21
     int 0x80
     ret

flags:
     mov al,0
     jnz .setazero ; Se não tiver dado 0, pula direto para a parte onde al é armazenado na variável zero, ignorando a atribuição al=1
     mov al,1 ; Se tiver dado 0, al agora vale 1, assim agora zero receberá 1
.setazero:
     mov byte [zero],al
     mov al,0
     jge .setaneg ; Se não tiver dado negativo, pula direto para a parte onde al é armazenado na variável negativo, ignorando a atribuição al=1
     mov al,1 ; Se tiver dado negativo, al agora vale 1, assim agora negativo receberá 1
.setaneg:
     mov byte [negativo],al  
     mov al, 0
     jnc .setacarry ; Se não haver carry, pula direto para a parte onde al é armazenado na variável carry, ignorando a atribuição al=1
     mov al, 1 ; Se houver carry, al agora vale 1, assim agora carry receberá 1
.setacarry:
     mov byte [carry], al
     ret

; -------------------
; PUSH R - Código 00
; 00 20 -> PUSH D0
PUSH_OP:
     inc rsi ; avança para pegar o byte do registrador
     xor r9, r9
     xor r8, r8 ; limpa r8
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     mov al, byte [rsi] ; pega o byte do registrador
     shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     lea r9, [r15+rax*4] ; calcula o endereço do registrador
     inc rsi ; avança para o rsi apontar para a proxima instrucao
     cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
     je PUSH_8_bits
     cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
     je PUSH_32_bits

     PUSH_16_bits: ; se não é um dos dois, então é de 16 bits
          mov bx, word [r9] ; pega 2 bytes seguidos da pilha
          sub rdi, 2
          mov word [rdi], bx
          jmp eterno ; sai da função

     PUSH_8_bits:
          mov bl, byte [r9] ; pega 1 byte da pilha
          sub rdi, 1
          mov byte [rdi], bl
          jmp eterno ; sai da função

     PUSH_32_bits:
          mov ebx, dword [r9] ; pega 4 bytes seguidos da pilha
          sub rdi, 4
          mov dword [rdi], ebx
          jmp eterno ; sai da função

; -------------------
; POP R - Código 01
; 01 60 -> POP H0
POP_OP:
     inc rsi ; avança para pegar o byte do registrador
     xor r9, r9
     xor r8, r8 ; limpa r8
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     mov al, byte [rsi] ; pega o byte do registrador
     shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     lea r9, [r15+rax*4] ; calcula o endereço do registrador
     inc rsi ; avança para o rsi apontar para a proxima instrucao
     cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
     je POP_8_bits
     cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
     je POP_32_bits

     POP_16_bits: ; se não é um dos dois, então é de 16 bits
          mov bx, word [rdi] ; pega 2 bytes seguidos da pilha
          add rdi, 2
          mov word [r9], bx
          jmp eterno ; sai da função

     POP_8_bits:
          mov bl, byte [rdi] ; pega 1 byte da pilha
          add rdi, 1
          mov byte [r9], bl
          jmp eterno ; sai da função

     POP_32_bits:
          mov ebx, dword [rdi] ; pega 4 bytes seguidos da pilha
          add rdi, 4
          mov dword [r9], ebx
          jmp eterno ; sai da função
          
; -----------------------------------
; LOAD R, Const(xx ou xx xx ou xx xx xx xx) - Código 02
; 02 10 1A 00 -> LOAD A1, 001A
; 02 30 0A -> LOAD D1, 0A
; 02 70 0B 00 0A 01 -> LOAD H1, 010A000B
LOADC_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r9, r9
     xor r8, r8 ; limpa r8
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     mov al, byte [rsi] ; pega o byte do registrador
     shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     lea r9, [r15+rax*4] ; calcula o endereço do registrador
     inc rsi ; avança o ponteiro de instruções para pegar a constante a ser armazenada
     cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
     je LOADC_8_bits
     cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
     je LOADC_32_bits

     LOADC_16_bits: ; se não é um dos dois, então é de 16 bits
          mov bx, word [rsi] ; pega 2 bytes seguidos da memoria
          mov word [r9], bx
          add rsi, 2 ; avança 2 bytes
          jmp eterno ; sai da função

     LOADC_8_bits:
          mov bl, byte [rsi] ; pega 1 byte da memoria
          mov byte [r9], bl
          add rsi, 1 ; avança 1 byte
          jmp eterno ; sai da função

     LOADC_32_bits:
          mov ebx, dword [rsi] ; pega 4 bytes seguidos da memoria
          mov dword [r9], ebx
          add rsi, 4 ; avança 4 bytes
          jmp eterno ; sai da função

; -----------------------------
; LOAD R, [xx xx] - Código 03
; 03 40 1A 00 -> LOAD D2, [001A]
LOAD_END_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9, r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     mov al, byte [rsi] ; pega o byte do registrador
     shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     lea r9, [r15+rax*4] ; calcula o endereço do registrador
     inc rsi ; avança o ponteiro de instruções
     mov r10w, word [rsi] ; pega 2 bytes seguidos da memoria
     lea r10, [memoria+r10] ; calcula o endereço da memoria apontado pelos 2 bytes pegos
     add rsi, 2 ; avança 2 bytes

     cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
     je LOAD_END_8_bits
     cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
     je LOAD_END_32_bits

     LOAD_END_16_bits:
          mov bx, word [r10] ; pega 2 bytes seguidos da memoria a partir do endereço calculado(r10)
          mov word [r9], bx
          jmp eterno ; sai da função

     LOAD_END_8_bits:
          mov bl, byte [r10] ; pega 1 byte da memoria a partir do endereço calculado(r10)
          mov byte [r9], bl
          jmp eterno ; sai da função

     LOAD_END_32_bits:
          mov ebx, dword [r10] ; pega 4 bytes seguidos da memoria a partir do endereço calculado(r10)
          mov dword [r9], ebx
          jmp eterno ; sai da função

; ----------------------------
; LOAD R, [Rx] (Rx = A0 ou A1)- Código 04
; 04 21 -> LOAD D0, A1
LOAD_RX_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9, r9
     xor r10, r10 ; limpa r10
     xor r11, r11 ; limpa r11
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador(o qual está na parte baixa)
     mov r8, rcx ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     cmp r8, qword 16
     jne invalid_instruction

     LOAD_validado:
          mov al, byte [rsi] ; pega o byte do registrador
          shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
          mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
          call obter_tamanho_registrador

          ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
          lea r9, [r15+rax*4] ; calcula o endereço do registrador
          lea r10, [r15+rcx*4] ; calcula o endereço do registrador que possui o endereço de memória guardado
          mov r11, [r10] ; obtem o endereço salvo no registrador
          lea r10, [memoria+r11] ; calcula o endereço na memória apontado pelo endereço salvo no registrador
          inc rsi
          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je LOAD_RX_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je LOAD_RX_32_bits

          LOAD_RX_16_bits:
               mov bx, word [r10] ; pega 2 bytes seguidos da memoria a partir do endereço calculado(r10)
               mov word [r9], bx
               jmp eterno ; sai da função

          LOAD_RX_8_bits:
               mov bl, byte [r10] ; pega 1 byte da memoria a partir do endereço calculado(r10)
               mov byte [r9], bl
               jmp eterno ; sai da função

          LOAD_RX_32_bits:
               mov ebx, dword [r10] ; pega 4 bytes seguidos da memoria a partir do endereço calculado(r10)
               mov dword [r9], ebx
               jmp eterno ; sai da função

; -------------------------------
; STORE [xx xx], R Código 05
; 05 1A 01 20 -> STORE [011A], D0
STORE_END_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9, r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx

     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     mov r10w, word [rsi] ; pega 2 bytes seguidos da memoria
     lea r10, [memoria+r10] ; calcula o endereço da memoria apontado pelos 2 bytes pegos

     add rsi, 2
     mov al, byte [rsi] ; pega o byte do registrador
     shr al, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     lea r9, [r15+rax*4] ; calcula o endereço do registrador
     inc rsi
     
     cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
     je STORE_END_8_bits
     cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
     je STORE_END_32_bits

     STORE_END_16_bits:
          mov bx, word [r9] ; pega o valor do registrador apontado por r9
          mov word [r10], bx ; Move o valor para a posição na memória apontada por r10
          jmp eterno ; sai da função

     STORE_END_8_bits:
          mov bl, byte [r9] ; pega o valor do registrador apontado por r9
          mov byte [r10], bl ; Move o valor para a posição na memória apontada por r10
          jmp eterno ; sai da função

     STORE_END_32_bits:
          mov ebx, dword [r9] ; pega o valor do registrador apontado por r9
          mov dword [r10], ebx ; Move o valor para a posição na memória apontada por r10
          jmp eterno ; sai da função

; --------------------------------
; STORE [Rx], R (Rx = A0 ou A1)- Código 06
; 06 16 -> STORE A1, H0
STORE_RX_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor r11, r11 ; limpa r11
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov cl, byte [rsi]
     shr cl, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rcx ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     cmp r8, qword 16
     jne invalid_instruction

     STORE_validado:

          mov al, byte [rsi] ; pega o byte do registrador
          and al, 0fh ; pega o código do segundo registrador
          mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
          call obter_tamanho_registrador

          ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
          lea r9, [regs+rax*4] ; calcula o endereço do registrador
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador que possui o endereço de memória guardado
          mov r11w, word [r10] ; obtem o endereço salvo no registrador
          lea r10, [memoria+r11] ; calcula o endereço na memória apontado pelo endereço salvo no registrador
          inc rsi
          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je STORE_RX_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je STORE_RX_32_bits

          STORE_RX_16_bits:
               mov bx, word [r9] ; pega o valor do registrador apontado por r9
               mov word [r10], bx ; Move o valor para a posição na memória apontada por r10
               jmp eterno ; sai da função

          STORE_RX_8_bits:
               mov bl, byte [r9] ; pega o valor do registrador apontado por r9
               mov byte [r10], bl ; Move o valor para a posição na memória apontada por r10
               jmp eterno ; sai da função

          STORE_RX_32_bits:
               mov ebx, dword [r9] ; pega o valor do registrador apontado por r9
               mov dword [r10], ebx ; Move o valor para a posição na memória apontada por r10
               jmp eterno ; sai da função

; -----------------------------
; HALT - Código 07
; 07 -> HALT
HALT_OP:
     ret

; -----------------------------
; ADD R1, R2 (tam de R1 == tam de R2) - Código 08
; 08 23 -> ADD D0, D1
; R1 = R1 + R2
ADD_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     ADD_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je ADD_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je ADD_32_bits

          ADD_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               add ax, bx
               mov word [r9], ax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          ADD_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               add al, bl
               mov byte [r9], al ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          ADD_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               add eax, ebx
               mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

; -----------------------------
; SUB R1, R2 (tam de R1 == tam de R2) - Código 09
; 09 10 -> SUB A1, A0
; R1 = R1 - R2
SUB_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     SUB_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je SUB_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je SUB_32_bits

          SUB_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               sub ax, bx
               mov word [r9], ax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          SUB_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               sub al, bl
               mov byte [r9], al ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          SUB_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               sub eax, ebx
               mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

; -----------------------------
; AND R1, R2 (tam de R1 == tam de R2) - Código 0A
; 0A 76 -> AND H1, H0
; R1 = R1 and R2
AND_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     AND_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je AND_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je AND_32_bits

          AND_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               and ax, bx
               mov word [r9], ax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          AND_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               and al, bl
               mov byte [r9], al ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          AND_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               and eax, ebx
               mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

; -----------------------------
; OR R1, R2 (tam de R1 == tam de R2) - Código 0B
; 0B 23 -> OR D0, D1
; R1 = R1 or R2
OR_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     OR_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je OR_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je OR_32_bits

          OR_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               or ax, bx
               mov word [r9], ax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          OR_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               or al, bl
               mov byte [r9], al ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          OR_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               or eax, ebx
               mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

; -----------------------------
; XOR R1, R2 (tam de R1 == tam de R2) - Código 0C
; 0C 23 -> XOR D0, D1
; R1 = R1 xor R2
XOR_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8 
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador (repete a parte baixa e coloca zero na parte alta)
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     XOR_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1 (*4 pois cada posicao tem 4bits)
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je XOR_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je XOR_32_bits

          XOR_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               xor ax, bx ;assim nao destruo o registrador1
	       mov word [r9], ax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

          XOR_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               xor al, bl
	       mov byte [r9], al ; Insere o resultado de volta no registrador 1
	       call flags
               jmp eterno ; sai da função

          XOR_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               xor eax, ebx
	       mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               call flags
               jmp eterno ; sai da função

; -----------------------------
; NOT R - Código 0D
; 0D 10 -> NOT A1
; R = ~R
NOT_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta)
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8
     call obter_tamanho_registrador

     NOT_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je NOT_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je NOT_32_bits

          NOT_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               not ax
               mov word [r9], ax ; Insere o resultado de volta no registrador 1
               sub ax,0
               call flags
               jmp eterno ; sai da função

          NOT_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               not al
               mov byte [r9], al ; Insere o resultado de volta no registrador 1
               sub al,0
               call flags
               jmp eterno ; sai da função

          NOT_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               not eax
               mov dword [r9], eax ; Insere o resultado de volta no registrador 1
               sub eax,0
               call flags
               jmp eterno ; sai da função

; -----------------------------
; CMP R1, R2 (tam de R1 == tam de R2) - Código 0E
; 0E 34 -> CMP D1, D2
; Equivale a um SUB sem reescrever R1, apenas seta flags
CMP_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9,r9 ; limpa r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx
     xor rcx, rcx ; limpa rcx

     mov al, byte [rsi]
     shr al, 4 ; pega o código do primeiro registrador(o qual está na parte alta) 
     mov r8, rax ; move o codigo do registrador(salvo em rax) para r8 
     call obter_tamanho_registrador
     push r8 ; Salva o tamanho do primeiro registrador na pilha

     mov cl, byte [rsi]
     and cl, 0fh ; pega o código do segundo registrador (repete a parte baixa e coloca zero na parte alta)
     mov r8, rcx
     call obter_tamanho_registrador

     pop rbx
     cmp rbx, r8
     jne invalid_instruction

     CMP_validado:
          lea r9, [regs+rax*4] ; calcula o endereço do registrador 1 (*4 pois cada posicao tem 4bits)
          lea r10, [regs+rcx*4] ; calcula o endereço do registrador 2
          inc rsi

          cmp r8, qword 8 ; vai para o codigo de 8 bits caso o registrador seja de 8 bits
          je CMP_8_bits
          cmp r8, qword 32 ;  vai para o codigo de 32 bits caso o registrador seja de 32 bits
          je CMP_32_bits

          CMP_16_bits:
               mov ax, word [r9] ; pega o valor do registrador 1
               mov bx, word [r10] ; pega o valor do registrador 2
               sub ax, bx ;assim nao destruo o registrador1
               call flags
               jmp eterno ; sai da função

          CMP_8_bits:
               mov al, byte [r9] ; pega o valor do registrador 1
               mov bl, byte [r10] ; pega o valor do registrador 2
               sub al, bl
               call flags
               jmp eterno ; sai da função

          CMP_32_bits:
               mov eax, dword [r9] ; pega o valor do registrador 1
               mov ebx, dword [r10] ; pega o valor do registrador 2
               sub eax, ebx
               call flags
               jmp eterno ; sai da função

; ---------------------------
; JMP - Código 0F
; 0F -> JMP
JMP_OP:
     xor rbx, rbx
     mov bx, word [rdi] ; Pega o endereço que está na pilha
     add rdi, 2 ; Desempilha os 2 bytes
     ; o lea calcula o endereço efetivo do segundo operando e armazena o resultado do calculo em um registrador
     lea rsi, [memoria+rbx] ; Faz RSI apontar para esse endereço
     jmp eterno ; Volta

; -----------------------------
; JL - Código 10
; 10 -> JL
; Se negativo == 1
JL_OP:
     xor rbx, rbx
     mov bl, byte [negativo]
     cmp bl, byte 1
     je JMP_OP ; Se for negativo = 1, dá o jump
     
     add rsi, 1 ; Senão, faz o RSI apontar para a próxima instrução
     jmp eterno ; e volta

; -----------------------------
; JG - Código 11
; 11 -> JG
; Se negativo == 0 E zero == 0
JG_OP:
     xor rbx, rbx
     mov bl, byte [negativo]
     cmp bl, byte 0
     jne NaoEverdade  ; Se for negativo = 1, não corresponde a condição de JG e dá o jump para NaoEverdade

     mov bl, byte [zero]
     cmp bl, byte 0
     jne NaoEverdade  ; Se for zero = 1, não corresponde a condição de JG e dá o jump para NaoEverdade

     jmp JMP_OP ; se ambas as condições forem verdadeiras, dá o jump 

     NaoEverdade:
          add rsi, 1 ; faz o RSI apontar para a próxima instrução
          jmp eterno ; volta

; -----------------------------
; JLE - Código 12
; 12 -> JLE
; Se negativo == 1 OU zero == 1
JLE_OP:
     xor rbx, rbx
     mov bl, byte [negativo]
     cmp bl, byte 1
     je JMP_OP  ; Se for negativo = 1, dá o jump

     mov bl, byte [zero]
     cmp bl, byte 1
     je JMP_OP ; Se for zero = 1, dá o jump

     add rsi, 1 ; faz o RSI apontar para a próxima instrução
     jmp eterno ; volta

;------------------
; JGE - Código 13
; 13 -> JGE
; Se negativo == 0
JGE_OP:
     xor rbx, rbx
     mov bl, byte [negativo]
     cmp bl, byte 0
     je JMP_OP ; Se for zero = 0, dá o jump

     add rsi, 1 ; faz o RSI apontar para a próxima instrução
     jmp eterno ; volta

; -----------------------------
; JC - Código 14
; 14 -> JC
; Se carry == 1
JC_OP:
     xor rbx, rbx
     mov bl, byte [carry]
     cmp bl, byte 1
     je JMP_OP ; Se for carry = 1, dá o jump

     add rsi, 1 ; faz o RSI apontar para a próxima instrução
     jmp eterno ; volta

; -----------------------------
; JNC - Código 15
; 15 -> JNC
; Se carry == 0
JNC_OP:
     xor rbx, rbx
     mov bl, byte [carry]
     cmp bl, byte 0
     je JMP_OP ; Se for carry = 0, dá o jump

     add rsi, 1 ; faz o RSI apontar para a próxima instrução
     jmp eterno ; volta

; ---------------------------
; IN R (R = DO ou D1 ou D2 ou D3) - Código 16
; 16 20 -> IN D0
IN_OP:
     inc rsi
     xor rax, rax
     xor rbx, rbx
     xor rcx, rcx

     mov bl, byte [rsi] ; pega o byte do registrador
     shr bl, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rbx ; move o codigo do registrador(salvo em rbx) para r8
     call obter_tamanho_registrador
     cmp r8, qword 8
     jne invalid_instruction

     IN_validado:
          ; Salva o valor dos registradores na pilha
          push rbp
          push rdi
          push rsi
          
          call getchar
          
          ; Restaura os valores dos registradores
          pop rsi
          pop rdi
          pop rbp
          mov byte [r15+rbx*4], al ; O Resultado do getchar está em al(convenção de chamada)
          inc rsi ; Avança para a proxima instrução
          jmp eterno

; ----------------------------------
; OUT R (R = DO ou D1 ou D2 ou D3) - Código 17
; 17 20 -> OUT D0
OUT_OP:
     inc rsi
     xor rax, rax
     xor rbx, rbx
     xor rcx, rcx

     mov bl, byte [rsi] ; pega o byte do registrador
     shr bl, 4 ; desloca 4 bits para a direita para pegar o código do registrador
     mov r8, rbx ; move o codigo do registrador(salvo em rbx) para r8
     call obter_tamanho_registrador
     cmp r8, qword 8
     jne invalid_instruction

     OUT_validado:
          ; Salva o valor dos registradores na pilha
          push rbp
          push rdi
          push rsi
          
          ; Passa os parâmetros para a função do C printf
          mov rdi, out_fmt ; Passa como parametro a formatação do printf 
          mov cl, byte [r15+rbx*4] ; Pega o caractere a ser impresso
          mov rsi, rcx ; Passa como parametro o caractere a ser impresso
          mov rax, 0 ; Sem registrador xmm (xmm serviria para passar um float como parametro)
          call printf ; printf("%c\n", rcx)
          
          ; Restaura os valores dos registradores
          pop rsi
          pop rdi
          pop rbp
          
          inc rsi ; Avança para a proxima instrução
          jmp eterno

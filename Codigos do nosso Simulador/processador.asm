; --------- Legenda dos Registradores Utilizados ----------
; RSI -> Aponta para o byte atual na memória
; RDI -> Aponta para o topo da pilha
; r15 -> Aponta para o início do vetor de registradores
; r9 -> Aponta para 1 registrador do vetor de registradores
; r10 -> Aponta para uma posição de memória
; rax -> Guarda o código de um registrador
; rcx -> Guarda o código de outro registrador
; rdx -> Guarda o valor da instrução atual

global  memoria
global  regs
global executar
extern print_registradores 
segment  .data
     memoria:times 65536 db 0 
     FIM_PILHA equ $ ; aponta para o fim da memoria
     regs: times 8 dd 0000

     invalido_msg db "Instrução Inválida",0ah
     
     negativo: db 0 
     zero:db 0
     carry:db 0
     ;----
     ; executa a partir do zero.
     desvios: dq  $PUSH_OP,$POP_OP,$LOADC_OP,$LOAD_END_OP,$LOAD_RX_OP,$STORE_END_OP,$STORE_RX_OP,$HALT_OP,$ADD_OP,$SUB_OP,$AND_OP,$OR_OP,$XOR_OP,$NOT_OP,$CMP_OP,$JMP_OP,$JL_OP,$JG_OP,$JLE_OP,$JGE_OP,$JC_OP,$JNC_OP,$IN_OP,$OUT_OP
 
segment .text
    executar: 
          mov rsi, memoria      ; funciona com IP(Ponteiro para a instrucao)
          mov rdi, $FIM_PILHA  ; funciona com SP(Ponteiro para o topo da pilha)
          mov r15, regs       ; r15 aponta para os registradores
    eterno:
          xor rdx,rdx ; limpa rdx
          mov dl, byte [rsi] ; pega o byte da instrucao
          cmp dl, 18h   ; instrucao valida < 0xe
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
    mov r8, qword 32
    ret

invalid_instruction:
     mov rax, 4
     mov rbx, 1
     mov rcx, invalido_msg
     mov rdx, 21
     int 0x80
     ret

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


STORE_END_OP:
     inc rsi ; avança para pegar os proximos bytes
     xor r8, r8 ; limpa r8
     xor r9, r9
     xor r10, r10 ; limpa r10
     xor rax, rax ; limpa rax
     xor rbx, rbx ; limpa rbx

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
          mov bx, word [r9] ; pega 2 bytes seguidos da memoria a partir do endereço calculado(r10)
          mov word [r10], bx
          jmp eterno ; sai da função

     STORE_END_8_bits:
          mov bl, byte [r9] ; pega 1 byte da memoria a partir do endereço calculado(r10)
          mov byte [r10], bl
          jmp eterno ; sai da função

     STORE_END_32_bits:
          mov ebx, dword [r9] ; pega 4 bytes seguidos da memoria a partir do endereço calculado(r10)
          mov dword [r10], ebx
          jmp eterno ; sai da função

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
               mov bx, word [r9]
               mov word [r10], bx
               jmp eterno ; sai da função

          STORE_RX_8_bits:
               mov bl, byte [r9]
               mov byte [r10], bl
               jmp eterno ; sai da função

          STORE_RX_32_bits:
               mov ebx, dword [r9]
               mov dword [r10], ebx
               jmp eterno ; sai da função


HALT_OP:
     ret

ADD_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
SUB_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
AND_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
OR_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
XOR_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
NOT_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
CMP_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JMP_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JL_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JG_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JLE_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JGE_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JC_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
JNC_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
IN_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
OUT_OP:
     ret ; Isso está aqui apenas para que o vetor de desvios não dê erro de compilação, remova-o quando começarem a implementar as instruções.
#include <stdio.h>
#include <stdint.h>
#include <string.h>

extern int8_t memoria[];
extern int32_t regs[];
extern void   executar();
extern int8_t negativo;
extern int8_t zero;
extern int8_t carry;

void print_memoria(){
    FILE *arquivo = fopen("memoria.txt", "w");
    for(int i = 0; i < 65536; i++){
        fprintf(arquivo, "%04X - %02X\n", i,  memoria[i]);
    }
    fclose(arquivo);
}

int main(int argc, char *argv[]){
    static char  buffer[131072]; // Como a memoria é de 65k bytes, o tamanho do buffer deve ser de 131k, pois um byte é representado por 2 caracteres
    int i=0,j=0, k=0;
    int8_t aux;
    if(argc == 1){
        printf("Digite o código a ser executado em letras maiusculas, duas letras por byte, ordem little endian(por exemplo, o endereço 0x001A deve ser digitado como 1A 00)\n");
        scanf("%s",buffer); // Lê o codigo digitado pelo usuario no terminal
    }
    else{
        FILE *arquivo = fopen(argv[1], "r"); // Abre o arquivo digitado pelo usuario
        if (arquivo == NULL){
            printf("Erro ao abrir o arquivo\n");
            return -1;
        }
        char c;
        while ((c = fgetc(arquivo)) != EOF) {
            if(c != '\n' && c != ' '){
                buffer[k++] = c;
            }
        }
        fclose(arquivo);
    }
    int tamanho_lido = strlen(buffer); // Obtem o numero de caracteres
    if(tamanho_lido % 2 == 0){
        // Loop para converter os bytes do buffer para byte em hexadecimal e armazenar no vetor codigo
        while (buffer[i]!=0){
            aux=buffer[i++]; // Obtem o caractere atual do buffer e avança para o próximo caractere
            // Convete a primeira parte do byte de ASCII para hexadecimal
            if(aux < 58 && aux > 47){ // Se o caractere está entre 48 e 57 (0-9), converte para o número correspondente
                aux=aux-48; 
            }
            else{ 
                if(aux < 71 && aux > 64){ // Se o caractere está entre 65 e 70 (A-F), converte para o número correspondente em hexa
                    aux=aux-55;
                } else {
                    printf("Erro no Código1\n");
                    return -1;
                }
            }
            // Convete a segunda parte do byte de ASCII para hexadecimal
            if(buffer[i] < 58 && buffer[i] > 47){ // Se o caractere está entre 48 e 57(ou seja, é um caractere de 0 a 9), converte para o número correspondente
                aux=aux*16+buffer[i++]-48; // converte o caractere atual, adiciona ao valor anterior multiplicado por 16 e avança para o próximo caractere
            } 
            else{ 
                if(buffer[i] < 71 && buffer[i] > 64){ // Se o caractere está entre 65 e 70(ou seja, é um caractere de A a F), converte para o número correspondente
                    aux=aux*16+buffer[i++]-55; // converte o caractere atual, adiciona ao valor anterior multiplicado por 16 e avança para o próximo caractere
                } else {
                    printf("Erro no Código2\n");
                    return -1;
                }
            }
            memoria[j++]=aux;
        }
        //print_memoria();
        printf("\nChamando modulo cpu asm \n");
        executar();
        printf("\nFim do Programa\n");
        printf("\nRegistradores(Signed)\n");
        printf("A0=%d A1=%d D0=%d D1=%d D2=%d D3=%d H0=%d H1=%d \n" ,(int16_t) regs[0], (int16_t) regs[1], (int8_t) regs[2], (int8_t) regs[3], (int8_t) regs[4], (int8_t) regs[5], (int32_t) regs[6], (int32_t) regs[7]);
        printf("\nRegistradores(Unsigned)\n");
        printf("A0=%u A1=%u D0=%u D1=%u D2=%u D3=%u H0=%u H1=%u \n" ,(uint16_t) regs[0], (uint16_t) regs[1], (uint8_t) regs[2], (uint8_t) regs[3], (uint8_t) regs[4], (uint8_t) regs[5], (uint32_t) regs[6], (uint32_t) regs[7]);
        printf("\nRegistradores(Hexadecimal)\n");
        printf("A0=%X A1=%X D0=%X D1=%X D2=%X D3=%X H0=%X H1=%X \n" ,regs[0], regs[1], regs[2], regs[3], regs[4], regs[5], regs[6], regs[7]);
        printf("\nFlags\n");
        printf("negativo=%d zero=%d carry=%d \n", negativo, zero, carry);
        print_memoria();
    }
    else{
        printf("Erro no Código3\n");
        return -1;
    }
    
    return 0;
}

#include <stdio.h>
#include <stdint.h>

extern  int8_t codigo[];
extern  int16_t regs[];
extern  void   executa();
void main()
{
 char  buffer[20000];
 int i=0,j=0;
 int8_t aux;
 printf("digite o código a ser executado em maiuscula duas letras por byte\n");
 scanf("%s",buffer);
/*para numero */

 while (buffer[i]!=0)
  {
   (aux=buffer[i++]) < 65 ? (aux=aux-48) : (aux=aux-55);
   buffer[i] < 65  ? (aux=aux*16+buffer[i++]-48) :  (aux=aux*16+buffer[i++]-55);
   codigo[j++]=aux;
    }
 printf("Chamando modulo cpu asm \n");
 executa();
printf("volta ao C \n");
printf("R1=%d R2=%d R3=%d R4=%d \n" ,(int16_t) regs[0], (int16_t) regs[1],(int16_t) regs[2],(int16_t) regs[3]);

}

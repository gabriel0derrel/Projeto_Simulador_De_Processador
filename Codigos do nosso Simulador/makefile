# Makefile do processador

all: exec

exec: processador_C.c processador_NASM.o
	gcc -m64 -no-pie processador_C.c processador_NASM.o -o exec
	
processador_NASM.o: processador_NASM.asm
	nasm -f elf64 processador_NASM.asm
	
clean:
	rm -rf *.o *~ exec

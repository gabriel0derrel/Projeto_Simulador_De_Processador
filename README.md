# Projeto De Um Simulador De Um Processador

Este repositório contém o trabalho final da disciplina **Arquitetura de Computadores 1**, que consiste na implementação de um simulador de um processador baseado nas especificações definidas no documento `tarq1.pdf`.

## Visão Geral
O projeto foi desenvolvido como parte da avaliação final da disciplina e tem como objetivo consolidar os conhecimentos sobre arquiteturas de computadores.

## Conteúdo do Repositório
- **`Codigos do nosso Simulador/`**: Contém os códigos-fonte do simulador em Assembly (NASM) e C.
- **O arquivo `tarq1.pdf` com as especificações do processador.
- **`tests/`**: Arquivos de teste para validação do simulador.
- **`README.md`**: Este arquivo com as instruções e descrição do projeto.

## Requisitos
Para compilar e executar o simulador, é necessário ter instalado:
- NASM (Netwide Assembler) para o código em Assembly.
- GCC para o código em C.
- `make` para automatizar o processo de compilação.

## Como Executar
1. Clone este repositório:
   ```bash
   git clone https://github.com/gabriel0derrel/Projeto_Simulador_De_Processador.git
   ```
   Ou
   ```bash
   git clone git@github.com:gabriel0derrel/Projeto_Simulador_De_Processador.git
   ```
2. Navegue até o diretório do projeto:
   ```bash
   cd Projeto_Simulador_De_Processador/Codigos\ do\ nosso\ Simulador/
   ```
3. Compile o simulador utilizando o `make`:
   ```bash
   make
   ```
4. Execute o simulador:
   ```bash
   ./exec
   ```
   Ou
   ```bash
   ./exec nome_do_arquivo.dasm
   ```
5. Deletar o que foi compilado:
   ```bash
   make clean
   ```

## Testes
Os arquivos na pasta `tests/` permitem validar as funcionalidades do simulador. Para executar os testes, compile e execute conforme as instruções do arquivo `README`.

## Estrutura do Processador
O processador implementado no simulador segue as especificações do arquivo `tarq1.pdf`. Entre os principais componentes estão:
- O nome, o código e o tamanho de cada registrador
- O nome, o código e a lógica de cada comando

## Autores
Este projeto foi desenvolvido por:
- **[Gabriel Derrel Martins Santee]**(https://github.com/gabriel0derrel)
- **[Guilherme Ponciano Silva]**(https://github.com/Guilheme-collab)
- **[Lucas Pereira Nunes]**(https://github.com/Prizrak2)
- **[Ronaldo Oliveira de Jesus]**(https://github.com/ParadoxIsReal)

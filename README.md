# Ling-Par-VM

Este projeto define uma **máquina virtual simples (RoboVM)** e uma **linguagem de programação de alto nível (RoboLabirinto)** para programar um robô explorador de labirintos.  

---

## RoboVM (Máquina Virtual do Robô)

### Registradores
- `X` → posição horizontal do robô no labirinto.  
- `Y` → posição vertical do robô no labirinto.  

### Sensores
- `frente_livre` → verdadeiro se não há parede à frente.  
- `carregando` → verdadeiro se o robô está segurando um objeto.  

### Memória
- **Pilha (stack)** → usada para armazenar valores temporários.  

### Instruções mínimas
- `SET R n` → define o valor de um registrador.  
- `INC R` → incrementa o valor do registrador em 1.  
- `DECJZ R label` → decrementa registrador e salta se chegar a zero.  
- `GOTO label` → salto incondicional.  
- `PUSH R` / `POP R` → empilhar/desempilhar valores.  
- `PRINT` → imprime valor atual de `X` ou `Y`.  
- `HALT` → encerra a execução.  

---

## Gramática (EBNF)

```ebnf
programa     = { comando } ;

comando      = atribuicao, ";" 
             | acao, ";" 
             | condicional 
             | loop ;

acao         = "andar", "()" 
             | "virar_esq", "()" 
             | "virar_dir", "()" 
             | "pegar", "()" 
             | "largar", "()" ;

condicional  = "se", "(", expressao, ")", "{", { comando }, "}", 
               [ "senao", "{", { comando }, "}" ] ;

loop         = "enquanto", "(", expressao, ")", "{", { comando }, "}" ;

atribuicao   = identificador, "=", expressao ;

expressao    = identificador 
             | numero 
             | booleano 
             | expressao, operador, expressao 
             | "nao", expressao ;

operador     = "+" | "-" | "*" | "/" | "<" | ">" | "==" ;

booleano     = "verdadeiro" | "falso" ;

identificador= "x" | "y" | "energia" | "frente_livre" | "carregando" ;

numero       = digito, { digito } ;

digito       = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;

```
![texto alternativo](VMLINGPARpng.jpg)

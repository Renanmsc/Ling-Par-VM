# Ling-Par-VM

Este projeto define uma **máquina virtual simples (RoboVM)** e uma **linguagem de programação de alto nível (RoboLabirinto)** para programar um robô explorador de labirintos.  

---

## RoboVM (Máquina Virtual do Robô)

### Registradores
- `ENERGY` → energia/bateria do robô (valor inteiro)  
- `STEPS` → contador de passos/iterações (valor inteiro)

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

### Exemplo de codigo Alto Nivel
```
energy = 20;
steps = 0;

enquanto (energy > 0) {
    se (carregando) {
        largar();
    } senao se (tem_objeto()) {
        pegar();
        steps = steps + 1;
    }
    
    se (frente_livre) {
        andar();
        energy = energy - 1;
    } senao {
        virar_dir();
    }
}
```

### Assembly
```
; Busca Simples por Objetos
    SET ENERGY 20
    SET STEPS 0

main_loop:
    DECJZ ENERGY end
    
    ; Verifica se está carregando objeto
    ROBO_TEM_OBJETO
    DECJZ STEPS check_object
    
    ; Está carregando - larga
    ROBO_LARGAR
    GOTO check_movement

check_object:
    ; Verifica se tem objeto para pegar
    ROBO_TEM_OBJETO
    DECJZ STEPS check_movement
    
    ; Tem objeto - pega
    ROBO_PEGAR
    INC STEPS

check_movement:
    ; Verifica se pode andar
    ROBO_FRENTE_LIVRE
    DECJZ ENERGY turn
    
    ; Frente livre - anda
    ROBO_ANDAR
    DEC ENERGY
    GOTO main_loop

turn:
    ; Virar direita na parede
    ROBO_VIRAR_DIR
    GOTO main_loop

end:
    PRINT
    HALT
```

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STACK_SIZE 100

typedef struct {
    int ENERGY;
    int STEPS;
    int stack[STACK_SIZE];
    int sp; // stack pointer
    int pc; // program counter
    int running;
    
    // Estado do robô
    int pos_x, pos_y;
    int direcao; // 0=N, 1=E, 2=S, 3=O
    int carregando;
    char **labirinto;
    int lab_width, lab_height;
} RoboVM;

void vm_init(RoboVM *vm, char **labirinto, int width, int height) {
    vm->ENERGY = 0;
    vm->STEPS = 0;
    vm->sp = 0;
    vm->pc = 0;
    vm->running = 1;
    
    vm->pos_x = 1;
    vm->pos_y = 1;
    vm->direcao = 1;
    vm->carregando = 0;
    vm->labirinto = labirinto;
    vm->lab_width = width;
    vm->lab_height = height;
}

int vm_frente_livre(RoboVM *vm) {
    int x = vm->pos_x, y = vm->pos_y;
    
    switch(vm->direcao) {
        case 0: y--; break; // Norte
        case 1: x++; break; // Leste
        case 2: y++; break; // Sul  
        case 3: x--; break; // Oeste
    }
    
    return (x >= 0 && x < vm->lab_width && 
            y >= 0 && y < vm->lab_height &&
            vm->labirinto[y][x] != '#');
}

void vm_execute_instruction(RoboVM *vm, const char *instruction) {
    char cmd[100];
    char reg[10];
    int value;
    char label[50];
    
    if (sscanf(instruction, "SET %s %d", reg, &value) == 2) {
        if (strcmp(reg, "ENERGY") == 0) vm->ENERGY = value;
        else if (strcmp(reg, "STEPS") == 0) vm->STEPS = value;
    }
    else if (sscanf(instruction, "INC %s", reg) == 1) {
        if (strcmp(reg, "ENERGY") == 0) vm->ENERGY++;
        else if (strcmp(reg, "STEPS") == 0) vm->STEPS++;
    }
    else if (strcmp(instruction, "ROBO_ANDAR") == 0) {
        if (vm_frente_livre(vm) && vm->ENERGY > 0) {
            switch(vm->direcao) {
                case 0: vm->pos_y--; break;
                case 1: vm->pos_x++; break;
                case 2: vm->pos_y++; break;
                case 3: vm->pos_x--; break;
            }
            vm->ENERGY--;
        }
    }
    else if (strcmp(instruction, "ROBO_VIRAR_ESQ") == 0) {
        vm->direcao = (vm->direcao + 3) % 4;
    }
    else if (strcmp(instruction, "ROBO_VIRAR_DIR") == 0) {
        vm->direcao = (vm->direcao + 1) % 4;
    }
    else if (strcmp(instruction, "ROBO_FRENTE_LIVRE") == 0) {
        vm->ENERGY = vm_frente_livre(vm) ? 1 : 0;
    }
    else if (strcmp(instruction, "HALT") == 0) {
        vm->running = 0;
    }
}

void vm_print_state(RoboVM *vm) {
    printf("Pos: (%d,%d) Dir: %d Energy: %d Steps: %d Carrying: %d\n",
           vm->pos_x, vm->pos_y, vm->direcao, vm->ENERGY, vm->STEPS, vm->carregando);
}
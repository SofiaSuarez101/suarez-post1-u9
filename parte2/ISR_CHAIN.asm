; ISR_CHAIN.ASM - ISR para IRQ1 con encadenamiento al handler original
; Compila: nasm -f bin ISR_CHAIN.ASM -o ISR_CHAIN.COM
;
[BITS 16]
[ORG 0x100]

MAX_KEYS EQU 5

section .data
old_isr   DD 0                  ; SEG:OFF del handler original de INT 09h
contador  DW 0                  ; interrupciones de teclado registradas
msg_ini   DB "Escribe teclas: el eco de DOS debe seguir funcionando.", 0Dh, 0Ah, "$"
msg_fin   DB 0Dh, 0Ah, "ISR_CHAIN restaurado. Interrupciones registradas: $"
msg_crlf  DB 0Dh, 0Ah, "$"

section .text
start:
    ; Guardar vector original de INT 09h
    MOV  AX, 3509h
    INT  21h
    MOV  [old_isr], BX
    MOV  [old_isr+2], ES

    MOV  AH, 09h
    MOV  DX, msg_ini
    INT  21h

    ; Instalar ISR encadenado
    PUSH DS
    MOV  AX, CS
    MOV  DS, AX
    MOV  DX, mi_isr_chain
    MOV  AX, 2509h
    INT  21h
    POP  DS
    STI

.esperar:
    ; Eco: si el handler original dejo una tecla en el buffer, mostrarla
    MOV  AH, 01h
    INT  16h                    ; ZF=1 si el buffer esta vacio
    JZ   .sin_tecla
    MOV  AH, 00h
    INT  16h                    ; AL = caracter ASCII
    MOV  DL, AL
    MOV  AH, 02h
    INT  21h
.sin_tecla:
    MOV  AX, [contador]
    CMP  AX, MAX_KEYS
    JL   .esperar

    ; Restaurar handler original
    CLI
    PUSH DS
    LDS  DX, [old_isr]
    MOV  AX, 2509h
    INT  21h
    POP  DS
    STI

    MOV  AH, 09h
    MOV  DX, msg_fin
    INT  21h
    MOV  AX, [contador]
    CALL imprimir_decimal
    MOV  AH, 09h
    MOV  DX, msg_crlf
    INT  21h

    MOV  AH, 4Ch
    INT  21h

; ---- ISR con encadenamiento -------------------------------------
mi_isr_chain:
    INC  WORD [CS:contador]     ; codigo propio (sin tocar DS ni otros registros)

    ; Encadenar: simular INT (PUSHF + far CALL) hacia el handler original
    PUSHF
    CALL FAR [CS:old_isr]       ; el handler original termina con IRET y vuelve aqui
    IRET                        ; retorno al programa interrumpido

; Subrutina: imprime AX en decimal (sin signo)
imprimir_decimal:
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV  BX, 10
    XOR  CX, CX
.divide:
    XOR  DX, DX
    DIV  BX
    PUSH DX
    INC  CX
    TEST AX, AX
    JNZ  .divide
.imprimir:
    POP  DX
    ADD  DL, 30h
    MOV  AH, 02h
    INT  21h
    LOOP .imprimir
    POP  DX
    POP  CX
    POP  BX
    POP  AX
    RET
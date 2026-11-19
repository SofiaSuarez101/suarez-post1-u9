; ISR_KB.ASM - ISR personalizado para IRQ1 (teclado)
; Compila: nasm -f bin ISR_KB.ASM -o ISR_KB.COM
[BITS 16]
[ORG 0x100]

KB_DATA_PORT EQU 60h
PIC_CMD_PORT EQU 20h            ; puerto de comandos del PIC maestro
EOI          EQU 20h            ; End Of Interrupt no especifico
MAX_KEYS     EQU 5

section .data
contador   DW 0                 ; interrupciones de teclado atendidas
old_isr    DD 0                 ; SEG:OFF del handler original de INT 09h
msg_tecla  DB 0Dh, 0Ah, "Tecla detectada por ISR propio$"
msg_fin    DB 0Dh, 0Ah, "ISR restaurado. Fin del programa.$"

section .text
start:
    ; Guardar vector original de INT 09h
    MOV  AX, 3509h              ; AH=35h: obtener vector
    INT  21h                    ; ES:BX = handler actual
    MOV  [old_isr], BX
    MOV  [old_isr+2], ES

    ; Instalar ISR propio
    PUSH DS
    MOV  AX, CS
    MOV  DS, AX
    MOV  DX, mi_isr             ; DS:DX = nuevo handler
    MOV  AX, 2509h              ; AH=25h: fijar vector
    INT  21h
    POP  DS
    STI                         ; asegurar interrupciones habilitadas

.esperar:
    MOV  AX, [contador]
    CMP  AX, MAX_KEYS
    JL   .esperar               ; espera activa hasta MAX_KEYS interrupciones

    ; Restaurar handler original
    CLI
    PUSH DS                     ; LDS modifica DS: se preserva para poder
    LDS  DX, [old_isr]          ; imprimir despues con DS=segmento del programa
    MOV  AX, 2509h
    INT  21h
    POP  DS
    STI

    MOV  AH, 09h
    MOV  DX, msg_fin
    INT  21h
    MOV  AH, 4Ch
    INT  21h

; ---- ISR propio -------------------------------------------------
mi_isr:
    PUSH AX
    PUSH DX
    PUSH DS

    MOV  AX, CS
    MOV  DS, AX                 ; DS apunta al segmento del programa

    IN   AL, KB_DATA_PORT       ; leer y descartar el scancode (libera el 8042)

    MOV  AH, 09h
    MOV  DX, msg_tecla
    INT  21h

    INC  WORD [contador]

    MOV  AL, EOI                ; EOI al PIC maestro antes del IRET
    OUT  PIC_CMD_PORT, AL

    POP  DS
    POP  DX
    POP  AX
    IRET
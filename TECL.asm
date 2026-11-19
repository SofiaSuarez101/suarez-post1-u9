; TECL.ASM - Lectura del estado del teclado 8042 por polling
; Compila: nasm -f bin TECL.ASM -o TECL.COM
[BITS 16]
[ORG 0x100]                     ; programa .COM, CS=DS=ES=SS

KB_DATA_PORT   EQU 60h          ; Data Port del 8042 (scancode)
KB_STATUS_PORT EQU 64h          ; Status Register del 8042
OBF_MASK       EQU 01h          ; bit 0: Output Buffer Full
BREAK_MASK     EQU 80h          ; bit 7 del scancode: 1 = tecla soltada (break)

start:
    ; CLI evita que el handler del BIOS (IRQ1) lea el puerto 60h antes
    ; que este programa y deje OBF en 0 sin que el polling lo vea.
    CLI

.poll:
    IN   AL, KB_STATUS_PORT     ; leer registro de estado del 8042
    TEST AL, OBF_MASK           ; comprobar bit OBF
    JZ   .poll                  ; OBF=0: no hay dato listo, repetir

    IN   AL, KB_DATA_PORT       ; leer scancode del Data Port
    TEST AL, BREAK_MASK         ; ignorar codigos de tecla soltada
    JNZ  .poll                  ; (p. ej. la liberacion de ENTER al lanzar el programa)

    CALL imprimir_hex           ; mostrar el scancode en hexadecimal

    MOV  AH, 02h                ; CR + LF
    MOV  DL, 0Dh
    INT  21h
    MOV  DL, 0Ah
    INT  21h

    STI                         ; devolver las interrupciones al sistema
    MOV  AH, 4Ch
    INT  21h                    ; terminar programa

; ---------------------------------------------------------------
; imprimir_hex: imprime AL como dos digitos hexadecimales
; ---------------------------------------------------------------
imprimir_hex:
    PUSH AX
    PUSH DX
    MOV  AH, AL                 ; copia del byte original
    MOV  DL, AL
    SHR  DL, 4                  ; nibble alto
    CALL imprimir_nibble
    MOV  DL, AH
    AND  DL, 0Fh                ; nibble bajo
    CALL imprimir_nibble
    POP  DX
    POP  AX
    RET

; imprimir_nibble: DL = 0..15, imprime el digito hexadecimal
imprimir_nibble:
    ADD  DL, 30h                ; '0'..'9'
    CMP  DL, 3Ah
    JB   .digito
    ADD  DL, 07h                ; ajuste para 'A'..'F'
.digito:
    PUSH AX
    MOV  AH, 02h
    INT  21h
    POP  AX
    RET
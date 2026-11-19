; POLL_T.ASM - Polling con timeout para el puerto de teclado
; Compila: nasm -f bin POLL_T.ASM -o POLL_T.COM
[BITS 16]
[ORG 0x100]

KB_DATA_PORT   EQU 60h
KB_STATUS_PORT EQU 64h
OBF_MASK       EQU 01h
BREAK_MASK     EQU 80h
MAX_RETRY      EQU 0FFFFh       ; reintentos maximos (usar 0005h para forzar el timeout)

start:
    CLI                         ; el handler del BIOS no debe consumir el scancode
    MOV  CX, MAX_RETRY

.poll:
    IN   AL, KB_STATUS_PORT
    TEST AL, OBF_MASK
    JNZ  .dato_listo            ; OBF=1: hay dato
.siguiente:
    LOOP .poll                  ; CX--, repetir mientras CX != 0

    ; Timeout: CX llego a 0 sin dato
    MOV  AH, 09h
    MOV  DX, msg_timeout
    INT  21h
    JMP  .fin

.dato_listo:
    IN   AL, KB_DATA_PORT       ; leer el byte (libera el buffer del 8042)
    TEST AL, BREAK_MASK         ; si es un break code, seguir esperando
    JNZ  .siguiente
    CALL imprimir_hex           ; mostrar el scancode en hexadecimal
    MOV  AH, 09h
    MOV  DX, msg_crlf
    INT  21h

.fin:
    STI
    MOV  AH, 4Ch
    INT  21h

; imprimir_hex: imprime AL como dos digitos hexadecimales
imprimir_hex:
    PUSH AX
    PUSH DX
    MOV  AH, AL
    MOV  DL, AL
    SHR  DL, 4
    CALL imprimir_nibble
    MOV  DL, AH
    AND  DL, 0Fh
    CALL imprimir_nibble
    POP  DX
    POP  AX
    RET

imprimir_nibble:
    ADD  DL, 30h
    CMP  DL, 3Ah
    JB   .digito
    ADD  DL, 07h
.digito:
    PUSH AX
    MOV  AH, 02h
    INT  21h
    POP  AX
    RET

msg_timeout DB 'Timeout: sin respuesta del dispositivo', 0Dh, 0Ah, '$'
msg_crlf    DB 0Dh, 0Ah, '$'
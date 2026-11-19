; LPT1.ASM - Envio de un caracter al puerto paralelo LPT1 (protocolo Centronics)
; Compila: nasm -f bin LPT1.ASM -o LPT1.COM
[BITS 16]
[ORG 0x100]

DATA_PORT     EQU 0378h         ; Data Register   (D0-D7)
STATUS_PORT   EQU 0379h         ; Status Register (BUSY, ACK, PE, SELECT, ERROR)
CTRL_PORT     EQU 037Ah         ; Control Register (STROBE, AUTOFEED, INIT, SELECT_IN)
BUSY_MASK     EQU 80h           ; bit 7: BUSY# (1 = impresora lista)
ACK_MASK      EQU 40h           ; bit 6: ACK#  (0 = impresora confirmo)
STROBE_MASK   EQU 01h           ; bit 0 del control
MAX_RETRY     EQU 0FFFFh

; NOTA: los puertos 0378h-037Ah superan 8 bits, por lo que IN/OUT
; deben usar DX como registro de puerto (la forma con inmediato solo
; admite puertos 00h-FFh).

start:
    ; 1. Esperar BUSY#=1 (impresora lista), con limite de reintentos
    MOV  CX, MAX_RETRY
    MOV  DX, STATUS_PORT
.wait_ready:
    IN   AL, DX
    TEST AL, BUSY_MASK
    JNZ  .listo
    LOOP .wait_ready
    MOV  DX, msg_ocupada        ; timeout: impresora nunca lista
    JMP  .mensaje

.listo:
    ; 2. Colocar el dato (caracter "A" = 41h) en el bus de datos
    MOV  AL, 41h
    MOV  DX, DATA_PORT
    OUT  DX, AL

    ; 3. Pulso de STROBE sobre el bit 0 del registro de control.
    ;    El hardware invierte este bit: escribir 1 lleva la linea
    ;    STROBE# a nivel bajo (activa); escribir 0 la desactiva.
    MOV  DX, CTRL_PORT
    IN   AL, DX                 ; leer-modificar-escribir: conserva los demas bits
    OR   AL, STROBE_MASK        ; STROBE activo
    OUT  DX, AL
    MOV  CX, 0Fh                ; retardo minimo (~1 us)
.delay:
    LOOP .delay
    AND  AL, 0FEh               ; STROBE inactivo
    OUT  DX, AL

    ; 4. Esperar ACK# en bajo (bit 6 del estado), con limite de reintentos
    MOV  CX, MAX_RETRY
    MOV  DX, STATUS_PORT
.wait_ack:
    IN   AL, DX
    TEST AL, ACK_MASK
    JZ   .ack_ok                ; ACK# = 0: la impresora confirmo
    LOOP .wait_ack
    MOV  DX, msg_sin_ack        ; en DOSBox sin impresora no hay ACK
    JMP  .mensaje

.ack_ok:
    MOV  DX, msg_ok

.mensaje:
    MOV  AH, 09h                ; DX ya apunta al mensaje elegido
    INT  21h

    MOV  AH, 4Ch
    INT  21h

msg_ocupada DB 'LPT1: impresora no lista (BUSY# nunca activo)', 0Dh, 0Ah, '$'
msg_sin_ack DB 'LPT1: caracter enviado, sin ACK (no hay impresora conectada)', 0Dh, 0Ah, '$'
msg_ok      DB 'LPT1: caracter enviado y confirmado con ACK', 0Dh, 0Ah, '$'
; MULTI_ST.ASM - Polling combinado de dos puertos de estado (teclado + LPT1)
; Compila: nasm -f bin MULTI_ST.ASM -o MULTI_ST.COM
[BITS 16]
[ORG 0x100]

KB_STATUS_PORT  EQU 64h         ; estado del 8042
OBF_MASK        EQU 01h         ; bit 0: Output Buffer Full
LPT_STATUS_PORT EQU 0379h       ; estado del puerto paralelo (requiere DX)
LPT_READY_MASK  EQU 80h         ; bit 7: BUSY# (1 = listo)

start:
    CLI                         ; el handler del BIOS no debe vaciar OBF antes del sondeo

.poll:
    ; Bandera de teclado: bit 0 (OBF) del registro de estado 64h
    IN   AL, KB_STATUS_PORT
    AND  AL, OBF_MASK
    MOV  BL, AL                 ; BL = bandera_teclado (0 o 1)

    ; Bandera de LPT1: bit 7 (listo) del registro de estado 0379h
    MOV  DX, LPT_STATUS_PORT    ; puerto > 0FFh: IN debe usar DX
    IN   AL, DX
    AND  AL, LPT_READY_MASK
    SHR  AL, 7                  ; normaliza a 0 o 1
    MOV  BH, AL                 ; BH = bandera_lpt1 (0 o 1)

    MOV  AL, BL
    OR   AL, BH                 ; AL = bandera_teclado OR bandera_lpt1
    JZ   .poll                  ; ningun dispositivo listo: repetir

    STI                         ; condicion cumplida: devolver interrupciones

    ; El OR descarta cual bandera fue: se examinan BL y BH por separado
    TEST BL, BL
    JZ   .solo_lpt1
    MOV  AH, 09h
    MOV  DX, msg_tecl
    INT  21h

.solo_lpt1:
    TEST BH, BH
    JZ   .fin
    MOV  AH, 09h
    MOV  DX, msg_lpt1
    INT  21h

.fin:
    MOV  AH, 4Ch
    INT  21h

msg_tecl DB "Teclado listo (OBF=1).", 0Dh, 0Ah, "$"
msg_lpt1 DB "LPT1 listo (BUSY#=1).", 0Dh, 0Ah, "$"
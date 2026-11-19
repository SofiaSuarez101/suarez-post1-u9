; MASK_KB.ASM - Enmascarar/desenmascarar IRQ1 con el PIC 8259A
; Compila: nasm -f bin MASK_KB.ASM -o MASK_KB.COM
[BITS 16]
[ORG 0x100]

PIC_IMR_PORT EQU 21h            ; Interrupt Mask Register del PIC maestro
IRQ1_MASK    EQU 02h            ; bit 1 = IRQ1 (teclado)
WAIT_TICKS   EQU 55             ; ~3 s a 18.2 ticks/s

start:                          ; el codigo va primero: en un .COM la ejecucion
                                ; empieza en 0100h, los datos van al final
    ; Leer IMR actual y conservarlo
    IN   AL, PIC_IMR_PORT
    PUSH AX

    ; Enmascarar IRQ1
    OR   AL, IRQ1_MASK
    OUT  PIC_IMR_PORT, AL

    MOV  AH, 09h
    MOV  DX, msg_mask
    INT  21h

    ; Esperar ~3 s con el timer del BIOS (INT 1Ah devuelve ticks en CX:DX)
    MOV  AH, 00h
    INT  1Ah
    MOV  SI, DX                 ; SI = tick inicial (palabra baja)
.wait:
    MOV  AH, 00h
    INT  1Ah
    MOV  AX, DX
    SUB  AX, SI                 ; ticks transcurridos (resta sin signo, tolera desbordes)
    CMP  AX, WAIT_TICKS
    JB   .wait                  ; repetir mientras transcurrido < 55

    ; Restaurar IMR original
    POP  AX
    OUT  PIC_IMR_PORT, AL

    MOV  AH, 09h
    MOV  DX, msg_unmask
    INT  21h

    MOV  AH, 4Ch
    INT  21h

msg_mask   DB "IRQ1 enmascarado (teclado deshabilitado)...$"
msg_unmask DB 0Dh, 0Ah, "IRQ1 restaurado.$"
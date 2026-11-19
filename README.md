# Post-contenido Unidad 9: Entrada y Salida Avanzados (Puertos, Polling e Interrupciones)

**Asignatura:** Arquitectura de Computadores
**Plataforma:** NASM 2.x sobre DOSBox 0.74

## Estructura del repositorio

```
apellido-post1-u9/
├── README.md
├── parte1/
│   ├── TECL.ASM / TECL.COM
│   ├── POLL_T.ASM / POLL_T.COM
│   ├── LPT1.ASM / LPT1.COM
│   ├── MULTI_ST.ASM / MULTI_ST.COM
└── parte2/
│   ├── ISR_KB.ASM / ISR_KB.COM
│   ├── MASK_KB.ASM / MASK_KB.COM
│   ├──ISR_CHAIN.ASM / ISR_CHAIN.COM
│   ├── ISR_TIME.ASM / ISR_TIME.COM
└── capturas/
```

# Parte 1: Acceso directo a puertos de E/S

## Objetivo

El estudiante implementa programas en ensamblador x86 que acceden directamente a puertos de E/S con `IN` y `OUT`, aplica polling para sincronizarse con dispositivos, combina banderas de dos puertos de estado y verifica el comportamiento de los registros del controlador de teclado 8042 y del puerto paralelo LPT1.

## Prerrequisitos

- DOSBox 0.74 o superior con NASM 2.x accesible desde el prompt de DOS.
- Conocimientos de INT 21h, registros de segmento y modos de direccionamiento (Unidades 3 a 6).
- Directorio de trabajo `C:\U9P1\`.

### LPT1.ASM: escritura al puerto paralelo (Checkpoint 3)

Espera BUSY# = 1 en 0x379 (bit 7), coloca el carácter `A` (41h) en 0x378 y genera el pulso de STROBE sobre el bit 0 de 0x37A, con un retardo corto entre la activación y la desactivación.

```
nasm -f bin LPT1a.ASM -o LPT1a.COM
LPT1a
```

**Comportamiento observado en DOSBox:** al ejecutar LPT1.COM el programa terminó sin bloquearse y mostró “LPT1: caracter enviado y confirmado con ACK”. DOSBox no tiene impresora física conectada, pero el puerto emulado devuelve en 0379h BUSY#=1 y ACK#=0 de forma inmediata. Por eso .wait_ready salió en la primera iteración y .wait_ack detectó el ACK sin espera.

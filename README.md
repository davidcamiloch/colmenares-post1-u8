# colmenares-post1-u8

Laboratorio del Post-contenido de la Unidad 8 (Operaciones con Cadenas y Aritmética) de Arquitectura de Computadores, UFPS. Autor: David Camilo Colmenares Hernández.

La Parte 1 usa las instrucciones de cadena del 8086 (REP MOVSB y MOVSW, REPNE SCASB, REPE CMPSB, LODSB y STOSB) para copiar, buscar, comparar y transformar cadenas. La Parte 2 usa ADC y SBB para aritmética de 32 bits, DAA y DAS para BCD empaquetado, MUL, DIV y AAM para una calculadora de un dígito, y AAA y AAS para BCD desempaquetado.

## Entorno

- DOSBox 0.74-3 con la carpeta del laboratorio montada como unidad D:.
- NASM 3.02 para DOS con CWSDPMI como servidor DPMI.
- DEBUG 2.51 (proyecto DOS-debug), porque DOSBox 0.74 no incluye DEBUG.

```
D:\> nasm -f bin post1.asm -o post1.com
D:\> post1
```

`COMPILA.BAT` ensambla los nueve programas en una sola orden.


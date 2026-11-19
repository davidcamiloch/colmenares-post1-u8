; post1b.asm - REP MOVSW + MOVSB: copia optimizada por palabras
; Compilar: nasm -f bin post1b.asm -o post1b.com
ORG 100h

LONG_CAD equ 13

section .data
  origen  db "HOLA, MUNDO!",0
  destino db LONG_CAD dup(0), "$"
  msgCop  db "Copiado con MOVSW: $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax
  mov si, origen
  mov di, destino
  mov cx, LONG_CAD
  cld

  mov ax, cx                        ; guardar la longitud original
  shr cx, 1                         ; CX = 13 / 2 = 6 palabras
  rep movsw                         ; copia 12 bytes en 6 iteraciones
  and ax, 1                         ; queda un byte impar?
  jz  .mostrar
  movsb                             ; copia el byte 13
.mostrar:
  mov ah, 09h
  mov dx, msgCop
  int 21h
  mov dx, destino
  int 21h
  mov dx, crlf
  int 21h

  mov ah, 4Ch
  xor al, al
  int 21h

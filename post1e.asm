; post1e.asm - LODSB + STOSB: copia con transformacion a mayusculas
; Compilar: nasm -f bin post1e.asm -o post1e.com
; Desviacion de la guia: destino lleva un "$" final para que INT 21h/09h se detenga.
ORG 100h

LONG_CAD equ 13
DIF_MAY  equ 20h                    ; distancia entre 'a' y 'A'

section .data
  origen  db "hola, mundo!",0
  destino db LONG_CAD dup(0), "$"
  msgCop  db "Transformado: $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax
  mov si, origen
  mov di, destino
  mov cx, LONG_CAD
  cld

.bucle:
  lodsb                             ; AL = [DS:SI], SI + 1
  cmp al, "a"
  jb  .escribir                     ; menor que 'a': se copia igual
  cmp al, "z"
  ja  .escribir                     ; mayor que 'z': se copia igual
  sub al, DIF_MAY                   ; 'a'..'z' -> 'A'..'Z'
.escribir:
  stosb                             ; [ES:DI] = AL, DI + 1
  loop .bucle

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

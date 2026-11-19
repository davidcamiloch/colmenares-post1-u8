; post1d.asm - REPE CMPSB: comparar cadenas de 8 caracteres
; Compilar: nasm -f bin post1d.asm -o post1d.com
ORG 100h

LONG_CMP equ 8                      ; las tres cadenas miden 8 caracteres

section .data
  cad1    db "NASM x86",0
  cad2    db "NASM x86",0
  cad3    db "NASM ARM",0
  msgIg   db "Iguales.$"
  msgDif  db "Diferentes. Primera diferencia en posicion $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax

  mov si, cad1
  mov di, cad2
  call comparar
  mov si, cad1
  mov di, cad3
  call comparar

  mov ah, 4Ch
  xor al, al
  int 21h

; comparar: DS:SI y ES:DI apuntan a las cadenas
comparar:
  mov bx, si                        ; inicio de la primera cadena
  mov cx, LONG_CMP
  cld
  repe cmpsb                        ; sigue mientras sean iguales y CX != 0
  je  .iguales                      ; ZF = 1: los 8 bytes coinciden

  mov ah, 09h
  mov dx, msgDif
  int 21h
  sub si, bx                        ; SI quedo despues del byte distinto
  dec si                            ; posicion base 0 de la diferencia
  mov dx, si
  add dl, "0"
  mov ah, 02h
  int 21h
  jmp .salto
.iguales:
  mov ah, 09h
  mov dx, msgIg
  int 21h
.salto:
  mov ah, 09h
  mov dx, crlf
  int 21h
  ret

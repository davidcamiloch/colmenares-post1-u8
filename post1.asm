; post1.asm - REP MOVSB: copia de una cadena de 13 bytes
; Compilar: nasm -f bin post1.asm -o post1.com
; Desviacion de la guia: destino lleva un "$" despues de sus 13 bytes para que
; INT 21h/09h se detenga alli y no siga imprimiendo los mensajes siguientes.
ORG 100h

LONG_CAD equ 13                     ; 12 caracteres + terminador nulo

section .data
  origen  db "HOLA, MUNDO!",0
  destino db LONG_CAD dup(0), "$"
  msgCop  db "Copiado: $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  ; En un .COM DS = ES, pero se carga ES de forma explicita
  mov ax, ds
  mov es, ax

  mov si, origen                    ; DS:SI = fuente
  mov di, destino                   ; ES:DI = destino
  mov cx, LONG_CAD                  ; CX = bytes a copiar
  cld                               ; DF = 0: SI y DI aumentan
  rep movsb                         ; copia CX bytes

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

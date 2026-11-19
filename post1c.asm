; post1c.asm - REPNE SCASB: buscar un caracter en una cadena
; Compilar: nasm -f bin post1c.asm -o post1c.com
; Desviaciones de la guia: la cadena mide 28 caracteres (no 29) y la "d" esta
; en la posicion 13, asi que la posicion se imprime con dos digitos usando AAM.
ORG 100h

BUSCAR  equ "d"                     ; caracter buscado
BUSCAR2 equ "z"                     ; caracter que no existe

section .data
  cadena  db "Arquitectura de Computadores",0
  longCad equ $ - cadena - 1        ; 28: longitud sin el nulo
  msgHall db "Hallado en posicion: $"
  msgNoH  db "No encontrado.$"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ax, ds
  mov es, ax

  mov al, BUSCAR
  call buscar
  mov al, BUSCAR2
  call buscar

  mov ah, 4Ch
  xor al, al
  int 21h

; buscar: AL = caracter. Imprime su posicion base 0 o "No encontrado."
buscar:
  mov di, cadena                    ; ES:DI recorre la cadena
  mov cx, longCad
  cld
  repne scasb                       ; repite mientras AL != [ES:DI] y CX != 0
  jne .noHallado                    ; ZF = 0: se agoto CX sin coincidencia

  mov bx, di                        ; DI quedo un byte despues del hallazgo
  sub bx, cadena
  dec bx                            ; posicion base 0

  mov ah, 09h
  mov dx, msgHall
  int 21h
  mov al, bl
  aam                               ; AH = decenas, AL = unidades
  mov bx, ax
  mov dl, bh
  add dl, "0"
  mov ah, 02h
  int 21h
  mov dl, bl
  add dl, "0"
  int 21h
  jmp .salto

.noHallado:
  mov ah, 09h
  mov dx, msgNoH
  int 21h
.salto:
  mov ah, 09h
  mov dx, crlf
  int 21h
  ret

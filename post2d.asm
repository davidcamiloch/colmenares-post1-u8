; post2d.asm - AAA y AAS: BCD desempaquetado (un digito por byte)
; Compilar: nasm -f bin post2d.asm -o post2d.com
; Desviacion de la guia: AH se pone en 0 antes de AAA. Tras INT 21h/09h AH vale 09h
; y AAA le suma 1; sin limpiarlo la decena se imprimiria como ':' (30h + 0Ah).
ORG 100h

ASCII_0 equ 30h

section .data
  msgSuma  db "AAA: 7 + 8 = $"
  msgResta db 0Dh,0Ah,"AAS: 13 - 8 = $"
  crlf     db 0Dh,0Ah,"$"

section .text
start:
  mov ah, 09h
  mov dx, msgSuma
  int 21h

  mov ax, 0007h                     ; AH = 0 (decenas), AL = 7
  add al, 08h                       ; AL = 0Fh: no es un digito valido
  aaa                               ; AH = 01h, AL = 05h, CF = 1
  call imprimirAHAL                 ; "15"

  mov ah, 09h
  mov dx, msgResta
  int 21h

  mov ax, 0103h                     ; "13" desempaquetado: AH = 1, AL = 3
  sub al, 08h                       ; AL = FBh: hay prestamo
  aas                               ; AH = 00h, AL = 05h, CF = 1
  call imprimirAHAL                 ; "05"

  mov ah, 09h
  mov dx, crlf
  int 21h
  mov ah, 4Ch
  xor al, al
  int 21h

; imprimirAHAL: decena en AH y unidad en AL
imprimirAHAL:
  push ax
  mov dl, ah
  add dl, ASCII_0
  mov ah, 02h
  int 21h
  pop ax
  mov dl, al
  add dl, ASCII_0
  mov ah, 02h
  int 21h
  ret

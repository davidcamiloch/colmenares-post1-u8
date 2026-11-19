; post2c.asm - Calculadora de un digito con MUL, DIV y AAM
; Compilar: nasm -f bin post2c.asm -o post2c.com
; Desviacion de la guia: el resultado de MUL (0 a 81) se convierte con AAM y el
; programa tambien imprime el resto de la division. La etiqueta pOp de la guia
; choca con la instruccion POP (NASM no distingue mayusculas) y se renombro pOper.
ORG 100h

ASCII_0 equ 30h
OP_MUL  equ "*"
OP_DIV  equ "/"

section .data
  pA     db "Primer operando (0-9): $"
  pB     db 0Dh,0Ah,"Segundo operando (0-9): $"
  pOper    db 0Dh,0Ah,"Operacion (* o /): $"
  msgR   db 0Dh,0Ah,"Resultado: $"
  msgRes db "  resto $"
  msgErr db 0Dh,0Ah,"Division por cero.$"
  msgOp  db 0Dh,0Ah,"Operacion no valida.$"
  crlf   db 0Dh,0Ah,"$"

section .text
start:
  mov ah, 09h
  mov dx, pA
  int 21h
  mov ah, 01h                       ; leer con eco
  int 21h
  sub al, ASCII_0                   ; ASCII -> binario
  mov bl, al                        ; BL = A

  mov ah, 09h
  mov dx, pB
  int 21h
  mov ah, 01h
  int 21h
  sub al, ASCII_0
  mov cl, al                        ; CL = B

  mov ah, 09h
  mov dx, pOper
  int 21h
  mov ah, 01h
  int 21h
  mov bh, al                        ; BH = operador

  cmp bh, OP_MUL
  je  multiplicar
  cmp bh, OP_DIV
  je  dividir
  mov dx, msgOp
  jmp mensaje

multiplicar:
  mov ah, 09h
  mov dx, msgR
  int 21h
  mov al, bl
  mul cl                            ; AX = A * B (maximo 81)
  call imprimir2                    ; AAM separa decenas y unidades
  jmp fin

dividir:
  cmp cl, 0
  jne .ok
  mov dx, msgErr
  jmp mensaje
.ok:
  mov ah, 09h
  mov dx, msgR
  int 21h
  xor ah, ah
  mov al, bl                        ; AX = A
  div cl                            ; AL = cociente, AH = resto
  push ax
  call imprimir2                    ; cociente
  mov ah, 09h
  mov dx, msgRes
  int 21h
  pop ax
  mov al, ah                        ; resto
  call imprimir2
  jmp fin

mensaje:
  mov ah, 09h
  int 21h
fin:
  mov ah, 09h
  mov dx, crlf
  int 21h
  mov ah, 4Ch
  xor al, al
  int 21h

; imprimir2: AL (0 a 99) en decimal; omite el cero de las decenas
imprimir2:
  aam                               ; AH = AL / 10, AL = AL mod 10
  push ax
  cmp ah, 0
  je  .unidad
  mov dl, ah
  add dl, ASCII_0
  mov ah, 02h
  int 21h
.unidad:
  pop ax
  mov dl, al
  add dl, ASCII_0
  mov ah, 02h
  int 21h
  ret

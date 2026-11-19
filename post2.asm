; post2.asm - ADC y SBB: suma y resta de 32 bits en pares de registros DX:AX
; Compilar: nasm -f bin post2.asm -o post2.com
ORG 100h

section .data
  ; A = 0001FFFFh = 131 071;  B = 00010001h = 65 537
  aLo    dw 0FFFFh
  aHi    dw 0001h
  bLo    dw 0001h
  bHi    dw 0001h
  resLo  dw 0
  resHi  dw 0
  msgSum db "Suma OK: $"
  msgRes db 0Dh,0Ah,"Resta OK: $"
  msgErr db "Error.$"
  sep    db ":$"
  crlf   db 0Dh,0Ah,"$"

section .text
start:
  ; ---- Suma: A + B = 00030000h ----
  mov ax, [aLo]
  mov dx, [aHi]
  add ax, [bLo]                     ; FFFFh + 0001h = 0000h, CF = 1
  adc dx, [bHi]                     ; 0001h + 0001h + CF = 0003h
  mov [resLo], ax
  mov [resHi], dx
  cmp ax, 0000h
  jne error
  cmp dx, 0003h
  jne error
  mov ah, 09h
  mov dx, msgSum
  int 21h
  call imprimirRes                  ; 0003:0000

  ; ---- Resta: (A + B) - B = 0001FFFFh ----
  mov ax, [resLo]
  mov dx, [resHi]
  sub ax, [bLo]                     ; 0000h - 0001h = FFFFh, CF = 1 (prestamo)
  sbb dx, [bHi]                     ; 0003h - 0001h - CF = 0001h
  mov [resLo], ax
  mov [resHi], dx
  cmp ax, 0FFFFh
  jne error
  cmp dx, 0001h
  jne error
  mov ah, 09h
  mov dx, msgRes
  int 21h
  call imprimirRes                  ; 0001:FFFF
  jmp fin

error:
  mov ah, 09h
  mov dx, msgErr
  int 21h
fin:
  mov ah, 09h
  mov dx, crlf
  int 21h
  mov ah, 4Ch
  xor al, al
  int 21h

; imprimirRes: muestra resHi:resLo en hexadecimal
imprimirRes:
  mov ax, [resHi]
  call hex16
  mov ah, 09h
  mov dx, sep
  int 21h
  mov ax, [resLo]
  call hex16
  ret

; hex16: imprime AX como 4 digitos hexadecimales
hex16:
  mov cx, 4
.digito:
  rol ax, 1                         ; 4 rotaciones de 1 bit: nibble alto -> bajo
  rol ax, 1
  rol ax, 1
  rol ax, 1
  push ax
  and al, 0Fh
  add al, "0"
  cmp al, "9"
  jbe .imprime
  add al, 7                         ; 'A'..'F'
.imprime:
  mov dl, al
  mov ah, 02h
  int 21h
  pop ax
  loop .digito
  ret

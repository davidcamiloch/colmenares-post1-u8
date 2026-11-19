; post2b.asm - DAA y DAS: suma y resta BCD empaquetada
; Compilar: nasm -f bin post2b.asm -o post2b.com
ORG 100h

BCD_A    equ 47h                    ; "47"
BCD_B    equ 38h                    ; "38"
BCD_MAX  equ 99h                    ; "99"
BCD_UNO  equ 01h                    ; "01"
BCD_M    equ 73h                    ; "73"
BCD_S    equ 28h                    ; "28"
BCD_V    equ 20h                    ; "20"

section .data
  msgSum  db "DAA 47 + 38 = $"
  msgSum2 db 0Dh,0Ah,"DAA 99 + 01 = $"
  msgCF   db "  CF = $"
  msgRes  db 0Dh,0Ah,"DAS 73 - 28 = $"
  msgRes2 db 0Dh,0Ah,"DAS 20 - 01 = $"
  crlf    db 0Dh,0Ah,"$"

section .text
start:
  mov ah, 09h
  mov dx, msgSum
  int 21h
  mov al, BCD_A
  add al, BCD_B                     ; 7Fh: no es BCD valido
  daa                               ; 85h
  call bcd2

  mov ah, 09h
  mov dx, msgSum2
  int 21h
  mov al, BCD_MAX
  add al, BCD_UNO                   ; 9Ah
  daa                               ; 00h y CF = 1
  pushf
  call bcd2
  mov ah, 09h
  mov dx, msgCF
  int 21h
  popf
  mov dl, "0"
  adc dl, 0                         ; '0' + CF
  mov ah, 02h
  int 21h

  mov ah, 09h
  mov dx, msgRes
  int 21h
  mov al, BCD_M
  sub al, BCD_S                     ; 4Bh: no es BCD valido
  das                               ; 45h
  call bcd2

  mov ah, 09h
  mov dx, msgRes2
  int 21h
  mov al, BCD_V
  sub al, BCD_UNO                   ; 1Fh
  das                               ; 19h
  call bcd2

  mov ah, 09h
  mov dx, crlf
  int 21h
  mov ah, 4Ch
  xor al, al
  int 21h

; bcd2: imprime AL como dos digitos BCD empaquetados
bcd2:
  mov bl, al
  mov dl, al
  shr dl, 4                         ; nibble alto = decenas
  add dl, "0"
  mov ah, 02h
  int 21h
  mov dl, bl
  and dl, 0Fh                       ; nibble bajo = unidades
  add dl, "0"
  int 21h
  ret

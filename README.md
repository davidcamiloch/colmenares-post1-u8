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

## Parte 1: Instrucciones de cadena

| Programa | Instrucciones | Registros implícitos | Salida verificada |
|----------|---------------|----------------------|-------------------|
| `post1.asm` | `REP MOVSB` | DS:SI fuente, ES:DI destino, CX = 13 | `Copiado: HOLA, MUNDO!` |
| `post1b.asm` | `REP MOVSW` + `MOVSB` | CX = 13 / 2 = 6 palabras y 1 byte suelto | `Copiado con MOVSW: HOLA, MUNDO!` |
| `post1c.asm` | `REPNE SCASB` | AL = carácter, ES:DI cadena, CX = 28 | `Hallado en posicion: 13` y `No encontrado.` |
| `post1d.asm` | `REPE CMPSB` | DS:SI y ES:DI, CX = 8 | `Iguales.` y `Diferentes. Primera diferencia en posicion 5` |
| `post1e.asm` | `LODSB` + `STOSB` + `LOOP` | AL como dato intermedio | `Transformado: HOLA, MUNDO!` |

Todos los programas copian DS en ES antes de la primera instrucción de cadena y ejecutan `CLD`. DF = 0 hace que SI y DI aumenten tras cada elemento; con DF = 1 retrocederían, que es lo que se usa para copiar regiones solapadas desde el final.

La sesión de DEBUG confirma el estado tras `REP MOVSB` en `post1.com`: SI = 0135h y DI = 0142h, 13 bytes más que sus valores iniciales 0128h y 0135h, y CX = 0. El volcado de 0135h a 0142h muestra `HOLA, MUNDO!`, el byte nulo y el `$` añadido. En `post1c.com` la búsqueda de `d` deja CX = 000Eh y DI = 0162h; la posición es 0162h − 0154h − 1 = 13.

### Desviaciones respecto a la guía

- `post1.asm` y `post1e.asm`: el búfer `destino` no tenía terminador `$`. INT 21h/09h imprime hasta encontrar un `$`, así que después de la cadena copiada mostraba también el texto de `msgCop`. Se añadió `"$"` después de los 13 bytes.
- `post1c.asm`: `Arquitectura de Computadores` mide 28 caracteres y no 29; `longCad` ahora se calcula con `$ - cadena - 1`. La primera `d` está en la posición 13 (base 0) y no en la 4 que indica la guía. Como la guía imprimía un solo dígito, la posición se convierte con `AAM` en decenas y unidades.
- `post1d.asm`: la primera diferencia entre `NASM x86` y `NASM ARM` está en la posición 5 (base 0), es decir en el sexto carácter, porque `NASM ` ocupa cinco. El programa imprime esa posición a partir de SI.
- `post1b.asm` conserva la versión con `MOVSW` del Paso 2 en un archivo propio para que `post1.asm` siga mostrando la versión con `MOVSB`.

### Decisión técnica 1: REP MOVSB o un bucle manual con LODSB y STOSB

Para una copia sin transformación REP MOVSB es la opción correcta. El prefijo REP convierte la copia en un bucle interno del procesador: la instrucción se decodifica una vez y el microcódigo repite la transferencia mientras CX no sea cero. El bucle de `post1e.asm` paga en cada byte la búsqueda y decodificación de LODSB, dos comparaciones con sus saltos condicionales, STOSB y LOOP; son seis instrucciones por byte frente a una sola instrucción para toda la copia. En el listado, `rep movsb` ocupa 2 bytes (F3h A4h) y el cuerpo del bucle de `post1e.asm` ocupa 14. Aun así, `post1e.asm` tuvo que abandonar REP MOVSB porque esa instrucción mueve el byte de DS:SI a ES:DI sin pasar por ningún registro visible; no existe un punto donde el programa pueda examinar el carácter y restarle 20h. LODSB deja el byte en AL, el programa decide y STOSB lo escribe. Si el laboratorio tuviera que copiar una cadena larga sin cambiarla, REP MOVSB seguiría siendo preferible; y para cadenas largas de longitud par `REP MOVSW` reduce las iteraciones a la mitad, como muestra `post1b.asm` con 6 palabras y un byte suelto en lugar de 13 bytes. La regla es usar REP para mover y el bucle manual solo cuando cada byte necesita una decisión.

### Decisión técnica 2: CX fijo o verificación manual del terminador

REPE CMPSB y REPNE SCASB no conocen el byte nulo; solo se detienen por CX = 0 o por la condición de ZF. Si se comparan dos cadenas de 5 y 8 caracteres con CX = 8, la instrucción compara los 5 caracteres, compara el nulo de la cadena corta con el sexto carácter de la larga y, si casualmente coincidieran, seguiría leyendo los bytes que estén en memoria después de ese nulo: el siguiente mensaje, otra variable o código. El resultado dependería de esa memoria ajena; dos cadenas distintas podrían declararse iguales o la diferencia se reportaría en una posición sin sentido. Para longitudes desconocidas el bucle de `post1e.asm` se adapta así:

```
comparar:
  lodsb                 ; AL = carácter de la cadena 1, SI + 1
  mov  ah, [es:di]      ; AH = carácter de la cadena 2
  inc  di
  cmp  al, ah
  jne  distintas        ; primera diferencia
  test al, al
  jnz  comparar         ; si AL = 0, ambas terminaron juntas
iguales:
```

El bucle termina en el primer nulo de cualquiera de las dos cadenas: si solo una llegó al nulo los caracteres difieren y salta a `distintas`; si ambas llegan a la vez son iguales. En `post1d.asm` el CX = 8 fijo es correcto porque `cad1`, `cad2` y `cad3` son literales de exactamente 8 caracteres conocidos en tiempo de ensamblado; la constante `LONG_CMP` documenta esa suposición. La regla es usar CX fijo solo cuando el ensamblador conoce la longitud y verificar el terminador en todos los demás casos.

## Parte 2: Aritmética de precisión múltiple y BCD

| Programa | Instrucciones | Salida verificada |
|----------|---------------|-------------------|
| `post2.asm` | `ADD` + `ADC`, `SUB` + `SBB` sobre DX:AX | `Suma OK: 0003:0000` y `Resta OK: 0001:FFFF` |
| `post2b.asm` | `ADD` + `DAA`, `SUB` + `DAS` | `47 + 38 = 85`, `99 + 01 = 00 CF = 1`, `73 - 28 = 45`, `20 - 01 = 19` |
| `post2c.asm` | `MUL`, `DIV`, `AAM` | `7 * 8 = 56`, `9 / 4 = 2 resto 1`, `Division por cero.` |
| `post2d.asm` | `ADD` + `AAA`, `SUB` + `AAS` | `AAA: 7 + 8 = 15` y `AAS: 13 - 8 = 05` |

En `post2.asm` el acarreo es el único enlace entre las dos mitades. `FFFFh + 0001h` deja la parte baja en 0000h y CF = 1; `ADC` suma ese bit a las partes altas: 0001h + 0001h + 1 = 0003h. En la resta `0000h − 0001h` deja FFFFh con CF = 1 como préstamo y `SBB` lo descuenta: 0003h − 0001h − 1 = 0001h. DEBUG lo confirma: tras el ADC, AX = 0000 y DX = 0003; tras el SBB, AX = FFFF y DX = 0001.

En BCD empaquetado cada nibble guarda un dígito decimal. `47h + 38h` da 7Fh en binario; el nibble bajo F supera 9, así que DAA suma 6 y obtiene 85h. `99h + 01h` da 9Ah; DAA suma 6 al nibble bajo y 60h al byte y deja 00h con CF = 1, el acarreo hacia el siguiente byte BCD. `post2b.asm` imprime ese CF sumándolo a `'0'` con `ADC`.

En BCD desempaquetado cada byte guarda un dígito en el nibble bajo y AH recibe el acarreo. Tras `07h + 08h = 0Fh`, AAA deja AH = 01h y AL = 05h con CF = 1. Tras `03h − 08h = FBh`, AAS deja AH = 00h y AL = 05h. DEBUG muestra AX = 0105 y AX = 0005 con CY.

### Desviaciones respecto a la guía

- `post2.asm` reúne la suma del Paso 1 y la resta del Paso 2 e imprime los resultados reales en hexadecimal con una subrutina `hex16`, en lugar de un texto fijo.
- `post2b.asm` incluye también la resta con DAS del Paso 4 y el caso `99 + 01` que la guía pide probar.
- `post2c.asm`: la etiqueta `pOp` de la guía no ensambla en NASM porque se confunde con la instrucción `POP`; NASM no distingue mayúsculas en los nombres de instrucción. Se renombró `pOper`. El resultado se convierte con `AAM`, como pide la rúbrica, y la división imprime también el resto.
- `post2d.asm`: la guía ejecuta AAA sin limpiar AH. Después de `INT 21h/09h`, AH sigue en 09h y AAA lo incrementa a 0Ah; la decena se imprimiría como `:` (30h + 0Ah = 3Ah). Se carga `AX = 0007h` antes de la suma y `AX = 0103h` antes de la resta, que representa `13` desempaquetado.

### Decisión técnica 3: DAA y DAS o AAA y AAS según el formato

La instrucción de ajuste depende del formato del dato y no de la operación. DAA y DAS trabajan sobre BCD empaquetado: examinan el nibble bajo de AL y AF y después el byte completo con CF, porque cada nibble es un dígito. AAA y AAS trabajan sobre BCD desempaquetado: solo corrigen el nibble bajo, ponen en cero el nibble alto y llevan el acarreo a AH. Aplicar AAA a un byte empaquetado 47h destruye las decenas; aunque no haya ajuste, AAA limpia el nibble alto y el 4 desaparece, y el resultado queda en 07h. La calculadora de `post2c.asm` lee cada dígito con INT 21h/01h y le resta 30h; el resultado es un dígito desempaquetado con el nibble alto en cero. Si sumara dos dígitos así, la instrucción correcta sería AAA: tras `07h + 08h = 0Fh` deja AH = 01h y AL = 05h, el 15 en dos bytes listos para sumarles 30h e imprimirlos. DAA sobre 0Fh también produce 15h, pero lo deja empaquetado en un solo byte y CF no se activa; la decena no pasa a AH y el código de impresión de un dígito por byte mostraría el carácter 45h (`E`) en lugar de `1` y `5`. La regla es DAA y DAS para dos dígitos por byte y AAA y AAS para un dígito por byte.

### Decisión técnica 4: ADC fijo o una cadena de ADC en bucle

`post2.asm` suma 32 bits con dos instrucciones porque el número cabe en DX:AX. Para N palabras el patrón se generaliza recorriendo de la palabra de menor peso a la de mayor peso:

```
  mov  si, numA          ; palabra menos significativa primero
  mov  di, numB
  mov  bx, res
  mov  cx, N
  clc                    ; no hay acarreo antes de la primera palabra
sumar:
  mov  ax, [si]
  adc  ax, [di]          ; suma + CF de la palabra anterior
  mov  [bx], ax
  inc  si                ; INC y LOOP no modifican CF
  inc  si
  inc  di
  inc  di
  inc  bx
  inc  bx
  loop sumar
```

La primera palabra no tiene acarreo previo: en el código fijo se usa ADD; en el bucle se obtiene el mismo efecto con CLC antes de entrar, de modo que el primer ADC suma un CF igual a cero. Todas las palabras siguientes deben usar ADC porque el CF que dejó la palabra anterior es justamente el acarreo que hay que incorporar; con ADD se perdería y el resultado quedaría corto en 10000h por cada acarreo perdido. Dentro del bucle solo pueden usarse instrucciones que no toquen CF entre dos ADC; por eso los punteros avanzan con INC y no con ADD. El bucle es más mantenible: cambiar de 32 a 128 bits es cambiar N, y la misma rutina sirve como base de un tipo bignum. El precio es rendimiento; cada palabra paga ocho instrucciones de control además del ADC, igual que el bucle LODSB y STOSB de la Parte 1 paga por su flexibilidad frente a REP MOVSB. La regla es código fijo cuando el tamaño es conocido y pequeño, y bucle con ADC cuando la precisión es variable.

## Capturas

| Captura | Contenido |
|---------|-----------|
| `capturas/p1-compilacion.png` | Ensamblado de los nueve programas y sus tamaños |
| `capturas/p1-cp1-cp5-ejecucion.png` | Salidas de post1, post1b, post1c, post1d y post1e |
| `capturas/p1-debug-movsb-scasb.png` | SI, DI y CX tras REP MOVSB, volcado de `destino` y estado tras REPNE SCASB |
| `capturas/p2-cp1-cp4-cp6-ejecucion.png` | Salidas de post2, post2b y post2d |
| `capturas/p2-cp5-calculadora.png` | Calculadora: 7 * 8, 9 / 4 y división por cero |
| `capturas/p2-debug-adc-sbb-aaa-aas.png` | DX:AX tras ADC y SBB, AX tras AAA y AAS |

## Referencias

- Cloutier, F. (s.f.). *x86 and amd64 instruction reference*. https://www.felixcloutier.com/x86/
- NASM Development Team. (s.f.). *NASM — The Netwide Assembler: documentación*. https://www.nasm.us/doc/
- Intel BCD opcodes. (s.f.). En *Wikipedia*. https://en.wikipedia.org/wiki/Intel_BCD_opcodes

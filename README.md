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


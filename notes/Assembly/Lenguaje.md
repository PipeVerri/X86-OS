Para escribir se puede tipear asi nomas, pero es mejor ponerle labels asi puedo hacer jmp
```
main: // Marker de la direccion de memoria del codigo
	jmp main
```

# Instrucciones
Una instruccion es algo que se traduce y ejecuta como codigo maquina

- `hlt`: frena el CPU, hay veces que no anda asi que la gente le pone un loop
- `jmp`: un goto
# Directivas
Una directiva es algo que le ayuda al assembler a interpretar, como si fuera un #DEFINE en C

- `ORG <address>`: Desde que punto, que offset, empiezo a escribir en la memoria RAM
- `bits <16|32|64>`: De cuantos bits emitir el codigo, que bits emular(si quiero hacer un programa para un CPU de 16 bits pero lo corro en uno de 64, hago `bits 16`)
- `TIMES <numero> <instruccion/datos>`: Cuantas veces repite la instruccion
- `db <byte`: escribe un byte en el programa
- `dw <word1>, <word2>...`: Define un word de 2 bytes **y espera que este encodeado como little endian**(al reves)
# Variables especiales
- `$`: El memory offset de la linea actual
- `$$`: El offset de la seccion actual
# Sintaxis
- Para words en hexadecimal, si el codigo fuera 0x1234, se escribiria como `01234h`(o `04321h`en little endian)
org 0x7c00  ; Empezar con este offset en la RAM
bits 16

%define ENDL 0x0D, 0x0A ; Macro para el newline

main:
    ; Inicializar DS
    mov ax, 0
    mov ds, ax ; No puedo escribirle un numero directamente
    ; Inicializar stack
    mov ss, ax ; Limpiar el stack para que no vaya a cualquier lado
    mov sp, 0x7c00  ; El stack es decremental y last-in-first-out, por ahora me alcanza el espacio
    
    ; Llamar la funcion
    mov si, msg ; Seteo el offset en vez de DS ya que msg de escribe en DS al declararlo
    call print

.stop:
    cli
    hlt
    jmp .stop    


; Imprime a consola
print:
    ; Setup del bios
    mov bh, 0
    ; Guarda los registros a modificar en el stack
    push si
    push ax
    jmp .loop

.loop:
    lodsb   ; Carga el word en DS:SI en AX e incrementa SI para que DS:SI sea el siguiente word
    or al, al   ; No modifica el caracter, pero si es nulo(todo 0) entonces setea ZF=1
    jz .done   ; Salta a done si ZF=1

    ; Imprimir el caracter
    mov ah, 0x0e
    int 0x10

    jmp .loop

.done:
    ; Retorna los valores de si y ax
    pop ax
    pop si
    ret

msg: db 'Hello', ENDL, 0   ; Termino con el 0 para que no quede basura y siga imprimiendo

times 510-($-$$) db 0 ; Un padding de 0s de 510 bytes - los usados para el programa
dw 0AA55h ; El tag. Escrito asi porque NASM no entiende hexadecimal cuando empieza con una letra, y al reves por little endian

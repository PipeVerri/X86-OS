org 0x0000
bits 16

main:
    mov ax, 0x1000
    mov ds, ax
    mov si, success_msg
    call print
halt:
    hlt
    jmp halt

; Imprime a consola
; Argumentos:
;   - SI: la direccion del string
print:
    ; Setup del bios
    mov bh, 0
    mov ah, 0x0E
    ; Guarda los registros a modificar en el stack
    push si
    push ax
    jmp .loop
.loop:
    lodsb   ; Carga el byte en DS:SI en AL e incrementa SI para que DS:SI sea el siguiente byte
    or al, al   ; No modifica el caracter, pero si es nulo(todo 0) entonces setea ZF=1
    jz .done   ; Salta a done si ZF=1

    int 0x10
    jmp .loop
.done:
    ; Retorna los valores de si y ax
    pop ax
    pop si
    ret

success_msg:    db 'Kernel cargado', 0
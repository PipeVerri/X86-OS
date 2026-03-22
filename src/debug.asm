; Imprime un solo byte
; Argumentos
; - al: el byte
print_hex:
    push ax
    ; Setup bios
    mov bh, 0
    mov ah, 0x0E
    ; Copia
    mov bl, al
    ; Parte alta
    and al, 0xF0
    shr al, 4
    call .print_hex_digit
    ; Parte baja
    mov al, bl
    and al, 0x0F
    call .print_hex_digit
    ; Retorno
    pop ax
    ret
.print_hex_digit:
    cmp al, 10 ; Fijarme si es menor a 10
    jl .print_digit ; Si es menor, saltar aca
    jmp .print_letter
.print_digit:
    add al, '0' ; Convertirlo a ASCII
    int 0x10
    ret
.print_letter:
    add al, 'A' - 10 ; Convertirlo a ASCII
    int 0x10
    ret


; Debugging de la conversion
debug_lba_to_chs:
    mov ax, 2879
    call lba_to_chs
    mov si, newline
    
    mov al, ch
    call print_hex
    call print
    
    mov al, cl
    call print_hex
    call print

    mov al, dh
    call print_hex
    call print

    jmp stop
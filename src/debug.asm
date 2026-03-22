; Print a single byte
; Arguments
; - al: the byte
print_hex:
    push ax
    ; BIOS setup
    mov bh, 0
    mov ah, 0x0E
    ; Copy
    mov bl, al
    ; High part
    and al, 0xF0
    shr al, 4
    call .print_hex_digit
    ; Low part
    mov al, bl
    and al, 0x0F
    call .print_hex_digit
    ; Return
    pop ax
    ret
.print_hex_digit:
    cmp al, 10 ; Check if less than 10
    jl .print_digit ; If less, jump here
    jmp .print_letter
.print_digit:
    add al, '0' ; Convert to ASCII
    int 0x10
    ret
.print_letter:
    add al, 'A' - 10 ; Convert to ASCII
    int 0x10
    ret


; Debug the conversion
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
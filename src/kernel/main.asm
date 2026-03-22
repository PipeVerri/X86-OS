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

; Print to console
; Arguments:
;   - SI: the string address
print:
    ; BIOS setup
    mov bh, 0
    mov ah, 0x0E
    ; Save registers to be modified on the stack
    push si
    push ax
    jmp .loop
.loop:
    lodsb   ; Load the byte at DS:SI into AL and increment SI so DS:SI points to the next byte
    or al, al   ; Does not modify the character, but if it's null (all 0) it sets ZF=1
    jz .done   ; Jump to done if ZF=1

    int 0x10
    jmp .loop
.done:
    ; Restore si and ax values
    pop ax
    pop si
    ret

success_msg:    db 'Kernel cargado', 0
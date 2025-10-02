org 0x7c00  ; Empezar con este offset en la memoria
bits 16

;
; Headers FAT12
;
jmp short main ; Salto a main, ocupa 2 bytes(por eso el short) 
nop

bpb_oem:                 db 'MSWIN4.1'   ; Version de DOS, solo por compatibilidad
bpb_bytes_per_sector:    dw 512
bpb_sectors_per_cluster: db 1
bpb_reserved_sectors:    dw 1            ; Los sectores usados para un segundo (futuro) bootloader
bpb_fat_number:          db 2            ; El numero de copias de la tabla FAT, 2 por redundancia
bpb_root_dir_count:      dw 224          ; El root directory solo ocupa un sector, asi que solo puede tener 224 entradas(de 32b cada una)
bpb_sector_count:        dw 2880         ; Num de sectores en el disco
bpb_media_descriptor:    db 0F0h         ; Disco de 3.5 pulgadas doble lado
bpb_sectors_per_fat:     dw 9            ; Cuantos sectores ocupo por tabla
bpb_sectors_per_track:   dw 18           ; Estandar del floppy de 1.44MiB
bpb_heads_number:        dw 2
bpb_hidden_sectors:      dd 0            ; Para cuando se usa un disco duro en vez de un floppy
bpb_large_sector_count:  dd 0
; Extended boot record
ebpb_drive_number:       db 0            ; 0x00 para floppy, 0x80 para HDD
                         db 0            ; Reservado
ebpb_signature:          dw 28h
                         dd 0            ; Ignorado
ebpb_label:              db 'label      '; 11 bytes, paddding con espacios
ebpb_system_id:          db 'FAT-12  '   ; 8 bytes

; Macros
%define ENDL 0x0D, 0x0A ; Macro para el newline

; Boot code
main:
    ; Inicializar segmentos
    mov ax, 0
    mov ds, ax
    ; ES
    mov ax, 0x1000 ; Offset de 64kb
    mov es, ax
    ; SS
    mov ax, 0
    mov ss, ax
    mov sp, 0x7c00  ; El stack es decremental y last-in-first-out, por ahora me alcanza el espacio
    
    ; Llamar la funcion de print
    mov si, msg_test ; Seteo el offset en vez de DS ya que msg de escribe en DS al declararlo
    call print

    ; Intentar leer del floppy
    mov bl, 1  ; Numero de sectores
    mov ax, 33 ; Segundo sector del disco
    call read_floppy

    ; Imprimir la lectura de ES:BX
    mov al, [es:bx]
    call print_hex

; hlt generalmente no funciona bien, por eso pongo un loop
stop:
    hlt
    jmp stop

; Leer un floppy
; Argumentos:
;  - ax: LBA address
;  - bl: Numero de sectores
; Retorna:
;  - ES:BX los datos
read_floppy:
    call lba_to_chs ; Empiezo seteando el address CHS
    ; Stack
    push ax
    push bx
    ; BIOS
    mov ah, 2
    mov al, bl
    mov dl, [ebpb_drive_number]
    int 0x13
    ; Fijarme si fallo
    jc .failed_floppy
    ; Retorno
    mov si, msg_read_success
    call print
    pop bx
    pop ax
    ret
.failed_floppy:
    mov si, msg_read_failed
    call print
    jmp stop

; Conversion de direcciones
; Argumentos:
;  - ax: LBA address
; Retorna:
;  - ch: 8 bits bajos del cilindro
;  - cl: 6 bits del sector y los 2 bits altos del cilindro
;  - dh: head
lba_to_chs:
    ; Stack
    push ax
    push bx
    
    ; Calculo del cilindro    
    mov dx, 0   ; Seteo en 0 el resto
    mov bx, [bpb_sectors_per_track] ; El divisor
    div bx  ; ax = ax / bx, dx = ax % bx
    inc dx
    mov cl, dl ; Luego hago el OR y le pongo los ultimos 2 bits del cilindro
    and cl, 0b00111111 ; Limpiar los residuos de los ultimos 2 bits altos
    
    ; Calculo del cabezal
    mov dx, 0
    mov bx, [bpb_heads_number]
    div bx ; ax = ax / bx, dx = ax % bx
    mov dh, dl
    
    ; Calculo del sector
    mov ch, al ; Los 8 bits altos
    shl ah, 6 ; Pongo los 2 ultimos bits del cilindro en el final de ah
    or cl, ah ; Pongo los 2 ultimos bits en cl

    ; Returno al stack
    pop bx
    pop ax
    ret

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

msg_test:   db 'Booting', ENDL, 0
msg_read_failed: db 'Lectura fallida', ENDL, 0   ; Termino con el 0 para que no quede basura y siga imprimiendo. Lo declaro al final para que no lo lea como codigo
msg_read_success: db 'Lectura correcta', ENDL, 0
newline: db ENDL, 0

; Padding y signature MBR
times 510-($-$$) db 0 ; Un padding de 0s de 510 bytes - los usados para el programa
dw 0AA55h ; El tag. Escrito asi porque NASM no entiende hexadecimal cuando empieza con una letra, y al reves por little endian

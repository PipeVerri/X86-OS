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
ebpb_drive_numer:        dw 0            ; 0x00 para floppy, 0x80 para HDD
                         db 0            ; Reservado
ebpb_signature:          dw 28h
                         dd 0            ; Ignorado
ebpb_label:              db 'label      '; 11 bytes, paddding con espacios
ebpb_system_id:          db 'FAT-12  '   ; 8 bytes

; Macros
%define ENDL 0x0D, 0x0A ; Macro para el newline

; Boot code
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

; hlt generalmente no funciona bien, por eso pongo un loop
.stop:
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
    lodsb   ; Carga el word en DS:SI en AL e incrementa SI para que DS:SI sea el siguiente byte
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

msg: db 'Cremoso de mierda', ENDL, 0   ; Termino con el 0 para que no quede basura y siga imprimiendo. Lo declaro al final para que no lo lea como codigo

; Padding y signature MBR
times 510-($-$$) db 0 ; Un padding de 0s de 510 bytes - los usados para el programa
dw 0AA55h ; El tag. Escrito asi porque NASM no entiende hexadecimal cuando empieza con una letra, y al reves por little endian

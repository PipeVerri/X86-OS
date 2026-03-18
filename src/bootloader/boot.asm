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
    mov ax, 0x7e00
    mov es, ax
    ; SS
    mov ax, 0
    mov ss, ax
    mov sp, 0x7c00  ; El stack es decremental y last-in-first-out, por ahora me alcanza el espacio
    
    ; Llamar la funcion de print
    mov si, msg_test ; Seteo el offset en vez de DS ya que msg de escribe en DS al declararlo
    call print

    call load_kernel

stop: ; hlt generalmente no funciona bien, por eso pongo un loop
    hlt
    jmp stop

load_kernel:
    ; Fijarme en que cluster esta el kernel
    call get_kernel_cluster
    mov dx, ax ; Pongo el cluster inicial en DX temporalmente
    ; Empiezo cargando la tabla FAT EN 0x7e00
    ; Inicializo ES:BX
    mov ax, 0x7e00
    mov es, ax
    mov bx, 0
    ; Lo cargo
    mov ax, [bpb_reserved_sectors] ; Empezar del bootloader para arriba
    mov cl, [bpb_sectors_per_fat]
    call read_floppy
    ; Ahora quiero cargar el kernel en 0x1000
    mov ax, 0x1000
    mov es, ax
    mov bx, 0
    ; Y quiero poder acceder a la tabla FAT desde FS:SI
    mov ax, 0x7e00
    mov fs, ax
    mov si, 0
    ; Poner ax el LBA del cluster inicial
    mov ax, dx
    add ax, 31 ; sector_oculto + sectores_FAT * 2 + sectores_root - 2(porque los 2 primeros clusters son metadata, no son registros posta)
    mov cl, [bpb_sectors_per_cluster]
    call read_floppy
    .loop_load_kernel_1:
        ; Extraer el registro actual de la tabla FAT
        mov si, dx
        shr si, 4 ; SI = n / 2
        add si, dx ; SI = n + n/2 = n * 1.5
        ; Me fijo si extraigo la parte baja o alta del word
        test dx, 1 ; Bitwise AND sin modificar DX, solo los flags
        mov dx, [fs:si] ; Cargar el nuevo registro
        jz .even_n
    .odd_n:
        and dx, 0x0FFF ; Tomar los 12 bits altos
        jmp .loop_load_kernel_2
    .even_n:
        shr dx, 4 ; Tomar los 12 bits bajos
    .loop_load_kernel_2:
        ; Fijarme si es EOF o seguir leyendo
        cmp dx, 0xFF8
        jae .return ; Saltar si >=
        ; Cargar el nuevo cluster en RAM
        mov ax, dx
        add ax, 31 ; Cluster -> LBA
        add bx, 512 ; Sumarle el offset asi no sobre-escribe la lectura anterior
        mov cl, [bpb_sectors_per_cluster]
        call read_floppy
        jmp .loop_load_kernel_1
    .return:
        jmp 0x1000:0x0000

; Retorna:
; - AX: el cluster inicial donde se encuentra el kernel
get_kernel_cluster:
    ; Calcular donde empieza el sector de la tabla FAT root(hardcodeado por ahora)
    mov ax, 19 ; sector reservado del kernel + (9 * 2) sectores de tablas FAT(es zero-index el LBA)
    mov cl, 14 ; La tabla FAT root mide 14 sectores(numero de archivos * 32 bits / 512b de sectores)
    mov bx, 0
    ; Leer el floppy
    call read_floppy
    ; Fijarme donde esta el kernel
    mov cx, [bpb_root_dir_count]
    mov si, kernel_name
    call find_file_start_cluster
    ret
; Argumentos
; - ES:BX el directorio cargado
; - DS:SI el nombre de archivo que quiero(en el formato FAT)
; - cx la cantidad de archivos en el directorio
; Retorna
; - AX el cluster de memoria en el que esa
find_file_start_cluster:
    ; Stack
    push bx
    push cx
    push dx
    push si

    cld ; Que el direction flag sea 0 para que vaya comparando moviendo DI y SI hacia adelante
.read_register_loop:
    ; Checkear el titulo
    mov di, bx ; CMBSP usa DI
    mov cx, 11
    push si
    repe cmpsb ; Repetir mientras ZF=1(van coincidiendo)
    pop si
    jz .equal_names
    ; Si no son iguales, decrementar dx y fijarme si me pase
    dec dx
    je .stop ; Si es 0, frenar
    ; Aumentar BX por 32 bits
    add bx, 32
    jmp .read_register_loop
.equal_names:
    ; Guardar la direccion 
    mov ax, [es:bx + 26]
    ; Retornar y stack
    pop si
    pop dx
    pop cx
    pop bx
    ret
.stop:
    mov si, msg_kernel_failed
    call print
    jmp stop

; Leer un floppy
; Argumentos:
;  - ax: LBA address
;  - cl: Numero de sectores
; Retorna:
;  - ES:BX los datos
read_floppy:
    ; Stack
    push ax
    push bx
    push cx
    push dx
    call lba_to_chs ; Empiezo seteando el address CHS
    ; BIOS
    mov ah, 2
    mov al, cl
    mov dl, [ebpb_drive_number]
    int 0x13
    ; Fijarme si fallo
    jc .failed_floppy
    ; Retorno
    pop dx
    pop cx
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

; Imprime a consola
; Argumentos:
;   - SI: la direccion del string
print:
    push ax
    push bx
    push si
    ; Setup del bios
    mov bh, 0
    mov ah, 0x0E
    ; Guarda los registros a modificar en el stack
    jmp .loop
.loop:
    lodsb   ; Carga el byte en DS:SI en AL e incrementa SI para que DS:SI sea el siguiente byte
    or al, al   ; No modifica el caracter, pero si es nulo(todo 0) entonces setea ZF=1
    jz .done   ; Salta a done si ZF=1

    int 0x10
    jmp .loop
.done:
    ; Retorna los valores de si y ax
    pop si
    pop bx
    pop ax
    ret

; Termino con el 0 para que no quede basura y siga imprimiendo. Lo declaro al final para que no lo lea como codigo
msg_test:   db 'Booting', ENDL, 0
msg_read_failed: db 'Floppy failed', ENDL, 0
msg_kernel_failed: db 'Finding kernel failed', ENDL, 0
kernel_name: db 'KERNEL  BIN'

; Padding y signature MBR
times 510-($-$$) db 0 ; Un padding de 0s de 510 bytes - los usados para el programa
dw 0AA55h ; El tag. Escrito asi porque NASM no entiende hexadecimal cuando empieza con una letra, y al reves por little endian

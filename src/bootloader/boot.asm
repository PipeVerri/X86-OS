org 0x7c00  ; Start with this offset in memory
bits 16

;
; Headers FAT12
;
jmp short main ; Jump to main, takes 2 bytes (hence the short)
nop

bpb_oem:                 db 'MSWIN4.1'   ; DOS version, for compatibility only
bpb_bytes_per_sector:    dw 512
bpb_sectors_per_cluster: db 1
bpb_reserved_sectors:    dw 1            ; Sectors reserved for a second (future) bootloader
bpb_fat_number:          db 2            ; Number of FAT table copies, 2 for redundancy
bpb_root_dir_count:      dw 224          ; The root directory only occupies one sector, so it can only have 224 entries (32 bytes each)
bpb_sector_count:        dw 2880         ; Number of sectors on disk
bpb_media_descriptor:    db 0F0h         ; Double-sided 3.5 inch disk
bpb_sectors_per_fat:     dw 9            ; How many sectors each FAT table occupies
bpb_sectors_per_track:   dw 18           ; Standard for 1.44MiB floppy
bpb_heads_number:        dw 2
bpb_hidden_sectors:      dd 0            ; For when a hard disk is used instead of a floppy
bpb_large_sector_count:  dd 0
; Extended boot record
ebpb_drive_number:       db 0            ; 0x00 for floppy, 0x80 for HDD
                         db 0            ; Reserved
ebpb_signature:          dw 28h
                         dd 0            ; Ignored
ebpb_label:              db 'label      '; 11 bytes, padded with spaces
ebpb_system_id:          db 'FAT-12  '   ; 8 bytes

; Macros
%define ENDL 0x0D, 0x0A ; Macro for newline

; Boot code
main:
    ; Initialize segments
    mov ax, 0
    mov ds, ax
    ; ES
    mov ax, 0x7e00
    mov es, ax
    ; SS
    mov ax, 0
    mov ss, ax
    mov sp, 0x7c00  ; The stack is decremental and last-in-first-out, for now the space is sufficient

    ; Call the print function
    mov si, msg_test ; Set the offset instead of DS since msg is written in DS when declared
    call print

    call load_kernel

stop: ; hlt generally doesn't work well, so I use a loop
    hlt
    jmp stop

load_kernel:
    ; Find which cluster the kernel is in
    call get_kernel_cluster
    mov dx, ax ; Store the initial cluster in DX temporarily
    ; Start loading the FAT table at 0x7e00
    ; Initialize ES:BX
    mov ax, 0x7e00
    mov es, ax
    mov bx, 0
    ; Load it
    mov ax, [bpb_reserved_sectors] ; Start from the bootloader and up
    mov cl, [bpb_sectors_per_fat]
    call read_floppy
    ; Now load the kernel at 0x1000
    mov ax, 0x1000
    mov es, ax
    mov bx, 0
    ; And access the FAT table from FS:SI
    mov ax, 0x7e00
    mov fs, ax
    mov si, 0
    ; Put the LBA of the initial cluster in ax
    mov ax, dx
    add ax, 31 ; hidden_sector + FAT_sectors * 2 + root_sectors - 2 (because the first 2 clusters are metadata, not actual records)
    mov cl, [bpb_sectors_per_cluster]
    call read_floppy
    .loop_load_kernel_1:
        ; Extract the current FAT table entry
        mov si, dx
        shr si, 4 ; SI = n / 2
        add si, dx ; SI = n + n/2 = n * 1.5
        ; Check whether to extract the low or high part of the word
        test dx, 1 ; Bitwise AND without modifying DX, only the flags
        mov dx, [fs:si] ; Load the new entry
        jz .even_n
    .odd_n:
        and dx, 0x0FFF ; Take the upper 12 bits
        jmp .loop_load_kernel_2
    .even_n:
        shr dx, 4 ; Take the lower 12 bits
    .loop_load_kernel_2:
        ; Check if EOF or continue reading
        cmp dx, 0xFF8
        jae .return ; Jump if >=
        ; Load the new cluster into RAM
        mov ax, dx
        add ax, 31 ; Cluster -> LBA
        add bx, 512 ; Add the offset so it doesn't overwrite the previous read
        mov cl, [bpb_sectors_per_cluster]
        call read_floppy
        jmp .loop_load_kernel_1
    .return:
        jmp 0x1000:0x0000

; Returns:
; - AX: the initial cluster where the kernel is located
get_kernel_cluster:
    ; Calculate where the root FAT table sector starts (hardcoded for now)
    mov ax, 19 ; kernel reserved sector + (9 * 2) FAT table sectors (LBA is zero-indexed)
    mov cl, 14 ; The root FAT table is 14 sectors (number of files * 32 bits / 512b per sector)
    mov bx, 0
    ; Read the floppy
    call read_floppy
    ; Find where the kernel is
    mov cx, [bpb_root_dir_count]
    mov si, kernel_name
    call find_file_start_cluster
    ret
; Arguments
; - ES:BX the loaded directory
; - DS:SI the file name to find (in FAT format)
; - cx the number of files in the directory
; Returns
; - AX the memory cluster where it is
find_file_start_cluster:
    ; Stack
    push bx
    push cx
    push dx
    push si

    cld ; Set the direction flag to 0 so comparisons move DI and SI forward
.read_register_loop:
    ; Check the title
    mov di, bx ; CMPSB uses DI
    mov cx, 11
    push si
    repe cmpsb ; Repeat while ZF=1 (characters match)
    pop si
    jz .equal_names
    ; If not equal, decrement dx and check if we've gone past all entries
    dec dx
    je .stop ; If 0, stop
    ; Increase BX by 32 bytes
    add bx, 32
    jmp .read_register_loop
.equal_names:
    ; Save the address
    mov ax, [es:bx + 26]
    ; Return and restore stack
    pop si
    pop dx
    pop cx
    pop bx
    ret
.stop:
    mov si, msg_kernel_failed
    call print
    jmp stop

; Read a floppy
; Arguments:
;  - ax: LBA address
;  - cl: Number of sectors
; Returns:
;  - ES:BX the data
read_floppy:
    ; Stack
    push ax
    push bx
    push cx
    push dx
    call lba_to_chs ; Start by setting the CHS address
    ; BIOS
    mov ah, 2
    mov al, cl
    mov dl, [ebpb_drive_number]
    int 0x13
    ; Check if it failed
    jc .failed_floppy
    ; Return
    pop dx
    pop cx
    pop bx
    pop ax
    ret
.failed_floppy:
    mov si, msg_read_failed
    call print
    jmp stop

; Address conversion
; Arguments:
;  - ax: LBA address
; Returns:
;  - ch: lower 8 bits of the cylinder
;  - cl: 6 sector bits and the upper 2 bits of the cylinder
;  - dh: head
lba_to_chs:
    ; Stack
    push ax
    push bx
    
    ; Cylinder calculation
    mov dx, 0   ; Set the remainder to 0
    mov bx, [bpb_sectors_per_track] ; The divisor
    div bx  ; ax = ax / bx, dx = ax % bx
    inc dx
    mov cl, dl ; Then do the OR and put the last 2 cylinder bits in
    and cl, 0b00111111 ; Clear the residual upper 2 bits

    ; Head calculation
    mov dx, 0
    mov bx, [bpb_heads_number]
    div bx ; ax = ax / bx, dx = ax % bx
    mov dh, dl

    ; Sector calculation
    mov ch, al ; The upper 8 bits
    shl ah, 6 ; Put the last 2 cylinder bits at the end of ah
    or cl, ah ; Put the last 2 bits in cl

    ; Restore from stack and return
    pop bx
    pop ax
    ret

; Print to console
; Arguments:
;   - SI: the string address
print:
    push ax
    push bx
    push si
    ; BIOS setup
    mov bh, 0
    mov ah, 0x0E
    ; Save registers to be modified on the stack
    jmp .loop
.loop:
    lodsb   ; Load the byte at DS:SI into AL and increment SI so DS:SI points to the next byte
    or al, al   ; Does not modify the character, but if it's null (all 0) it sets ZF=1
    jz .done   ; Jump to done if ZF=1

    int 0x10
    jmp .loop
.done:
    ; Restore si and ax values
    pop si
    pop bx
    pop ax
    ret

; End with 0 so no garbage is left and printing continues. Declared at the end so it's not read as code
msg_test:   db 'Booting', ENDL, 0
msg_read_failed: db 'Floppy failed', ENDL, 0
msg_kernel_failed: db 'Finding kernel failed', ENDL, 0
kernel_name: db 'KERNEL  BIN'

; MBR padding and signature
times 510-($-$$) db 0 ; Zero padding up to 510 bytes minus the bytes used by the program
dw 0AA55h ; The tag. Written this way because NASM doesn't understand hex starting with a letter, and reversed for little endian

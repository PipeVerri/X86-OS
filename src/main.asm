ORG 0x7c00 ; Empezar con este offset en la RAM
bits 16

main:
    hlt

times 510-($-$$) db 0 ; Un padding de 0s de 510 bytes - los usados para el programa
dw 0AA55h ; El tag en little endian

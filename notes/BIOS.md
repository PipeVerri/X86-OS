# Video
Interrupt 0x10
- AH = 0x0E para escribir por TTY
	- AL = caracter ASCII
	- BH = numero de pagina
# Almacenamiento
Interrupt 0x13
- AH = 0x2 para leer el floppy en CHS
	- AL = numero de sectores a leer(no puede superar los 64k, no se puede pasar del segmento de RAM)
	- CH = los 8 bits bajos del cilindro(cilindro & 0xFF)
	- CL = los 6 bits bajos del sector y los 2 altos del cilindro

https://wiki.osdev.org/Disk_access_using_the_BIOS_(INT_13h)

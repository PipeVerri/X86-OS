Para el numero de clusters, tengo
- 2880 sectores
- 1 lo uso para el bootloader
- 1 es reservado
- Tengo 224 entradas en el root, y como cada entrada ocupa 32b, uso 14 sectores.
- Cada tabla FAT ocupa 9 sectores porque:
	- Tengo que tablear 2880 - 1(boot) - 1(reservado) - 14(root) = 2864
	- Cada entrada ocupa 12 bits = 1.5 bytes(LAS NO ROOT)
	- Entonces necesito que las tablas les entren 2864 * 1.5 = 4296b
	- Eso es 4296 / 512 sectores = 9(redondeado para arriba)
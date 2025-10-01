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
https://wiki.osdev.org/FAT#FAT_12_and_FAT_16

![[Pasted image 20250930145843.png]]
Para referenciar un bloque, hay 2 formas de hacerlo:
1. CMS: donde le paso el numero de track, numero de sector, y numero de cabeza
	**El track y la cabeza empiezan desde el 0 pero el sector empieza desde el 1**.
2. LBA: le paso solo 1 numero

Hay veces que tengo que hacer la conversion de LBA a CHS a mano. Asi funciona LBA(aca el numero de sector se le deberia sumar 1, no existe el sector 0)
![[Pasted image 20250930150629.png]]

Para hacer la conversion:
- sector = (LBA % num sectores por track) + 1
- cabeza = (LBA / num sectores por track) % num cabezas
- cilindro = (LBA / num sectores por track) / num cabezas

**Pensarlo como los 3 numeros de CHS combinados**. Por ejemplo, en 345
- Es el sector 5
- Cabeza 4
- Cilindro 3


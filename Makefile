ASM = nasm # Usar nasm para compilar assembly, esto es solo una variable
SRC_DIR = src
BUILD_DIR = build

main_floppy: main
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img # Padding con 0s para que quede del tamaño de un floppy disk

main: $(SRC_DIR)/main.asm
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin

run: $(BUILD_DIR)/main_floppy.img
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

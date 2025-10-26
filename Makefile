ASM = nasm # Usar nasm para compilar assembly, esto es solo una variable
SRC_DIR = src
BUILD_DIR = build
.PHONY: clean run debug
#
# Image
#
main_floppy: $(BUILD_DIR)/main_floppy.img

$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	# Crear una imagen floppy vacia
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	# Formatearla como FAT12
	mkfs.fat -F 12 -n "OS" $(BUILD_DIR)/main_floppy.img
	# Copiarla para debugging del formateo
	cp $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/clean_floppy.img
	# Poner el bootloader al principio de la image, y notrunc para que no achique la imagen al tamaño del bootloader
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	# Copiar el kernel luego del bootloader(en la particion FAT). En vez de tener que montar la imagen puedo usar mcopy
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
#
# Build
#
$(BUILD_DIR)/boot.bin: $(SRC_DIR)/bootloader/boot.asm
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/boot.bin

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/main.asm
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin
#
# Utils
#
clean:
	rm -r $(BUILD_DIR)/*

run: $(BUILD_DIR)/main_floppy.img
	qemu-system-i386 -fda $(BUILD_DIR)/main_floppy.img

debug: $(BUILD_DIR)/main_floppy.img
	bochs -debugger -f bochsrc.txt -q
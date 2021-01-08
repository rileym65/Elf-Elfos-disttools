PROJECT = fsgen

$(PROJECT).prg: $(PROJECT).asm bios.inc
	rcasm -l -v -x -d 1802 $(PROJECT) 2>&1 | tee $(PROJECT).lst

ram: $(PROJECT).asm bios.inc
	rcasm -l -v -x -d 1802 -DRAM $(PROJECT) 2>&1 | tee $(PROJECT).lst

clean:
	-rm $(PROJECT).prg



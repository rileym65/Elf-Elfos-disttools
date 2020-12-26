PROJECT = hdinit

$(PROJECT).prg: $(PROJECT).asm bios.inc
	rcasm -l -v -x -d 1802 $(PROJECT) | tee $(PROJECT).lst

clean:
	-rm $(PROJECT).prg



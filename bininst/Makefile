PROJECT = bininst

$(PROJECT).prg: $(PROJECT).asm bios.inc
	rcasm -l -v -x -d1802 $(PROJECT) | tee $(PROJECT).lst

clean:
	-rm $(PROJECT).prg



PROJECT = menu
$(PROJECT).prg: $(PROJECT).asm
	rcasm -l -v -x -d 1802 $(PROJECT) | tee $(PROJECT).lst

clean:
	-rm $(PROJECT).prg


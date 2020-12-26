PROJECT = sedit
$(PROJECT).rom: $(PROJECT).asm
	rcasm -l -v -x -d 1802 $(PROJECT) | tee $(PROJECT).lst
	cat $(PROJECT).prg | sed -f adjust.sed > x.prg
	rm $(PROJECT).prg
	mv x.prg $(PROJECT).prg

clean:
	-rm $(PROJECT).prg


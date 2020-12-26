OBJS = ../asm/asm.prg \
	../chdir/chdir.prg \
	../copy/copy.prg \
	../del/del.prg \
	../dir/dir.prg \
	../dump/dump.prg \
	../edit/edit.prg \
	../exec/exec.prg \
	../free/free.prg \
	../hexdump/hexdump.prg \
	../install/install.prg \
	../load/load.prg \
	../minimon/minimon.prg \
	../mkdir/mkdir.prg \
	../patch/patch.prg \
	../rename/rename.prg \
	../rmdir/rmdir.prg \
	../save/save.prg \
	../setboot/setboot.prg \
	../stat/stat.prg \
	../type/type.prg \
	../ver/ver.prg \
	../kernel/kernel.prg \
	./bininst/bininst.prg \
	./eosinst/eosinst.prg \
	./sys/sys.prg \
	./hdinit/hdinit.prg \
	./menu/menu.prg \
	./sedit/sedit.prg

elfos.rom: $(OBJS) rom.txt
	./buildrom.pl
	cat table.rom build.rom > elfos.rom

clean:
	rm elfos.rom

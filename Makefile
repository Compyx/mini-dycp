# vim: set noet ts=8:

ASM = 64tass
AFLAGS = --case-sensitive --ascii --m6502 -Wshadow -Wbranch-page \
	 --vice-labels --labels labels.txt

PROGRAM = minidycp.prg
SOURCES = main.s dycp.s



all: $(PROGRAM)

$(PROGRAM): $(SOURCES) focus.kla find-gaps.awk
	#$(ASM) $(AFLAGS) $< -o $@ | awk -f find-gaps.awk
	$(ASM) $(AFLAGS) -D USE_SYSLINE=1 $< -o $@

packed: $(SOURCES) focus.kla find-gaps.awk
	#$(ASM) $(AFLAGS) $< -o $@ | awk -f find-gaps.awk
	$(ASM) $(AFLAGS) -D USE_SYSLINE=0 $< -o minidycp-pre-exo.prg
	exomizer sfx 8192 minidycp-pre-exo.prg -o minidycp.exomized.prg
	



.PHONY: clean
clean:
	rm -f $(PROGRAM)
	rm -f minidycp-pre-exo.prg
	rm -f minidycp.exomized.prg



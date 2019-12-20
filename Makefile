# vim: set noet ts=8:

ASM = 64tass
AFLAGS = --case-sensitive --ascii --m6502 -Wshadow -Wbranch-page \
	 --vice-labels --labels labels.txt

PROGRAM = minidycp.prg
SOURCES = main.s dycp.s



all: $(PROGRAM)

$(PROGRAM): $(SOURCES) focus.kla
	$(ASM) $(AFLAGS) $< -o $@ | awk -f find-gaps.awk


.PHONY: clean
clean:
	rm -f $(PROGRAM)


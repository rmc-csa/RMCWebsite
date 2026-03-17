# Makefile for latex2html with output directory

SRC = rmc.tex
OUTDIR = output   # change this to your desired folder

all:
	mkdir -p $(OUTDIR)
	latex2html -split 0 -no_navigation -html_version 4.0 -dir $(OUTDIR) $(SRC)

clean:
	rm -rf $(OUTDIR)
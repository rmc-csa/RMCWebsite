OUTDIR = output
SRCDIR = src
MAKE4HT = make4ht
LATEXMK = latexmk -pdf -interaction=nonstopmode -halt-on-error -shell-escape

# Injects a <style> block before </head> in every index.html to kill dark-mode image inversion
PATCH_HTML = find . -name "index.html" -exec perl -i -pe \
	's|</head>|<style>\@media (prefers-color-scheme:dark){img{filter:none!important}}</style></head>|i' {} \;

.PHONY: all main topic1 topic2 pdf pdf_main pdf_topic1 pdf_topic2 clean copy

all: clean main topic1 topic2 pdf

copy:
# 	rm -rf $(OUTDIR)
	mkdir -p $(OUTDIR)
	cp -r $(SRCDIR)/* $(OUTDIR)/
	cd $(OUTDIR)/img && ebb -x * || true
	ln -sfn ../img $(OUTDIR)/topic_1_ehrhart/img
	ln -sfn ../img $(OUTDIR)/topic_2_lattices/img

main: copy
	cd $(OUTDIR) && mkdir -p main && \
	$(MAKE4HT) -f html5 -d main index.tex && \
	$(PATCH_HTML)

topic1: copy
	cd $(OUTDIR) && mkdir -p main/topic_1_ehrhart && \
	$(MAKE4HT) -f html5 -d main/topic_1_ehrhart topic_1_ehrhart/index.tex && \
	$(PATCH_HTML)

topic2: copy
	cd $(OUTDIR) && mkdir -p main/topic_2_lattices && \
	$(MAKE4HT) -f html5 -d main/topic_2_lattices topic_2_lattices/index.tex && \
	$(PATCH_HTML)

# PDF targets — depend on copy so the output tree is fresh
pdf: pdf_main pdf_topic1 pdf_topic2

pdf_main: copy
	cd $(OUTDIR) && $(LATEXMK) index.tex && \
	mv index.pdf main/index.pdf

pdf_topic1: copy
	mkdir -p $(OUTDIR)/main/topic_1_ehrhart
	cd $(OUTDIR)/topic_1_ehrhart && $(LATEXMK) index.tex && \
	mv index.pdf ../main/topic_1_ehrhart/index.pdf

pdf_topic2: copy
	mkdir -p $(OUTDIR)/main/topic_2_lattices
	cd $(OUTDIR)/topic_2_lattices && $(LATEXMK) index.tex && \
	mv index.pdf ../main/topic_2_lattices/index.pdf

clean:
	rm -rf $(OUTDIR)
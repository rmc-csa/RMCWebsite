OUTDIR = output
SRCDIR = src
MAKE4HT = make4ht

# Injects a <style> block before </head> in every index.html to kill dark-mode image inversion
PATCH_HTML = find . -name "index.html" -exec perl -i -pe \
	's|</head>|<style>\@media (prefers-color-scheme:dark){img{filter:none!important}}</style></head>|i' {} \;

.PHONY: all main topic1 topic2 clean copy

all: main topic1 topic2

copy:
	rm -rf $(OUTDIR)
	mkdir -p $(OUTDIR)
	cp -r $(SRCDIR)/* $(OUTDIR)/
	cd $(OUTDIR)/img && ebb -x * || true

main: copy
	cd $(OUTDIR) && mkdir -p main && \
	$(MAKE4HT) -f html5 -d main index.tex && \
	$(PATCH_HTML)

topic1: copy
	cd $(OUTDIR) && mkdir -p topic_1_ehrhart && \
	$(MAKE4HT) -f html5 -d topic_1_ehrhart topic_1_ehrhart/index.tex && \
	$(PATCH_HTML)

topic2: copy
	cd $(OUTDIR) && mkdir -p topic_2_lattices && \
	$(MAKE4HT) -f html5 -d topic_2_lattices topic_2_lattices/index.tex && \
	$(PATCH_HTML)

clean:
	rm -rf $(OUTDIR)
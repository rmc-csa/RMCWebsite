# ──────────────────────────────────────────────────────────────────────────────
# RMC Site Makefile
#
# Directory layout
#   src/
#     index.tex                    ← main landing page
#     img/                         ← common images (logo, etc.)
#     img/topics/<year>/<n>/       ← topic-specific images
#     topics/<year>/<n>/
#       index.tex                  ← topic notes
#       notes.txt                  ← speaker / date metadata
#
#   output/
#     .build/                      ← scratch space for make4ht / latexmk
#       main/                      ← main page build dir
#       topics/<year>/<n>/         ← per-topic build dir
#     site/                        ← final deployable tree
#       index.html
#       index.pdf
#       img/  → symlink to common images
#       topics/<year>/<n>/
#         index.html
#         index.pdf
#         img  → symlink to topic images
#
# Incremental build
#   Each target writes a stamp file (.build/<target>.stamp).
#   A target only reruns when its source files are newer than the stamp.
#
# Parallelism
#   Run `make -j$(nproc)` to build all topics in parallel.
#   The main page is independent of all topics and also runs in parallel.
#
# Adding a new topic (e.g. 2026/3)
#   1. mkdir -p src/topics/2026/3  src/img/topics/2026/3
#   2. Drop index.tex and notes.txt in src/topics/2026/3/
#   3. Add a line to TOPICS below.
#   4. make
# ──────────────────────────────────────────────────────────────────────────────

SRCDIR   := src
OUTDIR   := output
BUILDDIR := $(OUTDIR)/.build
SITEDIR  := $(OUTDIR)/site

MAKE4HT  := make4ht
LATEXMK  := latexmk -pdf -interaction=nonstopmode -halt-on-error -shell-escape

# ── Topic registry ─────────────────────────────────────────────────────────────
# Format: <year>/<n>   (must match a directory under src/topics/)
TOPICS := \
    2026/1 \
    2026/2

# ── Derived lists ──────────────────────────────────────────────────────────────
TOPIC_HTML_STAMPS := $(foreach t,$(TOPICS),$(BUILDDIR)/topics/$(t)/html.stamp)
TOPIC_PDF_STAMPS  := $(foreach t,$(TOPICS),$(BUILDDIR)/topics/$(t)/pdf.stamp)
MAIN_HTML_STAMP   := $(BUILDDIR)/main/html.stamp
MAIN_PDF_STAMP    := $(BUILDDIR)/main/pdf.stamp

# ── Patch helper: suppress dark-mode image inversion ──────────────────────────
define PATCH_HTML
	find $1 -name "index.html" -exec perl -i -pe \
		's|</head>|<style>\
\@media (prefers-color-scheme:dark){img{filter:none!important}}\
</style></head>|i unless /max-width:min\(80vw,1100px\)/' {} \;
endef

# ── Default target ─────────────────────────────────────────────────────────────
.PHONY: all html pdf clean help

all: html pdf

html: $(MAIN_HTML_STAMP) $(TOPIC_HTML_STAMPS)

pdf: $(MAIN_PDF_STAMP) $(TOPIC_PDF_STAMPS)

IMG_STAMP := $(SITEDIR)/img/.stamp

$(IMG_STAMP):
	@echo "[SYNC] images"
	@mkdir -p $(SITEDIR)/img
	@rsync -a --delete $(SRCDIR)/img/ $(SITEDIR)/img/
	@find $(SITEDIR)/img -type f -exec ebb -x "{}" +
	@touch $@

# ── Main page — HTML ───────────────────────────────────────────────────────────
$(MAIN_HTML_STAMP): $(SRCDIR)/index.tex $(wildcard $(SRCDIR)/img/*) $(IMG_STAMP)
	@echo "[HTML] main"
	@mkdir -p $(BUILDDIR)/main $(SITEDIR)
	@# Copy source + common images into build scratch
	@cp $(SRCDIR)/index.tex $(BUILDDIR)/main/
	@ln -sfn $(abspath $(SITEDIR)/img) $(BUILDDIR)/main/img
	@cd $(BUILDDIR)/main && \
		$(MAKE4HT) -f html5 index.tex 2>&1 | tail -5
	@# Install into site
	@cp $(BUILDDIR)/main/index.html $(SITEDIR)/
	@cp $(BUILDDIR)/main/index.css  $(SITEDIR)/ 2>/dev/null || true
	@# Shared image symlink in site root (idempotent)
	$(call PATCH_HTML,$(SITEDIR))
	@touch $@

# ── Main page — PDF ────────────────────────────────────────────────────────────
$(MAIN_PDF_STAMP): $(SRCDIR)/index.tex $(wildcard $(SRCDIR)/img/*) $(IMG_STAMP)
	@echo "[PDF]  main"
	@mkdir -p $(BUILDDIR)/main $(SITEDIR)
	@cp $(SRCDIR)/index.tex $(BUILDDIR)/main/
	@rm -rf $(BUILDDIR)/main/img && cp -r $(SITEDIR)/img $(BUILDDIR)/main/img
	@cd $(BUILDDIR)/main && \
		$(LATEXMK) index.tex 2>&1 | tail -5
	@cp $(BUILDDIR)/main/index.pdf $(SITEDIR)/
	@touch $@

# ── Per-topic rules (pattern) ─────────────────────────────────────────────────
# HTML stamp for topics/<year>/<n>
$(BUILDDIR)/topics/%/html.stamp: \
    $(SRCDIR)/topics/%/index.tex \
    $(wildcard $(SRCDIR)/topics/%/*)  \
    $(wildcard $(SRCDIR)/img/topics/%/*) \
    $(IMG_STAMP)
	@echo "[HTML] topic $*"
	@mkdir -p $(BUILDDIR)/topics/$* $(SITEDIR)/topics/$*
	@cp $(SRCDIR)/topics/$*/index.tex $(BUILDDIR)/topics/$*/
	@# Make img/ inside build dir point to the full img tree so LaTeX
	@# can resolve both common (img/logo.png) and topic-specific paths
	@# (img/topics/2026/1/foo.png) without changing the .tex source.
	@rm -f $(BUILDDIR)/topics/$*/img
	@ln -sfn $(abspath $(SITEDIR)/img) $(BUILDDIR)/topics/$*/img
	@cd $(BUILDDIR)/topics/$* && \
		$(MAKE4HT) -f html5 index.tex 2>&1 | tail -5
	@# Install HTML + CSS into site
	@cp $(BUILDDIR)/topics/$*/index.html $(SITEDIR)/topics/$*/
	@cp $(BUILDDIR)/topics/$*/index.css  $(SITEDIR)/topics/$*/ 2>/dev/null || true
	@# Copy generated SVGs (make4ht extracts math/figures as SVGs)
	@find $(BUILDDIR)/topics/$* -maxdepth 1 -name '*.svg' \
		-exec cp {} $(SITEDIR)/topics/$*/ \;
	@# Symlink img inside the site topic dir for HTML <img> tags
	@ln -sfn $(abspath $(SITEDIR)/img) $(SITEDIR)/topics/$*/img
	$(call PATCH_HTML,$(SITEDIR)/topics/$*)
	@touch $@

# PDF stamp for topics/<year>/<n>
$(BUILDDIR)/topics/%/pdf.stamp: \
    $(SRCDIR)/topics/%/index.tex \
    $(wildcard $(SRCDIR)/topics/%/*) \
    $(wildcard $(SRCDIR)/img/topics/%/*) \
    $(IMG_STAMP)
	@echo "[PDF]  topic $*"
	@mkdir -p $(BUILDDIR)/topics/$* $(SITEDIR)/topics/$*
	@cp $(SRCDIR)/topics/$*/index.tex $(BUILDDIR)/topics/$*/
	@rm -f $(BUILDDIR)/topics/$*/img
	@ln -sfn $(abspath $(SITEDIR)/img) $(BUILDDIR)/topics/$*/img
	@cd $(BUILDDIR)/topics/$* && \
		$(LATEXMK) index.tex 2>&1 | tail -5
	@cp $(BUILDDIR)/topics/$*/index.pdf $(SITEDIR)/topics/$*/
	@touch $@

# ── Clean ──────────────────────────────────────────────────────────────────────
clean:
	rm -rf $(OUTDIR)

# Remove only stamp files — forces a full rebuild without wiping artifacts
rebuild:
	find $(BUILDDIR) -name '*.stamp' -delete

# ── Help ───────────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  make              build everything (incremental)"
	@echo "  make -j\$$(nproc)   build in parallel"
	@echo "  make html         HTML only"
	@echo "  make pdf          PDF only"
	@echo "  make rebuild      force full rebuild (keeps build cache)"
	@echo "  make clean        delete all output"
	@echo ""
	@echo "  Topics: $(TOPICS)"
	@echo ""

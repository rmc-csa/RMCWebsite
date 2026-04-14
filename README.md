# RMC Site — Build & Deployment

## Requirements

* TeX Live (with `make4ht`, `latexmk`)
* `perl`
* `make`

---

## Source layout

```
src/
  index.tex                  ← main landing page
  img/                       ← common images (logo, etc.)
  img/topics/<year>/<n>/     ← topic-specific images
  topics/
    <year>/
      <n>/
        index.tex            ← main page for the topic
        notes.txt            ← notes
```

Image paths in topic `.tex` files use the full path from the `img/` root:

```latex
\includegraphics{img/topics/<year>/<n>/foo.png}   % topic-specific
\includegraphics{img/logo.png}                    % common
```

---

## Build

```bash
make              # incremental build
make -j$(nproc)   # parallel build (recommended)
make html         # HTML only
make pdf          # PDF only
make rebuild      # force full rebuild (keeps LaTeX cache)
make clean        # wipe all output
```

The build is **incremental**: a topic is only rebuilt when its `.tex`
or image files are newer than the previous build's stamp file.

---

## Adding a new topic

1. Create the directories:

   ```bash
   mkdir -p src/topics/<year>/<n>
   mkdir -p src/img/topics/<year>/<n>
   ```

2. Add `src/topics/<year>/<n>/index.tex` and `src/topics/<year>/<n>/notes.txt`.

3. Drop any topic images into `src/img/topics/<year>/<n>/`.

4. Add `<year>/<n>` to the `TOPICS` list in `Makefile`.

5. `make -j$(nproc)`

---

## Output

```
output/site/
  index.html
  index.pdf
  img/              ← rsynced with src/img
  topics/
    <year>/
      <n>/
        index.html
        index.pdf
```

Deploy the contents of `output/site/` to any static host (GitHub Pages,
Netlify, Vercel, nginx, etc.).

---

## Local preview

```bash
cd output/site && live-server
```

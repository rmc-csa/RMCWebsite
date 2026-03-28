# Build & Deployment

## Requirements

* TeX distribution (TeX Live recommended)
* make
* make4ht
* latexmk
* perl
* ebb
* (optional) Node.js + live-server

Install live-server (optional):

```
npm install -g live-server
```

---

## Build

Build everything:

```
make
```

Build only HTML:

```
make main topic1 topic2
```

Build only PDFs:

```
make pdf
```

Clean:

```
make clean
```

---

## Local preview

Serve the generated site from:

```
output/main
```

Example:

```
cd output/main
live-server
```

Any static file server should work.

---

## Deployment

Deploy the contents of:

```
output/main
```

Works with:

* GitHub Pages
* Netlify
* Vercel
* nginx / Apache
* any static hosting

---

## Output structure

```
output/main/
    index.html
    index.pdf
    topic_1_ehrhart/
        index.html
        index.pdf
    topic_2_lattices/
        index.html
        index.pdf
```

#!/usr/bin/env python3

import pathlib
import sys

html_file = pathlib.Path(sys.argv[1])
header_file = pathlib.Path(sys.argv[2])

html = html_file.read_text(encoding="utf-8")
header = header_file.read_text(encoding="utf-8")

if header in html:
    sys.exit(0)

html = html.replace("</head>", header + "\n</head>", 1)

html_file.write_text(html, encoding="utf-8")
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""to_markdown.py - optional helper: convert a PDF into structured Markdown with anchors and fidelity notes.

This is a convenience helper. The study-paper workflow runs without it.

WHAT IT DOES
    Reads a PDF and prints Markdown organised into pages and (when the engine can
    infer them) section headings. Every page carries an HTML-comment anchor
    (<!-- anchor: pN -->) and every detected heading gets its own anchor, so the
    resulting notes can cite the source by location. The output always begins
    with an explicit FIDELITY NOTES block describing how the text was obtained
    and what is unreliable about it.

ENGINES (tried in order by --engine auto; first that yields text wins)
    1. pymupdf   - PyMuPDF (import name: fitz). Preferred: gives text plus font
                   sizes, so headings and page anchors are reliable.
    2. grobid    - a GROBID service (optional). Needs --grobid-url or GROBID_URL,
                   e.g. a container started with
                   `docker run --rm -p 8070:8070 lfoppiano/grobid:0.8.1`.
    3. pdftotext - Poppler on PATH. Plain-text fallback: page anchors only, no
                   headings, no figures/tables/equations.
    4. builtin   - a bundled best-effort extractor (standard library only). Lowest
                   fidelity; used only when nothing else is available.

DEPENDENCIES
    - Required: Python 3.8+ standard library only.
    - Optional: PyMuPDF for the best structure (`pip install pymupdf`).
    - Optional: a running GROBID service reachable at --grobid-url.
    - Optional: the `pdftotext` executable from Poppler on PATH.
    Missing optional pieces are not fatal: the helper falls back to the next
    engine and records the fallback in the fidelity notes rather than failing
    silently.

EXIT CODES
    0  text extracted
    1  bad usage, missing input file, or an output-write error
    2  no engine was available (all dependencies missing)
    3  an engine ran but returned no usable text (e.g. a scanned PDF with no text layer)

USAGE
    python3 to_markdown.py paper.pdf
    python3 to_markdown.py paper.pdf --out paper.md
    python3 to_markdown.py paper.pdf --engine pdftotext
    python3 to_markdown.py paper.pdf --grobid-url http://localhost:8070
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import zlib
import xml.etree.ElementTree as ET

USER_AGENT = "study-paper-tomarkdown/1.0"
DEFAULT_TIMEOUT = 60
DEFAULT_MIN_CHARS = 200
GROBID_BOUNDARY = "----studyPaperGrobidBoundary7MA4YWxkTrZu0gW"
TEI_NS = {"tei": "http://www.tei-c.org/ns/1.0"}


# --------------------------------------------------------------------------- #
# small helpers
# --------------------------------------------------------------------------- #

def collapse(text):
    return " ".join(text.split()) if text else ""


def slugify(text):
    slug = re.sub(r"[^a-z0-9]+", "-", (text or "").lower()).strip("-")
    return slug[:48] or "section"


def _local(tag):
    return tag.rsplit("}", 1)[-1]


def _structured(pages, warnings, structure, engine, extra=None):
    chars = sum(len(block["text"]) for page in pages for block in page["blocks"])
    headings = sum(
        1 for page in pages for block in page["blocks"] if block["type"] == "heading"
    )
    result = {
        "pages": pages,
        "warnings": warnings,
        "structure": structure,
        "engine": engine,
        "page_count": len(pages),
        "chars": chars,
        "headings": headings,
    }
    if extra:
        result.update(extra)
    return result


# --------------------------------------------------------------------------- #
# engine 1: PyMuPDF
# --------------------------------------------------------------------------- #

def engine_pymupdf(path, options):
    try:
        import fitz  # PyMuPDF
    except Exception as exc:  # ImportError or a broken install
        return None, "PyMuPDF not importable (%s)" % exc

    try:
        document = fitz.open(path)
    except Exception as exc:
        return None, "PyMuPDF could not open the file (%s)" % exc

    warnings = []
    raw_pages = []
    all_sizes = []
    try:
        for index in range(document.page_count):
            page = document.load_page(index)
            width = page.rect.width or 1.0
            lines = []
            try:
                data = page.get_text("dict")
            except Exception as exc:
                warnings.append("page %d text extraction failed (%s)" % (index + 1, exc))
                data = {}
            for block in data.get("blocks", []):
                if block.get("type") != 0:
                    continue
                for line in block.get("lines", []):
                    spans = line.get("spans", [])
                    text = collapse("".join(span.get("text", "") for span in spans))
                    if not text:
                        continue
                    size = max((span.get("size", 0.0) for span in spans), default=0.0)
                    bold = any(span.get("flags", 0) & 16 for span in spans)
                    bbox = line.get("bbox") or [0, 0, 0, 0]
                    lines.append({"text": text, "size": round(size, 1), "bold": bold, "x0": bbox[0]})
                    all_sizes.append(size)
            raw_pages.append({"number": index + 1, "width": width, "lines": lines})
    finally:
        document.close()

    if not all_sizes:
        return _structured(
            [{"number": p["number"], "blocks": []} for p in raw_pages],
            warnings + ["no text layer found - the PDF is probably a scan (OCR is not bundled)"],
            "none (no text layer)",
            "pymupdf",
        ), None

    body = sorted(all_sizes)[len(all_sizes) // 2]
    threshold = body * options.get("heading_ratio", 1.12)
    max_len = options.get("max_heading_len", 90)
    heading_sizes = sorted({round(s, 1) for s in all_sizes if s >= threshold}, reverse=True)
    level_of = {size: min(position + 1, 4) for position, size in enumerate(heading_sizes)}

    pages = []
    for page in raw_pages:
        blocks = []
        for line in page["lines"]:
            text = line["text"]
            is_heading = (
                line["size"] >= threshold
                and len(text) <= max_len
                and not text.endswith(".")
            )
            if is_heading:
                blocks.append({
                    "type": "heading",
                    "text": text,
                    "level": level_of.get(line["size"], 2),
                    "slug": slugify(text),
                })
            else:
                blocks.append({"type": "para", "text": text})
        pages.append({"number": page["number"], "blocks": blocks})

    right = sum(
        1 for page in raw_pages for line in page["lines"] if line["x0"] > page["width"] * 0.5
    )
    total = sum(len(page["lines"]) for page in raw_pages) or 1
    if right / total > 0.35:
        warnings.append(
            "many lines begin in the right-hand half of the page; for a two-column "
            "layout the reading order may be wrong"
        )
    warnings.append("figures, tables and equations are not transcribed (text only)")

    return _structured(pages, warnings, "headings + page anchors", "pymupdf"), None


# --------------------------------------------------------------------------- #
# engine 2: GROBID (optional service)
# --------------------------------------------------------------------------- #

def _grobid_post(base_url, pdf_bytes, timeout):
    url = base_url.rstrip("/") + "/api/processFulltextDocument"
    body = b"".join([
        ("--" + GROBID_BOUNDARY + "\r\n").encode("ascii"),
        b'Content-Disposition: form-data; name="input"; filename="paper.pdf"\r\n',
        b"Content-Type: application/pdf\r\n\r\n",
        pdf_bytes,
        ("\r\n--" + GROBID_BOUNDARY + "--\r\n").encode("ascii"),
    ])
    import urllib.error
    import urllib.request

    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "Content-Type": "multipart/form-data; boundary=" + GROBID_BOUNDARY,
            "Accept": "application/xml",
            "User-Agent": USER_AGENT,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return response.read()
    except urllib.error.HTTPError as exc:
        raise IOError("GROBID returned HTTP %s" % exc.code)
    except Exception as exc:
        raise IOError("GROBID unreachable at %s (%s)" % (url, exc))


def engine_grobid(path, options):
    base_url = options.get("grobid_url")
    if not base_url:
        return None, "no GROBID service URL given (--grobid-url or GROBID_URL)"
    try:
        with open(path, "rb") as handle:
            pdf_bytes = handle.read()
    except OSError as exc:
        return None, "could not read the input file (%s)" % exc

    try:
        data = _grobid_post(base_url, pdf_bytes, options.get("timeout", DEFAULT_TIMEOUT))
    except IOError as exc:
        return None, str(exc)

    try:
        root = ET.fromstring(data)
    except ET.ParseError as exc:
        return None, "GROBID returned unparseable XML (%s)" % exc

    body = root.find(".//tei:text/tei:body", TEI_NS)
    if body is None:
        return None, "GROBID response had no body text"

    ordered = []
    current_page = 1
    title = root.find(".//tei:teiHeader//tei:titleStmt/tei:title", TEI_NS)
    if title is not None and title.text and title.text.strip():
        ordered.append({"page": 1, "type": "heading", "level": 1,
                        "text": collapse(title.text), "slug": slugify(title.text)})

    for node in body.iter():
        tag = _local(node.tag)
        if tag == "pb":
            number = node.get("n")
            current_page = int(number) if (number and number.isdigit()) else current_page + 1
        elif tag == "head":
            text = collapse("".join(node.itertext()))
            if text:
                ordered.append({"page": current_page, "type": "heading", "level": 2,
                                "text": text, "slug": slugify(text)})
        elif tag == "p":
            text = collapse("".join(node.itertext()))
            if text:
                ordered.append({"page": current_page, "type": "para", "text": text})

    if not ordered:
        return None, "GROBID produced no paragraphs"

    grouped = {}
    for item in ordered:
        grouped.setdefault(item["page"], []).append(
            {"type": item["type"], "text": item["text"], "level": item.get("level", 2),
             "slug": item.get("slug", slugify(item["text"]))}
        )
    pages = [{"number": number, "blocks": grouped[number]} for number in sorted(grouped)]

    warnings = ["figures, tables and equations are not transcribed (text only)"]
    return _structured(pages, warnings, "section headings + page anchors (GROBID TEI)", "grobid"), None


# --------------------------------------------------------------------------- #
# engine 3: pdftotext (Poppler)
# --------------------------------------------------------------------------- #

def engine_pdftotext(path, options):
    executable = shutil.which("pdftotext")
    if not executable:
        return None, "pdftotext (Poppler) not found on PATH"
    try:
        completed = subprocess.run(
            [executable, "-layout", path, "-"],
            capture_output=True,
            timeout=options.get("timeout", DEFAULT_TIMEOUT),
        )
    except Exception as exc:
        return None, "pdftotext failed (%s)" % exc
    if completed.returncode != 0:
        message = completed.stderr.decode("utf-8", "replace").strip()[:200]
        return None, "pdftotext exited %d (%s)" % (completed.returncode, message)

    text = completed.stdout.decode("utf-8", "replace")
    chunks = text.split("\f")
    if chunks and not chunks[-1].strip():
        chunks = chunks[:-1]

    pages = []
    for index, chunk in enumerate(chunks, start=1):
        blocks = [{"type": "heading", "level": 2, "text": "Page %d" % index,
                   "slug": "page-%d" % index}]
        for paragraph in re.split(r"\n\s*\n", chunk):
            collapsed = collapse(paragraph)
            if collapsed:
                blocks.append({"type": "para", "text": collapsed})
        pages.append({"number": index, "blocks": blocks})

    warnings = [
        "plain-text extraction: headings are not detected; every page is labelled 'Page N'",
        "figures, tables and equations are not transcribed",
    ]
    return _structured(pages, warnings, "page anchors + flat text", "pdftotext"), None


# --------------------------------------------------------------------------- #
# engine 4: bundled best-effort extractor (standard library only)
# --------------------------------------------------------------------------- #

def _pdf_unescape(raw):
    escapes = {b"n": b"\n", b"r": b"\r", b"t": b"\t", b"b": b"\b",
               b"f": b"\f", b"(": b"(", b")": b")", b"\\": b"\\"}
    out = bytearray()
    index = 0
    while index < len(raw):
        byte = raw[index:index + 1]
        if byte == b"\\" and index + 1 < len(raw):
            following = raw[index + 1:index + 2]
            if following in escapes:
                out.extend(escapes[following])
                index += 2
                continue
            octal = re.match(rb"[0-7]{1,3}", raw[index + 1:index + 4])
            if octal:
                out.append(int(octal.group(0), 8) & 0xFF)
                index += 1 + len(octal.group(0))
                continue
            index += 1
            continue
        out.extend(byte)
        index += 1
    return bytes(out)


def _hex_to_bytes(raw):
    cleaned = re.sub(rb"\s+", b"", raw)
    if len(cleaned) % 2:
        cleaned = cleaned[:-1]
    try:
        return bytes.fromhex(cleaned.decode("ascii"))
    except Exception:
        return b""


def _decode_token(token):
    if token.startswith(b"<"):
        return _hex_to_bytes(token[1:-1])
    return _pdf_unescape(token[1:-1])


def _array_pieces(payload):
    pieces = []
    for item in re.finditer(rb"\((?:\\.|[^()\\])*\)|<[0-9A-Fa-f\s]*>", payload):
        pieces.append(_decode_token(item.group(0)))
    return pieces


def _text_from_content(content):
    pieces = []
    pattern = re.compile(
        rb"\[((?:[^\[\]]|\\.)*)\]\s*TJ"
        rb"|(<[0-9A-Fa-f\s]*>|\((?:\\.|[^()\\])*\))\s*Tj",
        re.S,
    )
    for match in pattern.finditer(content):
        if match.group(1) is not None:
            pieces.extend(_array_pieces(match.group(1)))
        else:
            pieces.append(_decode_token(match.group(2)))
    return b" ".join(piece for piece in pieces if piece)


def engine_builtin(path, options):
    try:
        with open(path, "rb") as handle:
            data = handle.read()
    except OSError as exc:
        return None, "could not read the input file (%s)" % exc

    collected = []
    for match in re.finditer(rb"stream\r?\n(.*?)\r?\nendstream", data, re.S):
        chunk = match.group(1)
        try:
            chunk = zlib.decompress(chunk)
        except Exception:
            pass
        text = _text_from_content(chunk)
        if text:
            collected.append(text)

    decoded = collapse(b" ".join(collected).decode("latin-1", "replace"))
    if not decoded:
        return None, "best-effort extractor found no text (compressed object streams or a scanned PDF)"

    blocks = [{"type": "para", "text": decoded}]
    pages = [{"number": 1, "blocks": blocks}]
    warnings = [
        "best-effort standard-library extraction: page boundaries, headings, columns, "
        "figures, tables and equations are all lost; treat this as a rough text dump",
    ]
    return _structured(pages, warnings, "flat text (best effort)", "builtin"), None


ENGINES = {
    "pymupdf": engine_pymupdf,
    "grobid": engine_grobid,
    "pdftotext": engine_pdftotext,
    "builtin": engine_builtin,
}
AUTO_ORDER = ("pymupdf", "grobid", "pdftotext", "builtin")


# --------------------------------------------------------------------------- #
# rendering
# --------------------------------------------------------------------------- #

def render_body(result):
    lines = []
    for page in result["pages"]:
        lines.append("<!-- anchor: p%d -->" % page["number"])
        paragraph = []
        for block in page["blocks"]:
            if block["type"] == "heading":
                if paragraph:
                    lines.append(" ".join(paragraph))
                    lines.append("")
                    paragraph = []
                lines.append("<!-- anchor: p%d-%s -->" % (page["number"], block["slug"]))
                lines.append("%s %s" % ("#" * block.get("level", 2), block["text"]))
                lines.append("")
            else:
                paragraph.append(block["text"])
        if paragraph:
            lines.append(" ".join(paragraph))
            lines.append("")
    return "\n".join(lines).strip() + "\n"


def render_fidelity(result, source, requested_engine, attempts):
    summary = {
        "source": source,
        "engine": result["engine"],
        "requested_engine": requested_engine,
        "pages": result["page_count"],
        "characters": result["chars"],
        "headings": result["headings"],
        "structure": result["structure"],
        "warnings": result["warnings"],
    }
    lines = [
        "<!-- fidelity:notes:begin -->",
        "> **Extraction fidelity notes**",
        ">",
        "> - source: `%s`" % source,
        "> - engine used: `%s` (requested: `%s`)" % (result["engine"], requested_engine),
        "> - pages: %d | characters: %d | headings detected: %d"
        % (result["page_count"], result["chars"], result["headings"]),
        "> - structure: %s" % result["structure"],
    ]
    if attempts:
        lines.append("> - engines tried: %s" % "; ".join(attempts))
    lines.append(">")
    if result["warnings"]:
        lines.append("> - warnings:")
        for warning in result["warnings"]:
            lines.append(">   - %s" % warning)
    else:
        lines.append("> - warnings: none")
    lines.append("<!-- fidelity:%s -->" % json.dumps(summary, ensure_ascii=False))
    lines.append("<!-- fidelity:notes:end -->")
    return "\n".join(lines) + "\n"


def render_blank_notes(source, requested_engine, reason, attempts):
    summary = {
        "source": source,
        "engine": None,
        "requested_engine": requested_engine,
        "structure": "none",
        "warnings": [reason],
    }
    lines = [
        "<!-- fidelity:notes:begin -->",
        "> **Extraction fidelity notes**",
        ">",
        "> - source: `%s`" % source,
        "> - engine used: none (requested: `%s`)" % requested_engine,
        "> - structure: none",
    ]
    if attempts:
        lines.append("> - engines tried: %s" % "; ".join(attempts))
    lines.append(">")
    lines.append("> - warnings:")
    lines.append(">   - %s" % reason)
    lines.append("<!-- fidelity:%s -->" % json.dumps(summary, ensure_ascii=False))
    lines.append("<!-- fidelity:notes:end -->")
    return "\n".join(lines) + "\n"


# --------------------------------------------------------------------------- #
# engine selection + entry point
# --------------------------------------------------------------------------- #

def run_engine(name, path, options):
    result, reason = ENGINES[name](path, options)
    attempts = "%s: %s" % (name, "ok" if result else reason)
    return result, reason, attempts


def select_and_run(path, options):
    requested = options["engine"]
    if requested != "auto":
        result, reason, attempt = run_engine(requested, path, options)
        if result is None:
            return None, [attempt], "the requested engine '%s' was unavailable: %s" % (requested, reason)
        return result, [attempt], None

    attempts = []
    best = None
    best_attempt = None
    for name in AUTO_ORDER:
        if name == "grobid" and not options.get("grobid_url"):
            continue
        result, reason, attempt = run_engine(name, path, options)
        attempts.append(attempt)
        if result is not None and result["chars"] >= options["min_chars"]:
            return result, attempts, None
        if result is not None and (best is None or result["chars"] > best["chars"]):
            best = result
            best_attempt = attempt
    if best is not None:
        return best, attempts, None
    return None, attempts, None


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Convert a PDF to structured Markdown with anchors and fidelity notes (optional helper)."
    )
    parser.add_argument("pdf", help="path to the input PDF")
    parser.add_argument("--out", help="write Markdown here instead of stdout")
    parser.add_argument(
        "--engine", default="auto",
        choices=("auto", "pymupdf", "grobid", "pdftotext", "builtin"),
        help="extraction engine; 'auto' cascades from best to worst (default auto)",
    )
    parser.add_argument(
        "--grobid-url",
        default=os.environ.get("GROBID_URL"),
        help="base URL of a GROBID service (env GROBID_URL), e.g. http://localhost:8070",
    )
    parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT,
                        help="per-step timeout in seconds (default %d)" % DEFAULT_TIMEOUT)
    parser.add_argument("--min-chars", type=int, default=DEFAULT_MIN_CHARS,
                        help="minimum characters to accept an engine's output (default %d)" % DEFAULT_MIN_CHARS)
    parser.add_argument("--quiet", action="store_true", help="suppress progress messages on stderr")
    args = parser.parse_args(argv)

    if not os.path.isfile(args.pdf):
        sys.stderr.write("input file not found: %s\n" % args.pdf)
        return 1

    options = {
        "engine": args.engine,
        "grobid_url": args.grobid_url,
        "timeout": args.timeout,
        "min_chars": args.min_chars,
    }

    result, attempts, hard_error = select_and_run(args.pdf, options)

    if result is None:
        reason = hard_error or (
            "no engine could extract text; install PyMuPDF (`pip install pymupdf`), "
            "put `pdftotext` (Poppler) on PATH, or point --grobid-url at a GROBID service"
        )
        output = render_blank_notes(args.pdf, args.engine, reason, attempts)
        _emit(output, args)
        sys.stderr.write("no text extracted: %s\n" % reason)
        return 2

    output = render_fidelity(result, args.pdf, args.engine, attempts) + "\n" + render_body(result)
    _emit(output, args)

    if result["chars"] < args.min_chars:
        sys.stderr.write(
            "warning: only %d characters were extracted (below --min-chars %d); "
            "the PDF may be a scan or use an unsupported encoding\n"
            % (result["chars"], args.min_chars)
        )
        return 3
    if not args.quiet:
        sys.stderr.write(
            "extracted %d characters from %d pages using '%s'\n"
            % (result["chars"], result["page_count"], result["engine"])
        )
    return 0


def _emit(output, args):
    if args.out:
        try:
            with open(args.out, "w", encoding="utf-8") as handle:
                handle.write(output)
        except OSError as exc:
            sys.stderr.write("could not write %s: %s\n" % (args.out, exc))
            return 3
        sys.stderr.write("wrote %s\n" % args.out)
    else:
        sys.stdout.write(output)


if __name__ == "__main__":
    sys.exit(main())

from pathlib import Path

from mkdocs.structure.files import File

VENDOR = {
    "node_modules/mermaid/dist/mermaid.min.js": "assets/javascripts/mermaid.min.js",
    "node_modules/pdfjs-dist/build/pdf.min.mjs": "assets/js/pdf.min.js",
    "node_modules/pdfjs-dist/build/pdf.worker.min.mjs": "assets/js/pdf.worker.min.js",
    "node_modules/tablesort/dist/tablesort.min.js": "assets/js/tablesort.min.js",
    "node_modules/tablesort/dist/sorts/tablesort.dotsep.min.js": "assets/js/tablesort.dotsep.min.js",
}


def on_files(files, config):
    root = Path(__file__).resolve().parents[1]
    for source, destination in VENDOR.items():
        path = root / source
        if not path.is_file():
            raise FileNotFoundError(f"{source} is missing; run npm ci in the container")
        files.append(File.generated(config, destination, abs_src_path=str(path)))
    return files

import json
from pathlib import Path

from mkdocs.structure.files import File

# Source -> destination, shared with the dev image's Dockerfile, which copies
# only these files out of node_modules.
VENDOR = json.loads(Path(__file__).with_name("vendor.json").read_text(encoding="utf-8"))


def on_files(files, config):
    root = Path(__file__).resolve().parents[1]
    for source, destination in VENDOR.items():
        path = root / source
        if not path.is_file():
            raise FileNotFoundError(f"{source} is missing; run npm ci in the container")
        files.append(File.generated(config, destination, abs_src_path=str(path)))
    return files

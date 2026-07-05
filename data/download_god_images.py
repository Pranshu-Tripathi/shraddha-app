#!/usr/bin/env python3
"""Download generated god images from the Shraddha admin API.

Examples:
  ./data/download_god_images.py krishna
  ./data/download_god_images.py krishna shiva --limit 50
  ./data/download_god_images.py krishna --image-type all

Files are saved to:
  data/god/<god-name>/
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


API_BASE_URL = "https://shraddha-admin.vercel.app/api/images"
IMAGE_FIELDS = {
    "wallpaper": ("wallpaper_url",),
    "story": ("story_url",),
    "square": ("square_url",),
    "all": ("wallpaper_url", "story_url", "square_url"),
}
EXTENSIONS_BY_CONTENT_TYPE = {
    "image/avif": ".avif",
    "image/gif": ".gif",
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


def main() -> int:
    args = parse_args()
    output_root = args.output_root or Path(__file__).resolve().parent / "god"

    total_downloaded = 0
    total_skipped = 0

    for god_name in args.gods:
        god_id = slugify(god_name)
        destination = output_root / god_id
        destination.mkdir(parents=True, exist_ok=True)

        payload = fetch_json(
            args.api_base_url,
            {"god": god_id, "limit": str(args.limit)},
            timeout_s=args.timeout,
        )
        images = payload.get("images", [])
        if not isinstance(images, list):
            raise RuntimeError("Unexpected API response: `images` is not a list")

        print(f"{god_id}: found {len(images)} image records")
        for index, image in enumerate(images, start=1):
            if not isinstance(image, dict):
                continue

            for image_field in IMAGE_FIELDS[args.image_type]:
                image_url = image.get(image_field)
                if not image_url:
                    continue

                filename = filename_for(index, image, image_field)
                path_without_extension = destination / filename

                if existing_match(path_without_extension) and not args.force:
                    print(f"  skip existing {path_without_extension.name}.*")
                    total_skipped += 1
                    continue

                if args.dry_run:
                    print(f"  would download {image_field}: {image_url}")
                    continue

                path = download_image(
                    str(image_url),
                    path_without_extension,
                    timeout_s=args.timeout,
                    force=args.force,
                )
                print(f"  saved {path.relative_to(Path.cwd())}")
                total_downloaded += 1
                if args.sleep > 0:
                    time.sleep(args.sleep)

    print(f"Done. downloaded={total_downloaded} skipped={total_skipped}")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Download god images from the Shraddha admin API.",
    )
    parser.add_argument(
        "gods",
        nargs="+",
        help="God names or ids, e.g. krishna, shiva, ganesha.",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=20,
        help="Max records to request per god. Default: 20.",
    )
    parser.add_argument(
        "--image-type",
        choices=sorted(IMAGE_FIELDS),
        default="wallpaper",
        help="Which image URL field to download. Default: wallpaper.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        help="Output root. Default: data/god next to this script.",
    )
    parser.add_argument(
        "--api-base-url",
        default=API_BASE_URL,
        help=f"Admin images API URL. Default: {API_BASE_URL}",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=30,
        help="HTTP timeout in seconds. Default: 30.",
    )
    parser.add_argument(
        "--sleep",
        type=float,
        default=0,
        help="Optional delay between image downloads. Default: 0.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite files that appear to already exist.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Fetch metadata and print downloads without saving files.",
    )
    return parser.parse_args()


def fetch_json(
    api_base_url: str,
    query: dict[str, str],
    *,
    timeout_s: float,
) -> dict[str, Any]:
    url = f"{api_base_url}?{urlencode(query)}"
    request = Request(url, headers={"Accept": "application/json"})
    try:
        with urlopen(request, timeout=timeout_s) as response:
            raw = response.read()
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"API request failed: HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"API request failed: {exc.reason}") from exc

    data = json.loads(raw.decode("utf-8"))
    if not isinstance(data, dict):
        raise RuntimeError("Unexpected API response: top-level JSON is not an object")
    return data


def download_image(
    image_url: str,
    path_without_extension: Path,
    *,
    timeout_s: float,
    force: bool,
) -> Path:
    request = Request(image_url, headers={"Accept": "image/*"})
    try:
        with urlopen(request, timeout=timeout_s) as response:
            content_type = response.headers.get_content_type().lower()
            extension = EXTENSIONS_BY_CONTENT_TYPE.get(content_type, ".img")
            final_path = path_without_extension.with_suffix(extension)
            if final_path.exists() and not force:
                return final_path

            temp_path = final_path.with_suffix(f"{final_path.suffix}.part")
            with temp_path.open("wb") as file:
                while True:
                    chunk = response.read(1024 * 256)
                    if not chunk:
                        break
                    file.write(chunk)
            temp_path.replace(final_path)
            return final_path
    except HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Image download failed: HTTP {exc.code}: {detail}") from exc
    except URLError as exc:
        raise RuntimeError(f"Image download failed: {exc.reason}") from exc


def filename_for(index: int, image: dict[str, Any], image_field: str) -> str:
    image_id = str(image.get("id") or f"{index:03d}")[:8]
    god_id = slugify(str(image.get("god_id") or image.get("god_name") or "god"))
    festival = slugify(str(image.get("festival") or "image"))
    style = slugify(str(image.get("style") or image_field.replace("_url", "")))
    kind = image_field.replace("_url", "")
    return f"{index:03d}_{god_id}_{festival}_{style}_{kind}_{image_id}"


def existing_match(path_without_extension: Path) -> bool:
    return any(path_without_extension.parent.glob(f"{path_without_extension.name}.*"))


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9_]+", "-", value.strip().lower()).strip("-")
    return slug or "unknown"


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("Interrupted", file=sys.stderr)
        raise SystemExit(130)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)

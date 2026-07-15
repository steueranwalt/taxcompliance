#!/usr/bin/env python3
"""Flatten OneNote export: PageName/README.md (+ assets/) → PageName.md + assets/PageName/."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


def is_leaf_page_dir(path: Path) -> bool:
    if not path.is_dir():
        return False
    readme = path / "README.md"
    if not readme.is_file():
        return False
    names = {p.name for p in path.iterdir()}
    return names <= {"README.md", "assets"}


def flatten_tree(root: Path, dry_run: bool = False) -> tuple[int, int]:
    leaves = [p for p in root.rglob("*") if is_leaf_page_dir(p)]
    # deepest first
    leaves.sort(key=lambda p: len(p.parts), reverse=True)

    moved = 0
    for page_dir in leaves:
        parent = page_dir.parent
        title = page_dir.name
        target_md = parent / f"{title}.md"
        assets_src = page_dir / "assets"
        assets_dst = parent / "assets" / title

        if target_md.exists():
            print(f"SKIP conflict: {target_md}")
            continue

        text = (page_dir / "README.md").read_text(encoding="utf-8")
        if assets_src.is_dir():
            # rewrite relative asset links
            text = text.replace("](assets/", f"](assets/{title}/")
            text = text.replace('(assets/', f'(assets/{title}/')
            text = re.sub(r'(?<![(\[])assets/', f"assets/{title}/", text)

        print(f"{'DRY ' if dry_run else ''}{page_dir.relative_to(root)} -> {target_md.relative_to(root)}")
        if dry_run:
            moved += 1
            continue

        if assets_src.is_dir():
            assets_dst.parent.mkdir(parents=True, exist_ok=True)
            if assets_dst.exists():
                for item in assets_src.iterdir():
                    dest = assets_dst / item.name
                    if dest.exists():
                        if dest.is_dir():
                            shutil.rmtree(dest)
                        else:
                            dest.unlink()
                    shutil.move(str(item), str(dest))
                shutil.rmtree(assets_src)
            else:
                shutil.move(str(assets_src), str(assets_dst))

        target_md.write_text(text, encoding="utf-8")
        # remove leftover README and empty dir
        readme = page_dir / "README.md"
        if readme.exists():
            readme.unlink()
        # remove empty directories under page_dir
        for p in sorted(page_dir.rglob("*"), reverse=True):
            if p.is_file():
                p.unlink()
            elif p.is_dir():
                try:
                    p.rmdir()
                except OSError:
                    pass
        try:
            page_dir.rmdir()
        except OSError:
            shutil.rmtree(page_dir, ignore_errors=True)
        moved += 1

    # rewrite index links …/Page/README.md → …/Page.md
    link_re = re.compile(r"\(([^)\s]+)/README\.md\)")
    fixed = 0
    for md in root.rglob("*.md"):
        original = md.read_text(encoding="utf-8")
        updated = link_re.sub(r"(\1.md)", original)
        # also bare Page/README.md without rename of section indexes that stay as README.md in folders with children - OK
        if updated != original:
            if not dry_run:
                md.write_text(updated, encoding="utf-8")
            fixed += 1

    return moved, fixed


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "root",
        nargs="?",
        default=str(Path(__file__).resolve().parent.parent / "Notizbuch-fuer-Wissen"),
    )
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    root = Path(args.root)
    if not root.is_dir():
        raise SystemExit(f"Not a directory: {root}")
    moved, fixed = flatten_tree(root, dry_run=args.dry_run)
    print(f"Done. pages={moved} indexes_updated={fixed} dry_run={args.dry_run}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

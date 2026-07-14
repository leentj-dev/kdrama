"""
scenes/*.json -> scenes/manifest.json

Mirrors kpop's manifest: one lightweight summary per scene plus a content hash,
so the app can render the feed and detect which scenes changed (and need
re-downloading) without loading every line.

Usage:
    python3 build_manifest.py ../app/assets/scenes
"""

import hashlib
import json
import os
import sys
import time


def main():
    scenes_dir = sys.argv[1] if len(sys.argv) > 1 else "../app/assets/scenes"
    entries = []

    files = sorted(f for f in os.listdir(scenes_dir)
                   if f.endswith(".json") and f != "manifest.json")

    for i, fname in enumerate(files):
        path = os.path.join(scenes_dir, fname)
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        scene = json.loads(raw)
        digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()[:16]
        entries.append({
            "id": scene["id"],
            "title": scene.get("title", ""),
            "drama": scene.get("drama", ""),
            "youtubeId": scene.get("youtubeId", ""),
            "wordCount": len(scene.get("words", [])),
            # order: file position for now; bump to add-time (unix sec) later.
            "order": i + 1,
            "hash": digest,
        })

    out = os.path.join(scenes_dir, "manifest.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
    print(f"-> {out}: {len(entries)}개 장면")
    for e in entries:
        print(f"   {e['id']}  ({e['wordCount']} words, {e['drama']})")


if __name__ == "__main__":
    main()

"""
Whisper SRT -> scene JSON 골격.

SRT 의 (start, end, korean) 만 채운 초안을 만든다.
romanization / english / note 등 나머지 필드는 다음 단계(Claude 정제)에서 채운다.

정제 단계에서 Claude 가 할 일:
  - 아웃트로/채널 노이즈 제거 ("다음 영상에서 만나요" 등)
  - 잘게 쪼개진 조각을 문장 단위로 병합
  - romanization 생성
  - 번역 (english + 필요 언어)
  - 문법 note (존댓말/반말, 준말, 어미 설명)
  - ★ 명대사 표시

사용:
    python3 build_scene.py dokkaebi-first-snow.srt \\
        --id dokkaebi-first-snow --title "첫눈 고백" \\
        --drama "도깨비" --youtube d4GaQ30slGI \\
        > ../app/assets/scenes/dokkaebi-first-snow.draft.json
"""

import argparse
import json
import re
import sys

TIME = re.compile(r"(\d+):(\d+):(\d+),(\d+) --> (\d+):(\d+):(\d+),(\d+)")


def parse_srt(path):
    lines = []
    with open(path, encoding="utf-8") as f:
        blocks = f.read().strip().split("\n\n")
    for b in blocks:
        rows = b.strip().splitlines()
        if len(rows) < 3:
            continue
        m = TIME.search(rows[1])
        if not m:
            continue
        h1, m1, s1, ms1, h2, m2, s2, ms2 = map(int, m.groups())
        text = " ".join(rows[2:]).strip()
        if not text:
            continue
        lines.append({
            "korean": text,
            "romanization": "",
            "english": "",
            "note": "",
            "start": round(((h1 * 60 + m1) * 60 + s1) * 1000 + ms1) / 1000,
            "end": round(((h2 * 60 + m2) * 60 + s2) * 1000 + ms2) / 1000,
        })
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("srt")
    ap.add_argument("--id", required=True)
    ap.add_argument("--title", default="")
    ap.add_argument("--drama", default="")
    ap.add_argument("--youtube", required=True)
    ap.add_argument("--offset", type=float, default=0)
    args = ap.parse_args()

    scene = {
        "id": args.id,
        "title": args.title,
        "drama": args.drama,
        "youtubeId": args.youtube,
        "introOffset": args.offset,
        "lines": parse_srt(args.srt),
    }
    json.dump(scene, sys.stdout, ensure_ascii=False, indent=2)
    print(file=sys.stderr)
    print(f"[골격] {len(scene['lines'])} 줄. 다음: Claude 로 번역/정제.",
          file=sys.stderr)


if __name__ == "__main__":
    main()

#!/usr/bin/env bash
# 유튜브 K-드라마 클립 -> Whisper 대사+타임스탬프(SRT)
#
# 검증된 파이프라인 (도깨비 클립으로 확인):
#   1) yt-dlp 로 오디오 다운로드 (android client 로 봇차단 우회)
#   2) ffmpeg 로 16kHz 모노 WAV 변환
#   3) whisper-cli large-v3-turbo 로 한국어 STT
#
# 중요 옵션:
#   -ng      : GPU(Metal) 끄기. 현재 whisper-cpp 가 이 Mac 의 Metal 에서 크래시남
#   -mc 0    : max-context 0. 배경음악 구간에서 반복/환청(hallucination) 방지
#   -bs 5    : beam search 5. 정확도 향상
#
# 사용:  ./transcribe.sh <youtube-id> <출력이름>
# 예:    ./transcribe.sh d4GaQ30slGI dokkaebi-first-snow

set -euo pipefail

VIDEO_ID="${1:?usage: transcribe.sh <youtube-id> <out-name>}"
OUT="${2:?usage: transcribe.sh <youtube-id> <out-name>}"
MODEL="${WHISPER_MODEL:-ggml-large-v3-turbo.bin}"

echo "[1/3] 오디오 다운로드: $VIDEO_ID"
yt-dlp -f 18 --extractor-args "youtube:player_client=android" \
  -o "${OUT}.%(ext)s" "https://www.youtube.com/watch?v=${VIDEO_ID}"

echo "[2/3] WAV 변환 (16kHz mono)"
ffmpeg -y -i "${OUT}.mp4" -ar 16000 -ac 1 -c:a pcm_s16le "${OUT}.wav" 2>/dev/null

echo "[3/3] Whisper STT (large-v3-turbo)"
whisper-cli -m "$MODEL" -f "${OUT}.wav" -l ko -ng -mc 0 -bs 5 \
  -osrt -of "$OUT"

echo "완료 -> ${OUT}.srt"
echo "다음: build_scene.py 로 SRT -> scene JSON 골격 생성, 그 다음 Claude 로 번역/정제"

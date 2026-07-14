# kdrama (K-Drama Hangul)

K-드라마 장면으로 한국어 배우기 앱 (외국인 대상). kpop-hangul 의 자매 앱.

## 컨셉

kpop-hangul 이 "K-pop 곡의 단어"로 가르친다면, kdrama 는 "K-드라마 명장면의 대사"로
가르친다. 유입 키워드가 달라 새 사용자층(드라마 팬)을 잡는다.

- 학습 단위: 곡의 단어 → **장면의 대사(문장)**
- 카드: 단일 timestamp 단어 → **start/end 구간을 가진 대사** (구간 반복 재생)

## Tech Stack

- Flutter (kpop 과 동일 엔진 이식)
- youtube_player_iframe — **YouTube 공식 임베드** (저작권 안전: 조회수·광고가 원 채널로)
- flutter_tts — 대사 발음 듣기
- shared_preferences — 로컬 상태 (언어, 싱크 오프셋, 테마)
- 백엔드 없음: 번들 JSON + GitHub raw 동기화 (kpop 과 동일)

## 구조

```
app/
  lib/
    models/scene.dart          Scene / LineEntry / SceneSummary
    data/scene_repository.dart  번들 + GitHub 동기화 (content-hash 변경감지)
    screens/
      feed_screen.dart          장면 목록
      scene_screen.dart         YouTube 임베드 + 대사 카드 싱크 + 구간반복(A-B)
    widgets/line_card.dart      대사 카드 (한국어/로마자/번역/문법note)
    config/                     app_config, theme_controller
    utils/themes.dart           장면별 그라디언트 테마
  assets/scenes/
    manifest.json               장면 요약 + content hash
    <scene-id>.json             장면 데이터 (대사 배열)
pipeline/
  transcribe.sh                 유튜브 -> Whisper SRT (검증된 옵션)
  build_scene.py                SRT -> scene JSON 골격
  build_manifest.py             scenes/*.json -> manifest.json
```

## 콘텐츠 파이프라인 (검증 완료 — 도깨비 클립)

```
유튜브 클립
  └[yt-dlp + ffmpeg]→ 16kHz WAV        (로컬, 무료)
  └[whisper-cli large-v3-turbo]→ SRT   (로컬, 무료; 대사+타임스탬프)
  └[build_scene.py]→ scene JSON 골격
  └[Claude 정제]→ 번역/로마자/문법note/명대사 표시 + 노이즈 제거
  └[build_manifest.py]→ manifest 갱신
```

Whisper 옵션(중요): `-ng` (Metal 크래시 회피), `-mc 0 -bs 5` (배경음악 구간 환청 방지).
large-v3-turbo **원본** 모델 사용 (양자화 q5_0 은 이 whisper-cpp 버전에서 출력 깨짐).

## Project Rules (kpop 계승)

- 한국어 UI + 다국어 번역 병행
- **저작권**: 클립을 앱에 직접 넣지 않고 YouTube 공식 임베드로만 재생. 대사는 전문
  나열이 아니라 학습 단위(문장+문법)로 가공 → "교육적 인용"에 가깝게.
- 대사 텍스트는 Whisper 로 자체 생성 (방송사 자막 파일 복제 아님).

## 상태

v0: 엔진 이식 완료, 도깨비 첫눈 고백 장면 1개 번들. `flutter analyze` 통과.
다음: 장면 여러 개 추가(배치), 실기기 구동 확인, (kpop 처럼) 광고/Firebase 붙이기.

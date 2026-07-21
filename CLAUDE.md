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
    main.dart / app.dart        부트스트랩 (MobileAds + Firebase + Remote Config)
    models/scene.dart           WordEntry / Scene / SceneSummary
    data/scene_repository.dart  번들 + GitHub 동기화 (content-hash 변경감지)
    screens/
      feed_screen.dart          장면 목록
      scene_screen.dart         YouTube 임베드 + 단어 카드 timestamp 싱크
    widgets/
      word_card.dart            단어 카드 (한국어/로마자/9개 언어 뜻/창작 예문)
      native_ad_card.dart       피드 사이 네이티브 광고
    config/                     app_config, theme_controller, remote_config
    utils/                      themes.dart(장면별 그라디언트), ads.dart
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
- **저작권 (kpop 과 동일 원칙)**: 드라마 대사(대본)는 어문저작물이라 문장을 그대로
  쓰지 않는다. **개별 단어만 추출**(단어 자체는 저작권 대상 아님)하고, 예문은 드라마와
  무관하게 **직접 창작**해서 가르친다 = kpop 의 "가사 직접 인용 금지, 단어만" 규칙.
- 영상은 **YouTube 공식 임베드**로만 재생(영상 저작권은 원 채널로). 앱은 클립을 담지
  않고, 대사 문장을 텍스트로 재현하지 않는다.
- 데이터 모델은 `WordEntry`(korean/뜻/품사/원저작 example/timestamp) — kpop 과 사실상
  동일. Whisper 는 "이 장면에 어떤 단어가 나오나"를 찾는 용도로만 쓰고, 뽑은 문장을
  그대로 배포하지 않는다.
- **번역 언어(단어 뜻)**: english/spanish/portuguese/indonesian/japanese/thai/french +
  **chinese(简体)/chineseTraditional(繁體)**. K-드라마는 중화권 시청량이 커서 중국어 필수.
  새 장면을 만들 때 **모든 단어에 이 9개 필드를 반드시 채운다**. UI 언어 목록은
  `config/app_config.dart` 의 `uiLanguages`.
- **상세(scene) 화면에는 offset/싱크 조정 UI 없음** — timestamp 기반 자동 하이라이트만.
  (사용자 싱크 보정 불필요.)

## 상태 (2026-07)

엔진 이식 + 광고/Firebase Remote Config 연동 완료. 콘텐츠 **544 장면** 번들.

| 드라마 | 장면 | 에피소드 |
|---|---|---|
| Crash Landing on You | 229 | EP1–16 전편 |
| 도깨비(Goblin) | 191 | EP1–16 전편 |
| 눈물의 여왕(Queen of Tears) | 123 | EP1–16 전편 |
| dokkaebi-first-snow | 1 | v0 샘플 |

장면 추가/수정 후에는 반드시 `pipeline/build_manifest.py` 로 manifest 를 갱신한다
(manifest 장면 수 = `assets/scenes/*.json` - 1 이어야 정상).

다음: 스토어 출시(Android/iOS), 이후 새 드라마 추가.

# Conversation Log - 2026-07-21

## Summary
진행 상황 점검 후(콘텐츠는 CLOY/도깨비/눈물의 여왕 3개 드라마 EP1-16 전편, 총 544 장면 완료)
CLAUDE.md 의 낡은 상태 섹션을 갱신하고, Android/iOS 스토어 출시 준비를 마쳤다.
릴리스 업로드 키스토어를 새로 만들어 AAB 를 서명 빌드했고, 없던 iOS 플랫폼을 생성해
Firebase/AdMob/아이콘까지 배선한 뒤 무서명 릴리스 컴파일로 검증했다.

## Issues & Solutions

### CLAUDE.md 상태 섹션이 v0 시점에 멈춰 있었음
- **Problem**: "장면 1개 번들, 다음: 광고/Firebase 붙이기"로 적혀 있었으나 실제로는
  544 장면 + 광고 + Firebase Remote Config 가 이미 완료 상태였다.
- **Cause**: 콘텐츠 배치 작업(66 커밋)을 진행하며 문서를 갱신하지 않음.
- **Solution**: 상태 섹션을 드라마별 장면 수 표로 재작성, 구조 섹션도 실제 코드에 맞게
  수정(`LineEntry`→`WordEntry`, `line_card.dart`→`word_card.dart`/`native_ad_card.dart`,
  `remote_config.dart`·`ads.dart` 추가). manifest 재빌드 규칙도 명시.
- **Files changed**: `CLAUDE.md`

### Android release 가 디버그 키로 서명되고 있었음 (Play Store 업로드 불가)
- **Problem**: `key.properties`/키스토어가 없어 `build.gradle.kts` 가
  `signingConfig = signingConfigs.getByName("debug")` 상태였다.
- **Cause**: `flutter create` 기본 템플릿의 TODO 가 그대로 남아 있었음.
- **Solution**: kdrama 전용 업로드 키스토어(RSA 2048 / 10,000일)를 생성하고
  `android/key.properties` 작성(둘 다 이미 .gitignore 대상). Gradle 에 release
  signingConfig 를 추가하되 key.properties 가 없으면 debug 로 폴백하게 해서 fresh
  clone 에서도 `flutter run --release` 가 동작하도록 했다.
  빌드 후 `jarsigner -verify` 로 `CN=leentj` 서명(디버그 키 아님)을 확인.
- **Files changed**: `app/android/app/build.gradle.kts`, `app/android/key.properties`(비추적),
  `app/android/app/upload-keystore.jks`(비추적)

### iOS 플랫폼 자체가 없었음
- **Problem**: `app/ios` 디렉터리가 존재하지 않아 iOS 빌드가 불가능.
- **Cause**: 프로젝트가 Android 전용으로만 생성돼 있었음.
- **Solution**: `flutter create --platforms=ios --org dev.leentj` 로 생성(번들
  `dev.leentj.kdramaHangul` — 언더스코어가 iOS 번들 ID 에 불가해 Android 의
  `dev.leentj.kdrama_hangul` 과 표기가 다름). Firebase CLI 로 iOS 앱 등록 후
  `GoogleService-Info.plist` 를 받아 xcodeproj gem 으로 Runner 타깃 리소스에 연결.
  Podfile `platform :ios, '13.0'` 활성화, Info.plist 에 `GADApplicationIdentifier`
  와 ATT 문구 추가, 표시 이름을 Android 와 같은 "K-Drama Hangul" 로 통일.
  `flutter build ios --release --no-codesign` 성공(EXIT=0)으로 검증.
- **Files changed**: `app/ios/**`, `app/pubspec.yaml`, `.gitignore`

### iOS 앱 아이콘이 Flutter 기본 이미지였음
- **Problem**: `flutter_launcher_icons` 설정이 `ios: false` 였다.
- **Solution**: `ios: true` + `remove_alpha_ios: true` 로 재생성(App Store 는 1024
  아이콘의 알파 채널을 거부). `sips` 로 `hasAlpha: no` 확인.
- **Files changed**: `app/pubspec.yaml`, `app/ios/Runner/Assets.xcassets/**`

## Decisions Made
- 버전 `0.1.0+1` → `1.0.0+1` (첫 스토어 출시 기준).
- Android 산출물은 GitHub Release 용 APK 가 아니라 **Play Console 업로드용 AAB**
  (48.9MB, `build/app/outputs/bundle/release/app-release.aab`).
- 키스토어/`key.properties`/`GoogleService-Info.plist` 는 커밋하지 않는다
  (기존 `google-services.json` 처리 방식과 동일). 키 정보는 Claude 메모리
  `kdrama-release-keys.md` 에 기록.
- trotcard 메모리의 "키스토어 없음" 기술이 사실과 달라 새 키 정보로 갱신함.
- 아이콘 재생성 후 Android res 바이트가 동일해 Gradle 이 기존 AAB 를 재사용한 것은
  정상(내용 기반 up-to-date 판정).

## TODO / Follow-up
- **AdMob iOS App ID 교체 필수**: 현재 `Info.plist` 의 `GADApplicationIdentifier` 는
  Google 공식 테스트 ID(`ca-app-pub-3940256099942544~1458002511`). AdMob 콘솔에서
  iOS 앱을 만들고 실제 ID 와 광고 단위로 바꿔야 실 수익 발생.
- **Play Console 업로드는 수동**: 앱 생성, 스토어 등록정보, 개인정보처리방침 URL,
  데이터 보안 설문, 콘텐츠 등급 후 AAB 업로드/심사.
- **iOS 서명 미설정**: Apple Developer 계정으로 Xcode 팀 지정 + App Store Connect
  앱 생성 후에야 IPA 빌드 가능. 현재는 `--no-codesign` 컴파일만 검증됨.
- 키스토어(`upload-keystore.jks`) 별도 백업 — 분실 시 앱 업데이트 영구 불가.
- CocoaPods 가 Profile 빌드 구성 경고를 냄(Flutter 템플릿의 알려진 무해한 경고).
- 의존성 20개가 상위 버전 존재(`flutter pub outdated`) — 출시 후 정리 고려.

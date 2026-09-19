#!/bin/bash
#
# SendbirdMarkdownUI / SendbirdNetworkImage / Splash 를 static xcframework 로 빌드한다.
#
# Xcode 27 은 SwiftPM 소스 패키지를 iOS 15.0 미만으로 빌드하지 못한다. 그래서
# SendbirdAIAgentCore 의 swiftinterface (ios14.0) 를 재컴파일할 때 소스 의존을
# 찾지 못하고 실패한다. 이 스크립트가 만드는 xcframework 는 ios14.0 으로 고정된
# swiftinterface 를 담고 있어 그 재컴파일을 통과시킨다.
#
# static 인 이유: SendbirdAIAgentCore.xcframework 가 지금처럼 이 모듈들을 자기
# 안에 흡수한 자기완결 바이너리로 남아야 한다. CocoaPods 고객은 Core 만 받는다.
#
# 사용:
#   Xcode 26 으로 실행해야 한다. Xcode 27 은 iOS 14 타깃을 거부한다.
#   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer ./scripts/build_xcframeworks.sh

set -Ee
trap 'echo "⚠️ 빌드 실패: line $LINENO"' ERR

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/build"
OUT="${BUILD}/xcframeworks"
SPLASH_TAG="${SPLASH_TAG:-0.16.0}"
SPLASH_SRC="${BUILD}/splash-${SPLASH_TAG}"

rm -rf "${BUILD}"
mkdir -p "${OUT}"

# 한 스킴을 device / simulator 두 슬라이스로 archive 한다.
archive_slices() {
  local project="$1" scheme="$2" workdir="$3"
  for slice in device simulator; do
    local destination="generic/platform=iOS"
    [ "${slice}" = "simulator" ] && destination="generic/platform=iOS Simulator"
    echo "📱 ${scheme} — ${slice}"
    ( cd "${workdir}" && xcodebuild archive \
        -project "${project}" \
        -scheme "${scheme}" \
        -configuration Release \
        -destination "${destination}" \
        -archivePath "${BUILD}/${scheme}-${slice}.xcarchive" \
        -derivedDataPath "${BUILD}/dd-${scheme}" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGNING_ALLOWED=NO \
        > "${BUILD}/${scheme}-${slice}.log" 2>&1 ) \
      || { echo "❌ ${scheme} ${slice} 빌드 실패 — ${BUILD}/${scheme}-${slice}.log"; exit 1; }
  done
}

# archive 두 벌에서 한 프레임워크를 골라 xcframework 로 묶고 NOTICE 를 동봉한다.
make_xcframework() {
  local framework="$1" scheme="$2" notice="$3"
  xcodebuild -create-xcframework \
    -framework "${BUILD}/${scheme}-device.xcarchive/Products/Library/Frameworks/${framework}.framework" \
    -framework "${BUILD}/${scheme}-simulator.xcarchive/Products/Library/Frameworks/${framework}.framework" \
    -output "${OUT}/${framework}.xcframework" > /dev/null
  cp "${ROOT}/Licenses/${notice}" "${OUT}/${framework}.xcframework/LICENSE"
  echo "✅ ${framework}.xcframework"
}

echo "🔨 SendbirdMarkdownUI / SendbirdNetworkImage"
( cd "${ROOT}" && xcodegen -s binary-frameworks.yml > /dev/null )
archive_slices "SendbirdBinaryFrameworks.xcodeproj" "SendbirdMarkdownUI" "${ROOT}"
make_xcframework "SendbirdMarkdownUI"   "SendbirdMarkdownUI" "SendbirdMarkdownUI-NOTICE.txt"
make_xcframework "SendbirdNetworkImage" "SendbirdMarkdownUI" "SendbirdNetworkImage-NOTICE.txt"

# Splash 는 업스트림 소스를 그대로 쓴다. 이 레포의 Sources/Splash 는 CocoaPods
# 전용 포크(`any` 키워드 지원 추가)라 SPM 고객이 지금 받는 코드와 다르다.
echo "🔨 Splash (JohnSundell ${SPLASH_TAG})"
git -c advice.detachedHead=false clone --quiet --depth 1 --branch "${SPLASH_TAG}" https://github.com/JohnSundell/Splash "${SPLASH_SRC}"
cp "${ROOT}/splash-framework.yml" "${SPLASH_SRC}/"
( cd "${SPLASH_SRC}" && xcodegen -s splash-framework.yml > /dev/null )
archive_slices "SplashBinary.xcodeproj" "Splash" "${SPLASH_SRC}"
make_xcframework "Splash" "Splash" "SendbirdSplash-NOTICE.txt"

# --- CocoaPods 용 ---------------------------------------------------------------
# 고객이 use_frameworks! 로 통합하므로 동적이어야 한다. 정적 vendored_frameworks
# 를 섞으면 pod install 이 거부한다. Splash 는 이 레포의 포크를 쓴다.
# 자세한 이유는 binary-frameworks-cocoapods.yml 주석 참조.
PODS_OUT="${BUILD}/xcframeworks-cocoapods"
mkdir -p "${PODS_OUT}"

# $1 아카이브 안의 프레임워크 이름 / $2 archive_slices 에 쓴 스킴 /
# $3 산출물 이름 (Splash 는 모듈명 Splash, 파일명 SendbirdSplash 로 다르다) / $4 NOTICE
make_pods_xcframework() {
  local framework="$1" scheme="$2" out_name="$3" notice="$4"
  xcodebuild -create-xcframework \
    -framework "${BUILD}/${scheme}-device.xcarchive/Products/Library/Frameworks/${framework}.framework" \
    -framework "${BUILD}/${scheme}-simulator.xcarchive/Products/Library/Frameworks/${framework}.framework" \
    -output "${PODS_OUT}/${out_name}.xcframework" > /dev/null
  cp "${ROOT}/Licenses/${notice}" "${PODS_OUT}/${out_name}.xcframework/LICENSE"
  echo "✅ ${out_name}.xcframework (CocoaPods)"
}

echo ""
echo "🔨 CocoaPods 용 (dynamic)"
( cd "${ROOT}" && xcodegen -s binary-frameworks-cocoapods.yml > /dev/null )
archive_slices "SendbirdBinaryFrameworksCocoaPods.xcodeproj" "SendbirdMarkdownUI" "${ROOT}"
make_pods_xcframework "SendbirdMarkdownUI"   "SendbirdMarkdownUI" "SendbirdMarkdownUI"   "SendbirdMarkdownUI-NOTICE.txt"
make_pods_xcframework "SendbirdNetworkImage" "SendbirdMarkdownUI" "SendbirdNetworkImage" "SendbirdNetworkImage-NOTICE.txt"
archive_slices "SendbirdBinaryFrameworksCocoaPods.xcodeproj" "SendbirdSplash" "${ROOT}"
# 산출물 이름은 Splash.xcframework 다. CocoaPods 는 xcframework 파일명으로
# -framework 를 만들기 때문에 안쪽 Splash.framework 와 같아야 한다.
make_pods_xcframework "Splash" "SendbirdSplash" "Splash" "SendbirdSplash-NOTICE.txt"

echo ""
echo "📦 zip + checksum"
cd "${OUT}"
# checksums.env 는 릴리즈 CI 가 읽어서 Package.swift 에 써 넣는다.
: > checksums.env
for framework in SendbirdMarkdownUI SendbirdNetworkImage Splash; do
  zip -qr "${framework}.xcframework.zip" "${framework}.xcframework"
  sum="$(swift package compute-checksum "${framework}.xcframework.zip")"
  printf "%-24s %s\n" "${framework}" "${sum}"
  case "${framework}" in
    SendbirdMarkdownUI)   echo "MARKDOWNUI_CHECKSUM=${sum}"   >> checksums.env ;;
    SendbirdNetworkImage) echo "NETWORKIMAGE_CHECKSUM=${sum}" >> checksums.env ;;
    Splash)               echo "SPLASH_CHECKSUM=${sum}"       >> checksums.env ;;
  esac
done

echo ""
echo "📦 zip + checksum (CocoaPods)"
# 잎 pod 은 자기 릴리즈 태그(SendbirdMarkdownUI-v1.2.0 등)에 자산을 붙인다.
# SPM 자산과 다른 릴리즈라 파일명이 같아도 겹치지 않는다.
cd "${PODS_OUT}"
for framework in SendbirdMarkdownUI SendbirdNetworkImage Splash; do
  zip -qr "${framework}.xcframework.zip" "${framework}.xcframework"
  sum="$(swift package compute-checksum "${framework}.xcframework.zip")"
  printf "%-24s %s\n" "${framework}" "${sum}"
done

echo ""
echo "✅ 완료: ${OUT}"
echo "✅ 완료: ${PODS_OUT}"

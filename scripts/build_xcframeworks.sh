#!/bin/bash
#
# SendbirdMarkdownUI / SendbirdNetworkImage / Splash 를 동적 xcframework 로 빌드한다.
#
# Xcode 27 은 SwiftPM 소스 패키지를 iOS 15.0 미만으로 빌드하지 못한다. 그래서
# SendbirdAIAgentCore 의 swiftinterface (ios14.0) 를 재컴파일할 때 소스 의존을
# 찾지 못하고 실패한다. 이 스크립트가 만드는 xcframework 는 ios14.0 으로 고정된
# swiftinterface 를 담고 있어 그 재컴파일을 통과시킨다.
#
# 동적인 이유: static 으로 만들면 Core 가 세 모듈의 코드를 자기 안으로 흡수하고,
# 고객 앱에는 심볼이 0개인 51KB 짜리 빈 dylib 세 개가 임베드된다. 빈 이미지라
# dSYM 이 만들어지지 않아 App Store Connect 가 업로드마다 경고를 세 번 낸다.
# 동적으로 만들면 여기서 만든 dSYM 이 고객 아카이브까지 따라간다.
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

# Becomes CFBundleShortVersionString in each framework's Info.plist.
# GENERATE_INFOPLIST_FILE omits the key entirely when the value is empty, and
# App Store Connect then rejects the upload with
# "missing the required key: CFBundleShortVersionString".
# The release CI passes DISTRIBUTION_PACKAGE_VERSION.
if [ -z "${MARKETING_VERSION:-}" ]; then
  echo "❌ MARKETING_VERSION is required. Example: MARKETING_VERSION=1.0.1 $0"
  exit 1
fi

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
        MARKETING_VERSION="${MARKETING_VERSION}" \
        > "${BUILD}/${scheme}-${slice}.log" 2>&1 ) \
      || { echo "❌ ${scheme} ${slice} 빌드 실패 — ${BUILD}/${scheme}-${slice}.log"; exit 1; }
  done
}

# archive 두 벌에서 한 프레임워크를 골라 xcframework 로 묶고 NOTICE 를 동봉한다.
#
# -debug-symbols 로 슬라이스마다 dSYM 을 같이 넣는다. 이게 없으면 고객이 앱을
# 아카이브할 때 이 프레임워크의 dSYM 이 없어서 App Store Connect 가
# "Upload Symbols Failed" 를 내고, 크래시 리포트도 심볼화되지 않는다.
# SendbirdChatSDK 와 SendbirdAIAgentCore 가 쓰는 방식과 같다.
make_xcframework() {
  local framework="$1" scheme="$2" notice="$3"
  local args=()
  for slice in device simulator; do
    local archive="${BUILD}/${scheme}-${slice}.xcarchive"
    local dsym="${archive}/dSYMs/${framework}.framework.dSYM"
    [ -d "${dsym}" ] || { echo "❌ dSYM 이 없습니다: ${dsym}"; exit 1; }
    args+=(-framework "${archive}/Products/Library/Frameworks/${framework}.framework")
    args+=(-debug-symbols "${dsym}")
  done
  xcodebuild -create-xcframework "${args[@]}" \
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
echo "✅ 완료: ${OUT}"

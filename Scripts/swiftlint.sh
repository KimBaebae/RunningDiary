#!/bin/bash
# SwiftLint runner script
# Usage:
#   ./Scripts/swiftlint.sh          # lint (warning only)
#   ./Scripts/swiftlint.sh --fix    # auto-fix correctable violations
#   ./Scripts/swiftlint.sh --strict # treat warnings as errors
#
# SwiftLint는 Homebrew로 설치해서 사용한다: brew install swiftlint

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXPECTED_VERSION="0.65.0"

# Homebrew(arm64) 경로를 먼저 본다. Intel Homebrew(/usr/local)에 남은 구버전
# x86_64 바이너리가 PATH를 선점해 sourcekitd 로딩에 실패하는 것을 피하기 위함.
SWIFTLINT_BIN=""
for candidate in /opt/homebrew/bin/swiftlint "$(command -v swiftlint || true)" /usr/local/bin/swiftlint; do
    if [ -n "${candidate}" ] && [ -x "${candidate}" ]; then
        SWIFTLINT_BIN="${candidate}"
        break
    fi
done

if [ -z "${SWIFTLINT_BIN}" ]; then
    echo "❌ SwiftLint를 찾을 수 없습니다. 아래 명령으로 설치해 주세요:"
    echo "   brew install swiftlint"
    exit 1
fi

INSTALLED_VERSION="$(${SWIFTLINT_BIN} version)"

if [ "${INSTALLED_VERSION}" != "${EXPECTED_VERSION}" ]; then
    echo "⚠️  SwiftLint 버전 불일치: 설치됨 ${INSTALLED_VERSION} / 기대값 ${EXPECTED_VERSION}"
    echo "    규칙 판정이 달라질 수 있습니다."
fi

echo "==> SwiftLint ${INSTALLED_VERSION}"

cd "${REPO_ROOT}"

if [ "${1:-}" = "--fix" ]; then
    echo "==> Running SwiftLint auto-fix..."
    "${SWIFTLINT_BIN}" --fix --config .swiftlint.yml
    echo "==> Fix complete. Running lint to show remaining issues..."
    "${SWIFTLINT_BIN}" lint --config .swiftlint.yml
elif [ "${1:-}" = "--strict" ]; then
    echo "==> Running SwiftLint (strict mode)..."
    "${SWIFTLINT_BIN}" lint --strict --config .swiftlint.yml
else
    echo "==> Running SwiftLint..."
    "${SWIFTLINT_BIN}" lint --config .swiftlint.yml
fi

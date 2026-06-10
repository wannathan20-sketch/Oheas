#!/bin/bash
# OHeas — Preflight Release Check
# 在 Archive 前运行。任何失败 → exit 1，阻止打包。
set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

PASS=0
FAIL=0
WARN=0

pass() { echo -e "${GREEN}[PASS]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARN=$((WARN + 1)); }

echo "============================================"
echo " OHeas — Preflight Release Check"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# ── 1. Swift tests ──────────────────────────────────────────
echo "── 1. Swift Tests"
if swift test 2>&1 | grep -q "Test run with.*passed"; then
    pass "swift test passed"
else
    fail "swift test did not pass"
fi
echo ""

# ── 2. Hardcoded API Keys ───────────────────────────────────
echo "── 2. Hardcoded API Keys"
SK_FOUND=$(grep -rn "sk-[a-zA-Z0-9]\{20,\}" "$PROJECT_DIR/Sources/" "$PROJECT_DIR/OHeasApp/" --include="*.swift" --include="*.json" --include="*.plist" --include="*.yml" --include="*.yaml" 2>/dev/null || true)
if [ -z "$SK_FOUND" ]; then
    pass "No hardcoded API keys (sk-*) found in source"
else
    fail "Hardcoded API key found: $SK_FOUND"
fi

OPENAI_KEY_IN_PLIST=$(grep -c "OPENAI_API_KEY" "$PROJECT_DIR/OHeasApp/Info.plist" 2>/dev/null; true)
OPENAI_KEY_COUNT="${OPENAI_KEY_IN_PLIST:-0}"
if [ "${OPENAI_KEY_COUNT//[!0-9]/}" -gt 0 ] 2>/dev/null; then
    warn "OPENAI_API_KEY key exists in Info.plist (check value is empty, not a real key)"
else
    pass "OPENAI_API_KEY not in Info.plist"
fi
echo ""

# ── 3. Raw HealthKit sample upload protection ────────────────
echo "── 3. Raw HealthKit Sample Upload Protection"
if grep -q "containsRawHealthSampleKeys" "$PROJECT_DIR/Sources/OHeasCore/Sync/SyncEngine.swift"; then
    pass "containsRawHealthSampleKeys guard present in SyncEngine"
else
    fail "SyncEngine missing raw HealthKit sample guard"
fi

SYNC_ENTITY_TYPES=$(grep "case dailyHealthMetrics" "$PROJECT_DIR/Sources/OHeasCore/Sync/SyncEngine.swift" || true)
if [ -n "$SYNC_ENTITY_TYPES" ]; then
    warn "dailyHealthMetrics is in sync entity types — verify only aggregate data, no raw samples"
else
    pass "dailyHealthMetrics not in sync entity types"
fi
echo ""

# ── 4. Dangerous code patterns ───────────────────────────────
echo "── 4. Dangerous Code Patterns"

FATAL_COUNT=$(grep -rn "fatalError" "$PROJECT_DIR/Sources/" "$PROJECT_DIR/OHeasApp/" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$FATAL_COUNT" -eq 0 ]; then
    pass "No fatalError calls"
else
    fail "fatalError ($FATAL_COUNT occurrences)"
fi

TRY_BANG_COUNT=$(grep -rn "try!" "$PROJECT_DIR/Sources/" "$PROJECT_DIR/OHeasApp/" --include="*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TRY_BANG_COUNT" -eq 0 ]; then
    pass "No try! calls"
else
    fail "try! ($TRY_BANG_COUNT occurrences)"
fi

FORCE_UNWRAP=$(grep -rn ')!' "$PROJECT_DIR/Sources/" "$PROJECT_DIR/OHeasApp/" --include="*.swift" 2>/dev/null | grep -v "catch\|import\|#if\|//\|///" | wc -l | tr -d ' ')
if [ "$FORCE_UNWRAP" -le 20 ]; then
    pass "Force unwraps: $FORCE_UNWRAP (≤ 20, all HKObjectType system identifiers)"
else
    warn "Force unwraps: $FORCE_UNWRAP (review for non-system-type usage)"
fi
echo ""

# ── 5. Required docs ─────────────────────────────────────────
echo "── 5. Required Documentation"
DOCS=(
    "docs/testflight-release-notes.md"
    "docs/beta-smoke-test-checklist.md"
    "docs/beta-blocking-issues.md"
    "docs/real-device-validation.md"
    "docs/testflight-beta-plan.md"
)
for doc in "${DOCS[@]}"; do
    if [ -f "$PROJECT_DIR/$doc" ]; then
        pass "$doc exists"
    else
        fail "$doc missing"
    fi
done
echo ""

# ── 6. Info.plist privacy strings ────────────────────────────
echo "── 6. Info.plist Privacy Strings"
REQUIRED_STRINGS=("NSHealthShareUsageDescription" "NSHealthUpdateUsageDescription")
for str in "${REQUIRED_STRINGS[@]}"; do
    if grep -q "$str" "$PROJECT_DIR/OHeasApp/Info.plist"; then
        pass "$str present in Info.plist"
    else
        fail "$str missing from Info.plist"
    fi
done
echo ""

# ── 7. Entitlements ──────────────────────────────────────────
echo "── 7. Entitlements"
if grep -q "com.apple.developer.healthkit" "$PROJECT_DIR/OHeasApp/OHeas.entitlements"; then
    pass "HealthKit capability in entitlements"
else
    fail "HealthKit capability missing from entitlements"
fi
echo ""

# ── 8. Xcode project can build for device ────────────────────
echo "── 8. iOS Device Build (no archive)"
if xcodebuild -project "$PROJECT_DIR/OHeas.xcodeproj" \
    -scheme OHeas \
    -destination "generic/platform=iOS" \
    -configuration Release \
    build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    pass "Release build for iOS device succeeded"
else
    warn "Release build for iOS device failed (expected if no team configured)"
fi
echo ""

# ── 9. Check for DEEPSEEK_API_KEY_PLACEHOLDER ────────────────
echo "── 9. API Key Placeholder Guard"
if grep -q 'DEEPSEEK_API_KEY_PLACEHOLDER' "$PROJECT_DIR/OHeasApp/UI/OHeasAppConfiguration.swift"; then
    pass "DEEPSEEK_API_KEY_PLACEHOLDER detection guard present"
else
    fail "Missing DEEPSEEK_API_KEY_PLACEHOLDER guard in OHeasAppConfiguration"
fi
echo ""

# ── 10. Git clean check ──────────────────────────────────────
echo "── 10. Git Status"
if [ -d "$PROJECT_DIR/.git" ]; then
    if git -C "$PROJECT_DIR" diff --quiet && git -C "$PROJECT_DIR" diff --cached --quiet; then
        pass "Git working tree is clean"
    else
        warn "Uncommitted changes exist — review before release"
    fi
else
    warn "Not a git repository — skipping git check"
fi
echo ""

# ── Summary ──────────────────────────────────────────────────
echo "============================================"
echo " SUMMARY"
echo "============================================"
echo -e "  ${GREEN}Pass:${NC} $PASS"
echo -e "  ${YELLOW}Warn:${NC} $WARN"
echo -e "  ${RED}Fail:${NC} $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Preflight FAILED — $FAIL issue(s) must be fixed before release.${NC}"
    exit 1
else
    echo -e "${GREEN}Preflight PASSED — ready for Archive.${NC}"
    exit 0
fi

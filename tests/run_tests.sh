#!/bin/bash
# Automated Test Runner for Custom Calendar Widget

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "=== Starting Automated Test Runner ===\n"

# 1. Run QML Unit Tests
echo "Step 1: Running QML Unit Tests (DateFormatter)..."
qmltestrunner -input "$(dirname "$0")/tst_dateformatter.qml"
TEST1_EXIT=$?

echo "Step 2: Running QML Unit Tests (Overlay Alignment)..."
qmltestrunner -input "$(dirname "$0")/tst_overlay_alignment.qml"
TEST2_EXIT=$?

echo "Step 3: Running QML Unit Tests (Text Effect Mask)..."
qmltestrunner -input "$(dirname "$0")/tst_texteffect_mask.qml"
TEST3_EXIT=$?

if [ $TEST1_EXIT -eq 0 ] && [ $TEST2_EXIT -eq 0 ] && [ $TEST3_EXIT -eq 0 ]; then
    echo -e "${GREEN}PASS: All QML Unit Tests succeeded.${NC}\n"
else
    echo -e "${RED}FAIL: QML Unit Tests failed.${NC}\n"
fi

# 2. Run QML Syntax Check (qmlformat validation)
echo "Step 4: Validating QML Syntax (qmlformat)..."
qmlformat -v "$(dirname "$0")/../contents/ui/main.qml" >/dev/null 2>&1
MAIN_SYNTAX=$?
qmlformat -v "$(dirname "$0")/../contents/ui/config/ConfigGeneral.qml" >/dev/null 2>&1
CONFIG_SYNTAX=$?
qmlformat -v "$(dirname "$0")/../contents/ui/config/ConfigRowDelegate.qml" >/dev/null 2>&1
DELEGATE_SYNTAX=$?

if [ $MAIN_SYNTAX -eq 0 ] && [ $CONFIG_SYNTAX -eq 0 ] && [ $DELEGATE_SYNTAX -eq 0 ]; then
    echo -e "${GREEN}PASS: QML syntax is valid (main.qml, ConfigGeneral.qml, ConfigRowDelegate.qml).${NC}\n"
else
    echo -e "${RED}FAIL: QML syntax validation failed.${NC}"
    [ $MAIN_SYNTAX -ne 0 ] && echo -e "  - main.qml contains syntax errors (exit code: $MAIN_SYNTAX)"
    [ $CONFIG_SYNTAX -ne 0 ] && echo -e "  - ConfigGeneral.qml contains syntax errors (exit code: $CONFIG_SYNTAX)"
    [ $DELEGATE_SYNTAX -ne 0 ] && echo -e "  - ConfigRowDelegate.qml contains syntax errors (exit code: $DELEGATE_SYNTAX)"
    echo ""
fi

# 3. Overall Summary
if [ $TEST1_EXIT -eq 0 ] && [ $TEST2_EXIT -eq 0 ] && [ $TEST3_EXIT -eq 0 ] && [ $MAIN_SYNTAX -eq 0 ] && [ $CONFIG_SYNTAX -eq 0 ]; then
    echo -e "${GREEN}======================================"
    echo -e "  ALL TESTS PASSED SUCCESSFULLY!"
    echo -e "======================================${NC}"
    exit 0
else
    echo -e "${RED}======================================"
    echo -e "  TEST SUITE FAILURE!"
    echo -e "======================================${NC}"
    exit 1
fi

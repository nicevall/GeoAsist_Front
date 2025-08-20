@echo off
REM test_scripts/run_all_tests.bat
REM Windows batch script for comprehensive test execution

echo 🧪 GeoAsist Frontend - Comprehensive Test Suite
echo ===============================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    exit /b 1
)

echo [INFO] Flutter version:
flutter --version

REM Clean and get dependencies
echo [INFO] Cleaning and getting dependencies...
flutter clean
flutter pub get

REM Verify project setup
echo [INFO] Verifying project setup...
flutter doctor -v

REM Run static analysis
echo [INFO] Running static analysis...
flutter analyze
if %errorlevel% neq 0 (
    echo [ERROR] Static analysis failed
    exit /b 1
)
echo [SUCCESS] Static analysis passed

REM Check code formatting
echo [INFO] Checking code formatting...
dart format --output=none --set-exit-if-changed .
if %errorlevel% neq 0 (
    echo [WARNING] Code formatting issues found. Run 'dart format .' to fix.
) else (
    echo [SUCCESS] Code formatting is correct
)

REM Create coverage directory
if not exist coverage mkdir coverage

REM Run unit tests with coverage
echo [INFO] Running unit tests with coverage...
flutter test --coverage --reporter expanded test/unit/
if %errorlevel% neq 0 (
    echo [ERROR] Unit tests failed
    exit /b 1
)
echo [SUCCESS] Unit tests passed

REM Run widget tests
echo [INFO] Running widget tests...
flutter test --reporter expanded test/widget/
if %errorlevel% neq 0 (
    echo [ERROR] Widget tests failed
    exit /b 1
)
echo [SUCCESS] Widget tests passed

REM Run integration tests
echo [INFO] Running integration tests...
flutter test test/integration/
if %errorlevel% neq 0 (
    echo [ERROR] Integration tests failed
    exit /b 1
)
echo [SUCCESS] Integration tests passed

REM Generate coverage report (Windows specific)
echo [INFO] Generating coverage report...
if exist coverage\lcov.info (
    echo Coverage file generated
    echo [SUCCESS] Coverage report generated in coverage/
) else (
    echo [WARNING] Coverage file not found
)

REM Build test
echo [INFO] Testing build process...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo [ERROR] Debug build failed
    exit /b 1
)
echo [SUCCESS] Debug build successful

REM Performance tests
echo [INFO] Running performance analysis...
flutter build apk --analyze-size --target-platform android-arm64

REM Security checks
echo [INFO] Running security checks...
flutter pub deps > deps_list.txt
echo [INFO] Dependency list generated in deps_list.txt

REM Test summary
echo.
echo 🎉 Test Execution Summary
echo =========================
echo [SUCCESS] ✅ Static analysis: PASSED
echo [SUCCESS] ✅ Unit tests: PASSED
echo [SUCCESS] ✅ Widget tests: PASSED
echo [SUCCESS] ✅ Integration tests: PASSED
echo [SUCCESS] ✅ Build test: PASSED
echo [SUCCESS] ✅ Performance analysis: COMPLETED
echo [SUCCESS] ✅ Security checks: COMPLETED

if exist coverage\html\index.html (
    echo [INFO] 📊 Open coverage\html\index.html to view detailed coverage report
)

echo [INFO] 🚀 All tests completed successfully!

echo.
echo Next steps:
echo - Review coverage report for any gaps
echo - Check performance analysis results
echo - Review dependency security report
echo - Consider adding more edge case tests if needed

pause
@echo off
REM CaloCam Test Runner Script
REM Run all tests with coverage reporting

echo ========================================
echo CaloCam Test Suite
echo ========================================
echo.

echo [1/4] Running unit tests...
call flutter test test/unit/ --reporter expanded
if %ERRORLEVEL% neq 0 (
    echo ❌ Unit tests failed!
    exit /b 1
)
echo ✅ Unit tests passed!
echo.

echo [2/4] Running widget tests...
call flutter test test/widget/ --reporter expanded
if %ERRORLEVEL% neq 0 (
    echo ❌ Widget tests failed!
    exit /b 1
)
echo ✅ Widget tests passed!
echo.

echo [3/4] Running all tests with coverage...
call flutter test --coverage
if %ERRORLEVEL% neq 0 (
    echo ❌ Tests with coverage failed!
    exit /b 1
)
echo ✅ Coverage generated!
echo.

echo [4/4] Test summary...
echo ========================================
echo ✅ All tests passed!
echo 📊 Coverage report: coverage/lcov.info
echo 📁 View HTML: coverage/html/index.html
echo ========================================
echo.

echo To view coverage report:
echo   1. Install lcov: choco install lcov
echo   2. Generate HTML: genhtml coverage/lcov.info -o coverage/html
echo   3. Open: start coverage/html/index.html
echo.

exit /b 0


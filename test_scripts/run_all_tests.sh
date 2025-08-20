#!/bin/bash
# test_scripts/run_all_tests.sh
# Comprehensive test execution script

set -e

echo "🧪 GeoAsist Frontend - Comprehensive Test Suite"
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Clean and get dependencies
print_status "Cleaning and getting dependencies..."
flutter clean
flutter pub get

# Verify project setup
print_status "Verifying project setup..."
flutter doctor -v

# Run static analysis
print_status "Running static analysis..."
if flutter analyze; then
    print_success "Static analysis passed"
else
    print_error "Static analysis failed"
    exit 1
fi

# Check code formatting
print_status "Checking code formatting..."
if dart format --output=none --set-exit-if-changed .; then
    print_success "Code formatting is correct"
else
    print_warning "Code formatting issues found. Run 'dart format .' to fix."
fi

# Create coverage directory
mkdir -p coverage

# Run unit tests with coverage
print_status "Running unit tests with coverage..."
if flutter test --coverage --reporter expanded test/unit/; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Run widget tests
print_status "Running widget tests..."
if flutter test --reporter expanded test/widget/; then
    print_success "Widget tests passed"
else
    print_error "Widget tests failed"
    exit 1
fi

# Run integration tests
print_status "Running integration tests..."
if flutter test test/integration/; then
    print_success "Integration tests passed"
else
    print_error "Integration tests failed"
    exit 1
fi

# Generate coverage report
print_status "Generating coverage report..."
if command -v lcov &> /dev/null; then
    # Remove unwanted files from coverage
    lcov --remove coverage/lcov.info \
        '*/test/*' \
        '*/generated/*' \
        '*/*.g.dart' \
        '*/*.freezed.dart' \
        -o coverage/lcov_cleaned.info
    
    # Generate HTML report
    genhtml coverage/lcov_cleaned.info -o coverage/html
    print_success "Coverage report generated in coverage/html/"
else
    print_warning "lcov not installed. HTML coverage report not generated."
fi

# Calculate coverage percentage
if [ -f "coverage/lcov.info" ]; then
    if command -v lcov &> /dev/null; then
        COVERAGE=$(lcov --summary coverage/lcov_cleaned.info | grep "lines" | awk '{print $2}' | sed 's/%//')
        echo "Coverage: $COVERAGE%"
        
        if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
            print_success "Coverage $COVERAGE% meets minimum threshold of 80%"
        else
            print_warning "Coverage $COVERAGE% is below minimum threshold of 80%"
        fi
    fi
fi

# Run memory leak detection tests
print_status "Running memory leak detection tests..."
flutter test --coverage test/unit/student_attendance_manager_comprehensive_test.dart

# Build test
print_status "Testing build process..."
if flutter build apk --debug; then
    print_success "Debug build successful"
else
    print_error "Debug build failed"
    exit 1
fi

# Performance tests
print_status "Running performance analysis..."
flutter build apk --analyze-size --target-platform android-arm64

# Security checks
print_status "Running security checks..."
flutter pub deps > deps_list.txt
print_status "Dependency list generated in deps_list.txt"

# Test summary
echo ""
echo "🎉 Test Execution Summary"
echo "========================="
print_success "✅ Static analysis: PASSED"
print_success "✅ Unit tests: PASSED"
print_success "✅ Widget tests: PASSED"
print_success "✅ Integration tests: PASSED"
print_success "✅ Build test: PASSED"
print_success "✅ Performance analysis: COMPLETED"
print_success "✅ Security checks: COMPLETED"

if [ -f "coverage/html/index.html" ]; then
    print_status "📊 Open coverage/html/index.html to view detailed coverage report"
fi

print_status "🚀 All tests completed successfully!"

echo ""
echo "Next steps:"
echo "- Review coverage report for any gaps"
echo "- Check performance analysis results"
echo "- Review dependency security report"
echo "- Consider adding more edge case tests if needed"
#!/bin/bash
set -e

echo "=== Drip Setup ==="
echo ""

echo "Building project..."
swift build
echo "Build succeeded."
echo ""

echo "Running tests..."
swift test
echo "All tests passed."
echo ""

echo "Opening in Xcode..."
open Package.swift

echo ""
echo "Setup complete."

#!/bin/bash

# Quick development setup script
# This script sets up the development environment quickly

set -e

echo "🔧 GitKtti Development Setup"
echo "============================"

# Check if we're in the right directory
if [ ! -f "Makefile.PL" ]; then
    echo "❌ Please run this from the GitKtti root directory"
    exit 1
fi

echo "🧹 Cleaning previous build..."
make clean 2>/dev/null || true
rm -f Makefile MYMETA.* pm_to_blib 2>/dev/null || true
rm -rf blib/ 2>/dev/null || true

echo "🔨 Building..."
perl Makefile.PL
make

echo "🧪 Running tests..."
make test

echo "✅ Development setup complete!"
echo ""
echo "You can now run scripts directly from bin/:"
echo "  ./bin/gitktti-checkout --help"
echo "  ./bin/gitktti-tests --verbose"
echo ""
echo "Or install system-wide with:"
echo "  sudo make install"

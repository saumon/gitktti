#!/bin/bash

# GitKtti Installation Script
# This script helps install GitKtti either from CPAN or locally

set -e

echo "🚀 GitKtti Installation Script"
echo "==============================="

# Check if we have Perl
if ! command -v perl &> /dev/null; then
    echo "❌ Perl is not installed. Please install Perl first."
    exit 1
fi

echo "✅ Perl found: $(perl -v | head -n 2 | tail -n 1)"

# Check if we have make
if ! command -v make &> /dev/null; then
    echo "❌ make is not installed. Please install make first."
    exit 1
fi

echo "✅ make found"

# Check if we're in the GitKtti directory
if [ ! -f "Makefile.PL" ]; then
    echo "❌ Makefile.PL not found. Please run this script from the GitKtti root directory."
    exit 1
fi

echo "✅ GitKtti source directory detected"

# Ask user for installation type
echo ""
echo "Choose installation method:"
echo "1) Install locally (development mode)"
echo "2) Install system-wide (requires sudo)"
echo "3) Install to ~/perl5 (local::lib)"

read -p "Enter your choice [1-3]: " choice

case $choice in
    1)
        echo "🔧 Installing locally (development mode)..."
        perl Makefile.PL
        make
        make test
        echo "✅ Local installation complete!"
        echo "📝 You can run the scripts directly from the bin/ directory"
        echo "   Example: ./bin/gitktti-checkout --help"
        ;;
    2)
        echo "🔧 Installing system-wide..."
        perl Makefile.PL
        make
        make test
        echo "🔐 Installing system-wide (requires sudo)..."
        sudo make install
        echo "✅ System-wide installation complete!"
        echo "📝 You can now run: gitktti-checkout, gitktti-delete, etc."
        ;;
    3)
        echo "🔧 Installing to ~/perl5..."
        # Setup local::lib if not already done
        if [ ! -d "$HOME/perl5" ]; then
            echo "📁 Creating ~/perl5 directory..."
            mkdir -p ~/perl5/lib/perl5
        fi

        # Check if local::lib is configured
        if ! perl -Mlocal::lib 2>/dev/null; then
            echo "📦 Installing local::lib..."
            curl -L https://cpanmin.us | perl - --local-lib ~/perl5 local::lib
            echo 'eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"' >> ~/.bashrc
            eval "$(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)"
        fi

        perl Makefile.PL INSTALL_BASE=~/perl5
        make
        make test
        make install
        echo "✅ Local installation complete!"
        echo "📝 Make sure ~/perl5/bin is in your PATH"
        echo "   Add this to your ~/.bashrc or ~/.zshrc:"
        echo "   export PATH=\"\$HOME/perl5/bin:\$PATH\""
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "🎉 GitKtti installation completed!"
echo ""
echo "Available commands:"
echo "  - gitktti-checkout  : Switch between branches"
echo "  - gitktti-delete    : Delete branches safely"
echo "  - gitktti-fix       : Start a hotfix"
echo "  - gitktti-fixend    : Finish a hotfix"
echo "  - gitktti-move      : Rename branches"
echo "  - gitktti-tag       : Create and push tags"
echo "  - gitktti-tests     : Run diagnostic tests"
echo ""
echo "Run any command with --help for usage information."
echo "Happy git flowing! 🌊"

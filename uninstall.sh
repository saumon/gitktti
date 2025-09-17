#!/bin/bash

# GitKtti Uninstallation Script
# This script helps uninstall GitKtti from various installation methods

set -e

echo "🗑️  GitKtti Uninstallation Script"
echo "================================="

# Ask user about installation method used
echo "How was GitKtti installed?"
echo "1) Locally (development mode)"
echo "2) System-wide (with sudo)"
echo "3) ~/perl5 (local::lib)"
echo "4) CPAN installation"

read -p "Enter your choice [1-4]: " choice

case $choice in
    1)
        echo "📁 Local installation - nothing to uninstall system-wide"
        echo "ℹ️  You can simply delete the GitKtti directory when ready"
        echo "✅ No system cleanup needed!"
        ;;
    2)
        echo "🔍 Searching for installed GitKtti files..."
        
        # Find perl installation paths
        PERL_SITEARCH=$(perl -MConfig -e 'print $Config{sitearchexp}')
        PERL_SITELIB=$(perl -MConfig -e 'print $Config{sitelibexp}')
        PERL_INSTALLBIN=$(perl -MConfig -e 'print $Config{installbin}')
        PERL_INSTALLMAN1DIR=$(perl -MConfig -e 'print $Config{installman1dir}')
        PERL_INSTALLMAN3DIR=$(perl -MConfig -e 'print $Config{installman3dir}')
        
        echo "🔍 Checking these locations:"
        echo "  - $PERL_SITELIB/App/GitKtti.pm"
        echo "  - $PERL_INSTALLBIN/gitktti-*"
        echo "  - $PERL_INSTALLMAN1DIR/gitktti-*.1*"
        echo "  - $PERL_INSTALLMAN3DIR/App::GitKtti.3*"
        
        FILES_TO_DELETE=""
        
        # Check module
        if [ -f "$PERL_SITELIB/App/GitKtti.pm" ]; then
            FILES_TO_DELETE="$FILES_TO_DELETE $PERL_SITELIB/App/GitKtti.pm"
        fi
        
        # Check scripts
        for script in gitktti-checkout gitktti-delete gitktti-fix gitktti-fixend gitktti-move gitktti-tag gitktti-tests; do
            if [ -f "$PERL_INSTALLBIN/$script" ]; then
                FILES_TO_DELETE="$FILES_TO_DELETE $PERL_INSTALLBIN/$script"
            fi
        done
        
        # Check man pages
        for manpage in "$PERL_INSTALLMAN1DIR"/gitktti-*.1* "$PERL_INSTALLMAN3DIR"/App::GitKtti.3*; do
            if [ -f "$manpage" ]; then
                FILES_TO_DELETE="$FILES_TO_DELETE $manpage"
            fi
        done
        
        if [ -n "$FILES_TO_DELETE" ]; then
            echo "📋 Files found for deletion:"
            echo "$FILES_TO_DELETE" | tr ' ' '\n' | sed 's/^/  - /'
            echo ""
            read -p "❓ Delete these files? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo "🗑️  Removing files (requires sudo)..."
                sudo rm -f $FILES_TO_DELETE
                echo "✅ System-wide uninstallation complete!"
            else
                echo "❌ Uninstallation cancelled"
            fi
        else
            echo "ℹ️  No GitKtti files found in system directories"
        fi
        ;;
    3)
        echo "🔍 Checking ~/perl5 installation..."
        
        FILES_FOUND=""
        
        # Check module
        if [ -f "$HOME/perl5/lib/perl5/App/GitKtti.pm" ]; then
            FILES_FOUND="yes"
            echo "  - Found: ~/perl5/lib/perl5/App/GitKtti.pm"
        fi
        
        # Check scripts
        for script in gitktti-checkout gitktti-delete gitktti-fix gitktti-fixend gitktti-move gitktti-tag gitktti-tests; do
            if [ -f "$HOME/perl5/bin/$script" ]; then
                FILES_FOUND="yes"
                echo "  - Found: ~/perl5/bin/$script"
            fi
        done
        
        # Check man pages
        for mandir in "$HOME/perl5/man/man1" "$HOME/perl5/man/man3"; do
            if [ -d "$mandir" ]; then
                find "$mandir" -name "*gitktti*" -o -name "*GitKtti*" 2>/dev/null | while read manpage; do
                    if [ -f "$manpage" ]; then
                        FILES_FOUND="yes"
                        echo "  - Found: $manpage"
                    fi
                done
            fi
        done
        
        if [ -n "$FILES_FOUND" ]; then
            echo ""
            read -p "❓ Delete GitKtti from ~/perl5? [y/N]: " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                echo "🗑️  Removing GitKtti from ~/perl5..."
                rm -f "$HOME/perl5/lib/perl5/App/GitKtti.pm"
                rm -f "$HOME/perl5/bin/gitktti-"*
                find "$HOME/perl5/man" -name "*gitktti*" -o -name "*GitKtti*" -delete 2>/dev/null || true
                echo "✅ ~/perl5 uninstallation complete!"
            else
                echo "❌ Uninstallation cancelled"
            fi
        else
            echo "ℹ️  No GitKtti files found in ~/perl5"
        fi
        ;;
    4)
        echo "📦 CPAN uninstallation..."
        echo "🔍 Trying cpan uninstall..."
        
        if command -v cpan &> /dev/null; then
            echo "💡 Using: cpan -U App::GitKtti"
            cpan -U App::GitKtti
            echo "✅ CPAN uninstallation complete!"
        elif command -v cpanm &> /dev/null; then
            echo "💡 cpanm doesn't support uninstall directly"
            echo "🔄 Falling back to manual method..."
            echo "Choose option 2 (System-wide) in the next prompt:"
            exec "$0"
        else
            echo "❌ No CPAN client found"
            echo "🔄 Falling back to manual method..."
            echo "Choose option 2 (System-wide) in the next prompt:"
            exec "$0"
        fi
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "🧹 Optional: Clean up configuration"
echo "If you had aliases in your shell config, you may want to remove:"
echo "  alias kfix='gitktti-fix'"
echo "  alias kfeat='gitktti-fix --mode feature'"
echo "  alias kreal='gitktti-fix --mode release'"
echo "  alias kfixend='gitktti-fixend'"
echo "  alias kmove='gitktti-move'"
echo "  alias kdel='gitktti-delete'"
echo "  alias kco='gitktti-checkout'"
echo "  alias ktest='gitktti-tests'"
echo ""
echo "🎉 GitKtti uninstallation process complete!"

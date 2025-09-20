# GitKtti AI Coding Assistant Instructions

## Project Overview

GitKtti is a Perl-based collection of command-line tools that implement **git-flow methodology** with safety features and colorized output. It's distributed as a CPAN module (`App::GitKtti`) with 7 executable scripts that wrap git operations to prevent common mistakes in branch management.

### Core Architecture

- **Main Module**: `lib/App/GitKtti.pm` - Contains shared utilities, colorized output functions, and git wrapper functions
- **Executables**: `bin/gitktti-*` scripts - Each implements a specific git-flow operation
- **Distribution**: Standard Perl module structure with `Makefile.PL`, tests in `t/`, and CPAN metadata

## Essential Development Patterns

### Branch Management Constants

All scripts use consistent regex patterns and mode constants:

```perl
use constant MODE_HOTFIX  => "hotfix";
use constant MODE_FEATURE => "feature";
use constant MODE_RELEASE => "release";

use constant REGEX_HOTFIX  => '^(hotfix)/(.+)$';
use constant REGEX_DEVELOP => '^(dev|develop)$';
use constant REGEX_MASTER  => '^(master|main)$';
use constant REGEX_RELEASE => '^(release)/(.+)$';
use constant REGEX_FEATURE => '^(feature)/(.+)$';
```

### Colorized Output System

The module uses ANSI color constants extensively. All user-facing output should use the predefined color constants:

```perl
use App::GitKtti;v
App::GitKtti::printSuccess("Operation completed");
App::GitKtti::printError("Something went wrong");
App::GitKtti::printWarning("Be careful");
```

### Git Command Execution Pattern

All git operations use the `launch()` function which provides:
- Colorized command display
- Exit code handling
- Output capture
- Error state management

```perl
my $ret = 99;
my @output = App::GitKtti::launch('git status --porcelain', \$ret);
if ($ret != 0) {
    # Handle error
}
```

### Script Structure Template

Each executable follows this structure:
1. Shebang and strict/warnings
2. Module imports with `FindBin` for relative lib path
3. Constants definition
4. `App::GitKtti::showVersion()` call
5. Variable initialization
6. `GetOptions` for argument parsing
7. Help display logic
8. Main operation logic

## Development Workflows

### Build and Test

```bash
# Quick development setup
./dev-setup.sh

# Manual steps
perl Makefile.PL
make
make test
make install
```

### Adding New Commands

1. Create new script in `bin/gitktti-newcommand`
2. Add to `EXE_FILES` array in `Makefile.PL`
3. Follow the established script structure template
4. Add tests in `t/` directory
5. Update documentation

### Version Management

- Version is defined once in `lib/App/GitKtti.pm` as `our $VERSION = 'X.Y.Z'`
- `Makefile.PL` uses `VERSION_FROM` to extract version automatically
- All scripts display version via `App::GitKtti::showVersion()`

## Testing Conventions

- Basic module loading tests in `t/01-basic.t`
- Function-specific tests in `t/02-functions.t`
- Test git operations in isolated temporary directories
- Use `Test::More` framework

## CPAN Distribution

The project uses standard Perl distribution practices:
- `make dist` creates `.tar.gz` for CPAN upload
- `META.yml` and `MYMETA.*` are auto-generated
- Repository metadata points to GitHub
- Homepage links to GitHub Pages documentation

## Key Integration Points

- **Git Integration**: All operations are git command wrappers with safety checks
- **Terminal UI**: Rich colorized output with progress indicators and user prompts
- **Cross-Platform**: Uses standard Perl modules for compatibility
- **CPAN Ecosystem**: Follows Perl packaging conventions for distribution

## Common Debugging Approaches

- Check `$ret` values from `launch()` calls for git command failures
- Use `App::GitKtti::git_isRepoClean()` before destructive operations
- Validate branch names against regex constants before operations
- Test interactively with `isResponseYes()` for confirmation prompts

When modifying this codebase, maintain the consistent error handling, colorized output patterns, and git-flow safety features that define the project's core value proposition.

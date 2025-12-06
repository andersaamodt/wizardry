# Security Policy

## Supported Versions

Wizardry follows a rolling release model. The `main` branch is always the supported version.

| Branch | Supported          |
| ------ | ------------------ |
| main   | :white_check_mark: |
| older commits | :x:     |

We recommend always using the latest version from the `main` branch.

## Security Philosophy

Wizardry is a collection of POSIX shell scripts designed to enhance your terminal experience. Security considerations include:

### What Wizardry Does

- Runs scripts locally on your system with your user permissions
- May modify files in your home directory (e.g., `.bashrc`, `.zshrc`)
- May install software using system package managers
- Does NOT send data to external servers
- Does NOT collect telemetry or analytics
- Does NOT execute remote code without explicit user action

### Security By Design

1. **No remote execution**: Wizardry scripts run locally and under your control
2. **Transparent commands**: Menu items show the exact command they will run
3. **User confirmation**: Installation scripts ask before making system changes
4. **Minimal permissions**: Scripts run with your user permissions (no unnecessary sudo)
5. **Code visibility**: All scripts are readable and auditable
6. **POSIX compliance**: Standardized shell language reduces unexpected behavior

### What You Should Review

Before installing or running any spell:

1. **Read the spell**: All spells are text files you can inspect
2. **Check `--help`**: Every spell documents what it does
3. **Run in a test environment**: Try new spells in a VM or container first
4. **Review installation scripts**: Especially those that require sudo

## Reporting a Vulnerability

If you discover a security vulnerability in wizardry, please report it responsibly:

### Where to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report security issues via GitHub's Security Advisory feature:

1. Go to the [Security Advisories page](https://github.com/andersaamodt/wizardry/security/advisories)
2. Click "Report a vulnerability"
3. Fill in the details

Alternatively, you can email the maintainer directly. Check the repository for contact information.

### What to Include

A good security report includes:

- **Description**: What the vulnerability is and what it affects
- **Impact**: What an attacker could do
- **Reproduction**: Step-by-step instructions to reproduce
- **Versions**: Which versions are affected
- **Fix**: If you have suggestions for a fix
- **Credit**: How you'd like to be credited (if at all)

### What to Expect

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Progress updates**: Every 1-2 weeks
- **Fix timeline**: Depends on severity and complexity
- **Disclosure**: Coordinated with you before public announcement

## Security Best Practices

When using wizardry:

### For Users

1. **Review before running**: Read spell code before executing
2. **Understand permissions**: Know what each spell modifies
3. **Keep updated**: Pull latest changes regularly
4. **Report issues**: If something seems wrong, report it
5. **Don't run as root**: Install and run wizardry as your regular user

### For Contributors

1. **No secrets in code**: Never commit passwords, API keys, or tokens
2. **Validate inputs**: Check user input before using it
3. **Use quotes**: Always quote variables to prevent injection
4. **Avoid eval**: Never use `eval` with user input
5. **Check file operations**: Verify paths before modifying files
6. **Test across platforms**: Ensure spells work securely everywhere
7. **Document security implications**: Note if a spell needs sudo or modifies system files

## Common Security Patterns

### Safe File Operations

```sh
# GOOD: Check before modifying
if [ -f "$file" ]; then
  # ... safe operations ...
fi

# GOOD: Use temporary files safely
tmpfile=$(mktemp) || exit 1
# ... use tmpfile ...
rm -f "$tmpfile"
```

### Safe Input Handling

```sh
# GOOD: Quote all variables
path="$HOME/wizardry"
[ -d "$path" ] && cd "$path"

# GOOD: Validate input
case "$input" in
  *[!a-zA-Z0-9_-]*) 
    printf '%s\n' "Invalid input" >&2
    exit 1
    ;;
esac
```

### Avoiding Command Injection

```sh
# NEVER do this:
eval "$user_input"

# GOOD: Use variables directly
"$command" "$arg1" "$arg2"
```

## Threat Model

Wizardry assumes:

- **Trusted source**: You cloned from the official repository
- **Local execution**: Scripts run on your local machine
- **User permissions**: Scripts run as your user, not root
- **No network**: Scripts don't send data externally (except package managers)

Wizardry does NOT protect against:

- **Malicious forks**: Always clone from the official repository
- **Compromised system**: If your system is compromised, scripts may be too
- **Social engineering**: Always verify what a spell does before running it
- **Physical access**: Scripts won't protect you from physical attack vectors

## Third-Party Dependencies

Wizardry may use system package managers to install third-party software. Security of those packages depends on:

- The package maintainers
- Your distribution's security practices
- Package signing and verification

Always review what software wizardry installs.

## Updates and Patches

Security patches are released as soon as possible after discovery. To stay updated:

```sh
cd ~/.wizardry
git pull origin main
```

We recommend checking for updates weekly if you use wizardry regularly.

## Acknowledgments

We appreciate responsible disclosure and will credit security researchers who report vulnerabilities (with their permission).

---

*Guard growth and ease pain. Use the Art wisely.* 🧙‍♂️✨

For general security questions or concerns, please open a public GitHub issue with the `security` label (only for general questions, not for reporting vulnerabilities).

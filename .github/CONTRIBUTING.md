# Contributing to Wizardry

Welcome, fellow spellcaster! We're delighted that you wish to contribute to the wizardry project. This guide will help you understand how to join our community of practice and add your own magic to the grimoire.

## The Wizard's Oath

By contributing to wizardry, you agree to abide by the [Wizard's Oath](/OATH). The Oath represents our commitment to using our skills for the service of Life, guarding growth and easing pain. Please take a moment to read and understand it.

## Ways to Contribute

### Scribing New Spells

Have an idea for a new spell? Wonderful! Here's how to contribute:

1. **Check existing spells** - Browse `spells/` to ensure your spell doesn't already exist
2. **Follow the spell template** - See `.AGENTS.md` for the complete spell style guide
3. **Write tests** - Every spell needs a test in `.tests/` that mirrors its path
4. **Run the vetting** - Use `./spells/spellcraft/vet-spell` to check style compliance
5. **Submit your spell** - Open a pull request with your new spell

### Improving Existing Spells

Found a bug or have an enhancement? You can:

- Fix bugs in existing spells
- Improve cross-platform compatibility
- Add better error handling
- Enhance documentation
- Optimize performance

### Writing Tests

Tests are specifications! Every spell should have comprehensive tests that demonstrate its behavior. See `.tests/` for examples.

### Documentation

Help make wizardry more accessible:

- Improve README sections
- Add examples to spell help text
- Create tutorials
- Fix typos and clarify explanations

## Development Process

### Setting Up Your Workspace

1. **Fork and clone** the repository:
   ```sh
   git clone https://github.com/YOUR_USERNAME/wizardry ~/.wizardry
   cd ~/.wizardry
   ```

2. **Install wizardry** to test your changes:
   ```sh
   ./install
   ```

3. **Create a branch** for your work:
   ```sh
   git checkout -b spell/your-spell-name
   ```

### Making Changes

1. **Follow POSIX sh** - All spells must be POSIX-compliant
2. **Keep it simple** - Spells should do one thing well
3. **Add tests first** - Write tests before implementing features
4. **Document thoroughly** - Use clear comments for novice shell developers
5. **Maintain the theme** - Keep the MUD/fantasy flavor

### Code Style

Wizardry follows strict style guidelines:

- **Shebang**: `#!/bin/sh` (POSIX only, no bash)
- **Strict mode**: `set -eu` in all spells
- **Quotes**: Always quote variables
- **Error messages**: Descriptive, not imperative (see `.AGENTS.md`)
- **Portability**: Test on Linux and macOS

Run the style checker:
```sh
./spells/spellcraft/vet-spell
```

Check POSIX compliance:
```sh
./spells/system/verify-posix
```

### Testing

Run the full test suite:
```sh
./spells/system/test-magic --verbose
```

Run specific tests:
```sh
.tests/category/test-spell-name.sh
```

### Submitting Changes

1. **Commit your work** with clear messages:
   ```sh
   git add .
   git commit -m "Add spell-name spell for doing X"
   ```

2. **Push to your fork**:
   ```sh
   git push origin spell/your-spell-name
   ```

3. **Open a pull request** on GitHub with:
   - Clear description of what your spell does
   - Any platform-specific considerations
   - Examples of usage

## Pull Request Guidelines

A good pull request:

- Focuses on a single spell or improvement
- Includes tests for new functionality
- Passes all CI checks (tests, style, POSIX compliance)
- Has a clear, descriptive title
- Explains the "why" in the description
- Follows the project's minimal-change philosophy

## Spell Requirements

Every spell must have:

1. **Shebang**: `#!/bin/sh`
2. **Opening comment**: 1-2 lines describing what it does
3. **Help text**: `show_usage()` function with `--help` support
4. **Strict mode**: `set -eu`
5. **Tests**: Corresponding test file in `.tests/`
6. **Documentation**: Clear comments for novice developers

See the [spell style guide](/.AGENTS.md) for complete requirements.

## Imp Requirements

Imps (micro-helpers in `spells/.imps/`) have relaxed requirements:

- Opening comment serves as spec (no `--help` needed)
- Must still be POSIX sh with `set -eu`
- Should do exactly one thing
- Located in demon family folders by function

## Platform Support

Wizardry supports:

- **Primary**: Debian, Ubuntu, NixOS
- **Secondary**: macOS
- **Testing**: Arch Linux

Ensure your spell works on at least Debian/Ubuntu and macOS.

## Community Guidelines

### Be Respectful

We're a teaching community. Everyone is learning, and all questions are welcome.

### Write for Novices

Code is didactic. Write clear, well-commented spells that teach POSIX shell best practices.

### Embrace the Theme

Wizardry uses MUD/fantasy terminology. Embrace it! It makes the terminal more playful without hiding functionality.

### Self-Healing Philosophy

Spells should fix problems automatically or offer to fix them. Never tell users to fix things themselves - that's what wizardry is for!

## Getting Help

- **Questions**: Open an issue with the `question` label
- **Bugs**: Open an issue with detailed reproduction steps
- **Feature ideas**: Open an issue tagged `enhancement`
- **Documentation**: PRs for doc improvements are always welcome

## Recognition

Contributors are recognized in commits and pull request credits. Your spells will carry your authorship and help countless wizards in their terminal journeys.

## License

By contributing to wizardry, you agree that your contributions will be licensed under the same [Open Wizardry License 1.1](/LICENSE) as the project.

---

*May your spells cast true!* 🧙‍♂️✨

Thank you for contributing to wizardry. Every spell you add, every bug you fix, and every test you write makes the terminal a more magical place for everyone.

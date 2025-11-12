# Contributing to Laptop Diagnostic Tool

First off, thank you for considering contributing to the Laptop Diagnostic Tool! It's people like you that make this tool better for everyone.

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include as many details as possible:

#### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run script with '...'
2. Click on '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**System Information:**
 - Windows Version: [e.g., Windows 11 22H2]
 - PowerShell Version: [e.g., 5.1]
 - Laptop Make/Model: [e.g., Dell XPS 15]

**Additional context**
Add any other context about the problem here.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description** of the feature
- **Use case**: Why would this be useful?
- **Possible implementation**: If you have ideas on how to implement it
- **Alternatives**: Any alternative solutions you've considered

### Pull Requests

1. **Fork the repository** and create your branch from `main`
   ```bash
   git checkout -b feature/amazing-feature
   ```

2. **Make your changes**
   - Follow the PowerShell style guide (see below)
   - Update documentation if needed
   - Test your changes thoroughly

3. **Commit your changes**
   ```bash
   git commit -m "Add some amazing feature"
   ```

4. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

5. **Open a Pull Request**
   - Use a clear, descriptive title
   - Describe what changes you've made and why
   - Reference any related issues

## 💻 Development Guidelines

### PowerShell Style Guide

- Use **PascalCase** for function names
- Use **camelCase** for variables
- Add comments for complex logic
- Use meaningful variable names
- Follow the existing code structure

Example:
```powershell
function Get-SystemInformation {
    param (
        [string]$computerName
    )

    # Get computer system information
    $systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem

    return $systemInfo
}
```

### Testing

Before submitting a PR, test on:
- Windows 10 (if possible)
- Windows 11 (minimum)
- Different laptop models (if available)
- Various hardware configurations

### Documentation

- Update README.md if you add new features
- Add inline comments for complex code
- Update version history in README.md

## 🏗️ Project Structure

```
LaptopDiagnostic_v13/
├── FinalDiagnostic_v15.ps1          # Main script - core diagnostic logic
├── hardware_database.json            # Hardware benchmarks - add new hardware here
├── upgrade_recommendations.json      # Upgrade suggestions - pricing and recommendations
├── RUN_DIAGNOSTIC_v15.bat            # Launcher script
└── reports/                          # Generated reports
```

### Adding New Hardware to Database

To add new hardware benchmarks, edit `hardware_database.json`:

```json
{
  "cpus": {
    "Intel Core i9-14900K": {
      "tier": "flagship",
      "score": 95,
      "year": 2024
    }
  }
}
```

## 📝 Commit Message Guidelines

Use clear, descriptive commit messages:

- **feat**: New feature (e.g., `feat: add GPU benchmark test`)
- **fix**: Bug fix (e.g., `fix: correct battery health calculation`)
- **docs**: Documentation changes (e.g., `docs: update installation guide`)
- **style**: Code style changes (e.g., `style: format PowerShell code`)
- **refactor**: Code refactoring (e.g., `refactor: simplify temperature detection`)
- **test**: Test additions or changes
- **chore**: Maintenance tasks (e.g., `chore: update dependencies`)

Example:
```
feat: add M.2 NVMe detection

- Detect M.2 slots
- Identify NVMe vs SATA
- Add to hardware report
```

## 🐛 Known Issues & Limitations

Current known limitations:
- Temperature detection doesn't work on all laptop models
- Some USB-C PD detection may be inaccurate
- WiFi signal strength requires active connection

Feel free to tackle these in your PRs!

## 📞 Questions?

If you have questions about contributing:

- **Email**: wasimxe@gmail.com
- **WhatsApp**: +92 345 540 7008
- **Website**: https://www.tanxe.com

Or open a GitHub issue with the "question" label.

## 🙏 Recognition

Contributors will be:
- Listed in the README
- Mentioned in release notes
- Credited in commit history

Thank you for making the Laptop Diagnostic Tool better!

---

**Happy Contributing! 🎉**

*Tanxe Studio*

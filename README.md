# Laptop Diagnostic Tool v15.0 🔍💻

[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.0+-blue?logo=powershell)](https://docs.microsoft.com/powershell/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Developed by](https://img.shields.io/badge/Developed%20by-Tanxe%20Studio-orange)](https://www.tanxe.com)

> **A comprehensive PowerShell-based laptop diagnostic tool featuring dual rating system, 20+ hardware tests, and interactive HTML reports**

Developed by **[Tanxe Studio](https://www.tanxe.com)** - Professional Windows diagnostic solution for laptop health analysis and performance benchmarking against 2025 hardware standards.

---

## 🎬 Live Demo

**Want to see it in action?** Check out our sample diagnostic report:
- [View Sample Report](file:///D:/workspace/windows/LaptopDiagnostic_v13/reports/Diagnostic_Report_20251025_014010.html) (Download repo and open locally)
- The report includes interactive tests for keyboard, touchpad, display, and audio

---

## ✨ Key Features

### 🎯 Dual Rating System
- **Health Score (0-100)**: Current condition and functionality
- **Performance Score (0-100)**: Comparison against 2025 hardware standards

### 🔬 Comprehensive Testing Suite (20+ Tests)
- CPU performance benchmarking with stress testing
- Memory (RAM) analysis and speed testing
- Storage read/write performance (10MB test)
- Battery health with capacity degradation analysis
- AC adapter health and voltage stability testing
- Temperature monitoring with 10-second stress test
- Display properties (resolution, refresh rate, screen size)
- Network connectivity and WiFi signal strength
- Ports detection (USB-A, USB-C, HDMI, Ethernet)
- Keyboard backlight and layout verification
- Webcam detection (even when disabled)
- Durability certifications (MIL-STD check)

### 🎮 Interactive HTML Report
- **Keyboard Test**: Visual key press testing
- **Touchpad/Mouse Test**: Drawing canvas for precision testing
- **Display Test**: Dead pixel detection with fullscreen colors
- **Audio Test**: Stereo speaker and frequency sweep testing

### 📊 Smart Recommendations
- Use case suitability (Gaming, Office Work, Video Editing, etc.)
- Upgrade recommendations with cost/benefit analysis
- Priority-based suggestion system
- 2025 hardware tier classification

---

## 🚀 Quick Start

### Method 1: One-Click Launch (Easiest)
Simply **double-click** `RUN_DIAGNOSTIC_v15.bat`

### Method 2: PowerShell Direct
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "FinalDiagnostic_v15.ps1"
```

### Method 3: Right-Click Method
1. Right-click `FinalDiagnostic_v15.ps1`
2. Select **"Run with PowerShell"**

The diagnostic takes **2-3 minutes** and generates a beautiful HTML report in the `reports/` folder.

---

## 📊 Understanding Your Scores

### Health Score
| Score | Rating | Description |
|-------|--------|-------------|
| 85-100 | Excellent | Like new condition, all components working optimally |
| 70-84 | Good | Well maintained, minor wear acceptable |
| 50-69 | Fair | Shows some wear, may need attention soon |
| <50 | Needs Attention | Components may need replacement |

### Performance Score
| Score | Tier | Capability | Example CPUs |
|-------|------|------------|--------------|
| 85-100 | Flagship | 4K editing, AI/ML, AAA gaming | i9-14900K, Ryzen 9 7950X |
| 70-84 | High Performance | 1440p gaming, 3D modeling | i7-13700K, Ryzen 7 7700X |
| 55-69 | Mainstream | Everyday tasks, light gaming | i5-13400, Ryzen 5 7600 |
| 40-54 | Mid-Range | Office work, web browsing | i5-12400, Ryzen 5 5600 |
| 25-39 | Entry Level | Basic tasks, outdated by 2025 | i3-10100, Ryzen 3 3300X |
| 0-24 | Legacy | Significantly outdated | i5-4690, FX-8350 |

---

## 🆕 What's New in v15.0

### Critical Fixes
- ✅ Fixed tab switching in HTML reports
- ✅ Enhanced WiFi detection (Intel Centrino, Advanced-N support)
- ✅ Accurate USB port counting (physical ports only)
- ✅ Fixed all JavaScript errors in interactive tests

### New Features
- 🌡️ CPU Temperature stress test (10-second load)
- 📐 Screen size detection in inches
- 👆 Touchscreen capability detection
- 🔌 USB-C and USB Power Delivery support detection
- ⌨️ Keyboard backlight detection
- 📷 Enhanced webcam detection
- 🛡️ MIL-STD certification checking
- ⚡ USB power when off detection

---

## 📂 Project Structure

```
LaptopDiagnostic_v13/
├── FinalDiagnostic_v15.ps1          # Main diagnostic script (PowerShell)
├── RUN_DIAGNOSTIC_v15.bat            # One-click launcher
├── hardware_database.json            # 2025 hardware benchmarks database
├── upgrade_recommendations.json      # Upgrade cost/benefit data
├── README.md                         # This documentation
├── LICENSE                           # MIT License
└── reports/                          # Generated diagnostic reports
    └── Diagnostic_Report_[timestamp].html
```

---

## 💡 Use Cases

### Perfect For:
- 🏪 **Second-hand laptop buyers** - Verify condition before purchase
- 🔧 **IT professionals** - Quick hardware assessment tool
- 💼 **Businesses** - Fleet health monitoring
- 🎓 **Students** - Check if laptop meets course requirements
- 🏠 **Home users** - Understand what upgrades are worth it
- 💻 **Sellers** - Generate professional condition reports

---

## 🛠️ System Requirements

- **OS**: Windows 10 or Windows 11 (any edition)
- **PowerShell**: Version 5.0 or higher (pre-installed on Win10/11)
- **Privileges**: Standard user (Administrator recommended for full details)
- **Disk Space**: <5MB for script, minimal space for reports

---

## 📸 Screenshot Tour

The generated HTML report includes:
- **Dual Score Dashboard**: Visual health and performance ratings
- **Component Breakdown**: Detailed analysis with color-coded status
- **Interactive Tests**: Real-time keyboard, touchpad, display, and audio testing
- **Upgrade Advisor**: Cost-effective improvement suggestions
- **Use Case Matrix**: What your laptop can and can't handle
- **Responsive Design**: Works on any screen size, print-friendly

---

## 🐛 Troubleshooting

### Script Won't Run
If you see "execution policy" error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```
Then run the script again.

### Temperature Not Detected
Some laptops don't expose temperature sensors to Windows. This is hardware-specific and normal.

### WiFi Shows "Not Detected"
Ensure WiFi is enabled in Windows settings. The tool can detect disabled adapters.

### Report Won't Open
Make sure you have a modern web browser (Chrome, Edge, Firefox). The report uses HTML5 features.

---

## 🤝 Contributing

We welcome contributions! Whether it's:
- 🐛 Bug reports
- 💡 Feature suggestions
- 📝 Documentation improvements
- 🔧 Code contributions

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📞 Contact & Support

### Developer: Tanxe Studio

- 🌐 **Website**: [https://www.tanxe.com](https://www.tanxe.com)
- 📧 **Email**: [wasimxe@gmail.com](mailto:wasimxe@gmail.com)
- 💬 **WhatsApp**: [+92 345 540 7008](https://wa.me/923455407008)

**Need Help?** Reach out via any channel above. When reporting issues, please include:
1. Windows version (Win+R → `winver`)
2. PowerShell version (`$PSVersionTable.PSVersion`)
3. Error message or screenshot
4. Generated report (if available)

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

You are free to:
- ✅ Use commercially
- ✅ Modify and distribute
- ✅ Use privately
- ✅ Sublicense

---

## ⚠️ Disclaimer

- This tool provides estimates based on available system data
- Actual performance may vary based on specific configurations and workloads
- Upgrade costs are estimates (2025 pricing) and may vary by region
- Always backup important data before making hardware changes
- For critical systems, consult a professional technician

---

## 🌟 Show Your Support

If this tool helped you:
- ⭐ Star this repository
- 🐦 Share on social media
- 💬 Tell your friends and colleagues
- 🤝 Contribute improvements

---

## 📈 Roadmap

Future enhancements planned:
- [ ] Linux support (Bash version)
- [ ] macOS support
- [ ] Network speed testing
- [ ] GPU benchmark testing
- [ ] Historical tracking (compare reports over time)
- [ ] Cloud report storage option
- [ ] PDF export functionality
- [ ] Multi-language support

---

## 🏆 Credits

**Developed with ❤️ by [Tanxe Studio](https://www.tanxe.com)**

Special thanks to the PowerShell community and hardware database contributors.

---

**Last Updated**: November 2025
**Version**: 15.0
**Status**: Production Ready

---

<div align="center">

### Made with 💻 by Tanxe Studio

[Website](https://www.tanxe.com) • [Email](mailto:wasimxe@gmail.com) • [WhatsApp](https://wa.me/923455407008)

**⭐ Don't forget to star this repo if you found it useful! ⭐**

</div>

# Laptop Diagnostic Tool v15.0

**Developed by Tanxe Studio**

A comprehensive PowerShell-based laptop diagnostic tool that provides **dual rating system** with both health scoring and performance comparison against 2025 hardware standards.

---

## 🚀 Quick Start

### Method 1: Double-click the Launcher (Easiest)
Simply double-click `RUN_DIAGNOSTIC_v15.bat` to start the diagnostic.

### Method 2: Run PowerShell Script Directly
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "FinalDiagnostic_v15.ps1"
```

### Method 3: Right-click PowerShell
1. Right-click `FinalDiagnostic_v15.ps1`
2. Select "Run with PowerShell"

---

## 📊 Dual Rating System

### Health Score (0-100)
Measures your laptop's **current condition and functionality**:
- **85-100**: Excellent - Like new condition
- **70-84**: Good - Well maintained
- **50-69**: Fair - Shows some wear
- **Below 50**: Needs Attention - Components may need replacement

### Performance Score (0-100)
Compares your laptop against **2025 hardware standards**:
- **85-100**: Flagship - Matches 2025 high-end laptops
- **70-84**: High Performance - Modern gaming/workstation
- **55-69**: Mainstream - Good for everyday 2025 tasks
- **40-54**: Mid-Range - Entry level by 2025 standards
- **25-39**: Entry Level - Outdated by 2025
- **Below 25**: Legacy - Significantly outdated

---

## ✨ NEW in v15.0

### 🔧 Critical Fixes
- ✅ **Fixed tab switching** - Interactive HTML report tabs now work properly
- ✅ **Enhanced WiFi detection** - Now detects Intel Centrino, Advanced-N, and other chipsets
- ✅ **Accurate USB port counting** - Detects physical ports, not internal hubs
- ✅ **Fixed JavaScript errors** - All interactive tests now function correctly

### 🆕 New Features
- 🔥 **CPU Temperature Stress Test** - 10-second load test with before/after measurements
- 📐 **Screen Size Detection** - Displays actual screen size in inches (e.g., "15.3 inches")
- 👆 **Touchscreen Detection** - Identifies if laptop has touch capability
- 🔌 **Enhanced Port Detection**:
  - USB-C ports
  - USB Type-A ports
  - HDMI ports
  - Ethernet ports
  - USB-C Power Delivery (PD) support
- ⌨️ **Keyboard Features**:
  - Backlight detection
  - Layout verification (Ctrl position)
- 📷 **Webcam Detection** - Detects webcam even when disabled in Device Manager
- 🛡️ **Durability Certification** - Checks for MIL-STD-810G/H certification
- ⚡ **USB Power When Off** - Detects if USB ports can charge devices when laptop is off

---

## 📋 Complete Test Suite (20 Tests)

### System Tests
1. **System Information** - Manufacturer, model, OS, BIOS
2. **CPU Performance & Benchmark** - Real-time benchmark (ops/sec)
3. **Memory (RAM)** - Type, speed, capacity analysis
4. **Storage Performance** - Read/write speed testing (10MB)
5. **Battery Health** - Capacity degradation, cycle count, chemistry
6. **AC Adapter** - Wattage, voltage, current detection
7. **Temperature & Cooling** - Stress test with delta measurement
8. **Display** - Resolution, refresh rate, screen size, touchscreen
9. **Graphics Card** - Dedicated vs integrated, VRAM, driver
10. **Network & WiFi** - Adapter detection, signal strength
11. **Audio Devices** - Speaker and microphone detection
12. **Input Devices** - Keyboard and pointing devices
13. **Webcam** - Detection even when disabled
14. **Ports & Connectors** - USB-A, USB-C, HDMI, Ethernet
15. **Keyboard Features** - Backlight, layout verification
16. **Durability & Certifications** - MIL-STD check
17. **USB Power Delivery** - Charging when powered off
18. **Performance Score Calculation** - Tier-based comparison
19. **Use Case Recommendations** - What tasks it can handle
20. **Upgrade Recommendations** - Cost/benefit analysis

### Interactive Tests (in HTML report)
- **Keyboard Test** - Press keys to verify all work
- **Touchpad/Mouse Test** - Drawing canvas to test clicks and movement
- **Display Test** - Dead pixel detection with fullscreen colors
- **Audio Test** - Left/right speaker test, frequency sweep

---

## 📈 Component Tier System

Hardware is compared against 2025 standards using these tiers:

| Tier | Score Range | Description | Example CPU |
|------|-------------|-------------|-------------|
| **Flagship** | 85-100 | Latest high-end | i9-14900K, Ryzen 9 7950X |
| **High Performance** | 70-84 | Modern premium | i7-13700K, Ryzen 7 7700X |
| **Mainstream** | 55-69 | Current mid-range | i5-13400, Ryzen 5 7600 |
| **Mid-Range** | 40-54 | Entry level (2023-2024) | i5-12400, Ryzen 5 5600 |
| **Entry Level** | 25-39 | Budget (2020-2022) | i3-10100, Ryzen 3 3300X |
| **Legacy** | 0-24 | Outdated (pre-2020) | i5-4690, FX-8350 |

---

## 🎯 Use Case Recommendations

The tool automatically suggests what your laptop is suitable for based on Performance Score:

### Flagship (85-100)
✅ **Suitable:**
- Professional 3D rendering
- 4K/8K video editing
- AAA gaming at ultra settings
- AI/ML development
- Large-scale software compilation

### High Performance (70-84)
✅ **Suitable:**
- 1080p/1440p video editing
- Modern gaming (high settings)
- 3D modeling
- Software development

⚠️ **Limited:**
- 8K video editing
- Real-time ray tracing
- Large AI model training

### Mid-Range (40-54)
✅ **Suitable:**
- Web browsing and email
- Office applications
- 1080p video streaming
- Light photo editing
- Casual gaming

⚠️ **Limited:**
- Modern AAA gaming
- 4K video editing
- Heavy multitasking

❌ **Not Recommended:**
- Professional video editing
- 3D rendering
- VR gaming

---

## 💡 Upgrade Recommendations

The tool suggests upgrades with:
- **Current vs Recommended** specs
- **Estimated Cost** (2025 prices)
- **Performance Gain** percentage
- **Priority Level** (High/Medium/Low)
- **Detailed Description** of impact

Example recommendations:
- **RAM Upgrade**: 8GB → 16GB ($30-50, +25% performance, HIGH priority)
- **Storage Upgrade**: HDD → SSD ($35-60, +200% performance, VERY HIGH priority)
- **Battery Replacement**: <50% health ($40-120, +100% runtime, HIGH priority)

---

## 📂 File Structure

```
LaptopDiagnostic_v13/
├── FinalDiagnostic_v15.ps1          # Main diagnostic script
├── RUN_DIAGNOSTIC_v15.bat            # Easy launcher
├── hardware_database.json            # 2025 hardware benchmarks
├── upgrade_recommendations.json      # Upgrade cost/impact data
├── README_v15.md                     # This file
└── reports/                          # Generated HTML reports
    └── Diagnostic_Report_YYYYMMDD_HHMMSS.html
```

---

## 🔧 Technical Details

### Requirements
- **Windows 10/11** (any edition)
- **PowerShell 5.0+** (included in Windows 10/11)
- **Administrator privileges** recommended (not required)

### Performance Benchmarks
- **CPU Benchmark**: 3-second computational test
- **Storage Speed**: 10MB read/write test
- **Temperature Stress**: 10-second CPU load test

### Scoring Weights (Performance Score)
- CPU: 30%
- RAM: 20%
- GPU: 20%
- Storage: 15%
- Display: 10%
- Other: 5%

---

## 📊 HTML Report Features

The generated HTML report includes:

### Tabs
1. **Overview** - Complete system information
2. **Battery** - Detailed battery analysis
3. **Temperature** - Cooling performance with stress test
4. **Hardware Details** - Extended component information
5. **Keyboard Test** - Interactive key testing
6. **Touchpad Test** - Drawing canvas for mouse/touchpad
7. **Display Test** - Dead pixel detection
8. **Audio Test** - Speaker stereo testing
9. **Recommendations** - Use cases and upgrade suggestions

### Visual Features
- Responsive design (mobile-friendly)
- Progress bars and visual indicators
- Color-coded health status
- Interactive test interfaces
- Print-friendly layout

---

## 🐛 Troubleshooting

### "Execution Policy" Error
Run this in PowerShell (as Administrator):
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

### Temperature Not Detected
Some laptops don't expose temperature sensors. This is normal.

### USB Port Count Seems Wrong
The tool estimates physical ports from USB controllers. Some laptops have internal hubs that affect detection.

### WiFi Not Detected
Ensure WiFi is enabled in Windows settings. The tool detects the adapter even if not connected.

---

## 📝 Version History

### v15.0 (October 2025)
- Fixed tab switching in HTML report
- Added CPU temperature stress test
- Added screen size detection (inches)
- Added touchscreen detection
- Enhanced WiFi detection (Centrino, Advanced-N)
- Improved USB port detection
- Added USB-C port detection
- Added keyboard backlight detection
- Added webcam detection (even disabled)
- Added MIL-STD certification check
- Fixed all JavaScript errors

### v14.0
- Added dual rating system
- Hardware database with 2025 benchmarks
- Performance tier classification
- Use case recommendations
- Upgrade suggestions with cost analysis

### v13.0
- Initial single-score health rating
- Basic hardware detection
- HTML report generation

---

## 🤝 Support & Contact

**Developer**: Tanxe Studio

For issues or suggestions, please document:
1. Windows version
2. PowerShell version (`$PSVersionTable.PSVersion`)
3. Error message or unexpected behavior
4. Generated report (if applicable)

---

## 📜 License

This tool is provided as-is for personal diagnostic use. The hardware database and benchmark data are based on publicly available specifications as of 2025.

---

## ⚠️ Disclaimer

- This tool provides estimates based on available data
- Actual performance may vary based on specific hardware configurations
- Upgrade costs are estimates and may vary by region and retailer
- Always backup important data before making hardware changes
- Consult a professional for critical system modifications

---

**Last Updated**: October 25, 2025
**Version**: 15.0
**Build**: Final Release

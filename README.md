# Signature Audit Script

A PowerShell script for auditing digital signatures of executable files across directory structures. Generates detailed logs and CSV reports for security compliance and software inventory analysis.

## 📋 Overview

This tool recursively scans specified directories, verifies Authenticode digital signatures of files with configurable extensions, and produces comprehensive reports. It's ideal for:
- Security compliance auditing
- Software inventory management
- Detecting unsigned or tampered executables
- Certificate expiration tracking
- Incident response investigations

## ✨ Features

- **Digital Signature Verification** — validates file authenticity and integrity using Windows Authenticode
- **Recursive Scanning** — traverses entire directory trees
- **Configurable File Types** — specify which extensions to check (default: `.exe`)
- **Smart Filtering** — optional `-UnsignedOnly` mode for focusing on problematic files
- **Dual Output** — generates both a detailed text log and structured CSV report
- **Error Resilience** — handles permission issues and corrupted files gracefully
- **Certificate Details** — captures signer information, thumbprint, and expiration dates
- **UTF-8 Encoding** — ensures proper character encoding in CSV output

## 🚀 Installation

Clone the repository or download the script directly:

```powershell
# Download the script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/your-repo/signature_audit.ps1" -OutFile "signature_audit.ps1"
```

Make sure you have **PowerShell 5.0+** (comes pre-installed with Windows 10/11 and Windows Server 2016+).

## 📖 Usage

### Basic Syntax

```powershell
.\signature_audit.ps1 -Roots <string[]> -LogPath <string> [-Extensions <string[]>] [-UnsignedOnly]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Roots` | `string[]` | ✅ Yes | One or more root directories to scan |
| `-LogPath` | `string` | ✅ Yes | Full path to the log file (CSV will be created in the same directory) |
| `-Extensions` | `string[]` | ❌ No | File extensions to check (default: `@('.exe')`) |
| `-UnsignedOnly` | `switch` | ❌ No | Report only files with invalid or missing signatures |

### Examples

#### 1. Basic Scan - Check all .exe files in Program Files

```powershell
.\signature_audit.ps1 -Roots "C:\Program Files" -LogPath "C:\Audit\scan_log.txt"
```

#### 2. Scan Multiple Directories with Custom Extensions

```powershell
.\signature_audit.ps1 -Roots "C:\Program Files", "C:\Windows\System32" -LogPath "C:\Audit\audit.txt" -Extensions ".exe",".dll",".sys"
```

#### 3. Find Only Problematic Files (Unsigned/Invalid)

```powershell
.\signature_audit.ps1 -Roots "D:\Apps" -LogPath "D:\Reports\unsigned.txt" -UnsignedOnly
```

#### 4. Scan Network Drive

```powershell
.\signature_audit.ps1 -Roots "\\server\share\applications" -LogPath "C:\Logs\network_scan.txt"
```

## 📊 Output

### Text Log File
Contains a timestamped record of all operations:

```
2026-08-25 14:23:45 :: Start scan. Roots=C:\Program Files, C:\Windows\System32 Extensions=.exe, .dll UnsignedOnly=False
2026-08-25 14:23:46 :: Scanning root: C:\Program Files
2026-08-25 14:23:47 :: Valid :: C:\Program Files\App\app.exe
2026-08-25 14:24:15 :: NotSigned :: C:\Program Files\Tool\helper.exe
2026-08-25 14:25:30 :: Error :: C:\Program Files\Protected\secure.dll :: Access denied
2026-08-25 14:30:00 :: Finished. CSV=C:\Audit\scan_log.csv
```

### CSV Report
Structured data with the following columns:

| Column | Description |
|--------|-------------|
| `Root` | Source directory that was scanned |
| `Path` | Full file system path |
| `Name` | File name |
| `Extension` | File extension |
| `SizeMB` | File size in megabytes |
| `Status` | Signature status: `Valid`, `Invalid`, `NotSigned`, or `Error` |
| `Signer` | Certificate subject (who signed the file) |
| `Thumbprint` | Certificate thumbprint (SHA-1 hash) |
| `NotAfter` | Certificate expiration date |

**Status Definitions:**
- **Valid** — Digitally signed and signature is intact
- **Invalid** — Signature exists but is corrupted or tampered
- **NotSigned** — No digital signature present
- **Error** — Verification failed (permission issues, corrupted file, etc.)

### Sample CSV Output

```csv
Root,Path,Name,Extension,SizeMB,Status,Signer,Thumbprint,NotAfter
C:\Program Files, C:\Program Files\App\app.exe,app.exe,.exe,15.23,Valid,Microsoft Corporation,ABC123DEF456...,2027-12-31 23:59:59
C:\Program Files, C:\Program Files\Tool\helper.exe,helper.exe,.exe,2.45,NotSigned,,,
```

## 🔧 Advanced Usage

### Running on Multiple Servers

```powershell
$servers = @("server01", "server02", "server03")
foreach ($server in $servers) {
    Invoke-Command -ComputerName $server -ScriptBlock {
        C:\Scripts\signature_audit.ps1 -Roots "C:\Program Files" -LogPath "C:\Logs\audit_$env:COMPUTERNAME.txt"
    }
}
```

### Scheduled Task Automation

Create a scheduled task to run the audit weekly:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\signature_audit.ps1 -Roots 'C:\Program Files' -LogPath 'C:\Reports\audit_$(Get-Date -Format yyyyMMdd).txt'"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2am
Register-ScheduledTask -TaskName "SignatureAudit" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
```

## ⚠️ Requirements & Limitations

- **Operating System**: Windows 7/8/10/11, Windows Server 2008 R2+
- **PowerShell Version**: 5.0 or higher
- **Permissions**: 
  - Read access to target directories
  - Write access to log file directory
  - For system directories (e.g., `C:\Windows\System32`), run as Administrator
- **Performance**: Scanning large directories (100,000+ files) may take significant time
- **Network Drives**: UNC paths are supported but may be slower

## 🐛 Troubleshooting

### "Access Denied" Errors
- Run PowerShell as Administrator
- Check file/folder permissions
- For system protected files, you may need TrustedInstaller privileges

### Script Takes Too Long
- Reduce scan scope using more specific root paths
- Use `-UnsignedOnly` to reduce output processing
- Filter extensions to only essential file types

### CSV Not Generating
- Verify write permissions in the log directory
- Ensure the log directory path is valid
- Check disk space availability

### Signature Verification Fails
- Ensure Windows is up to date (root certificates may be expired)
- Verify the file isn't corrupted
- Check if the file is from a trusted publisher

## 📝 Changelog

### v1.0.0 (Initial Release)
- Core signature verification functionality
- Recursive directory scanning
- CSV and log output generation
- Configurable file extensions
- Unsigned-only filtering mode

## 🤝 Contributing

Contributions are welcome! Please feel free to submit:
- Bug reports
- Feature requests
- Pull requests with improvements

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with different directory structures
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 💬 Support

For issues or questions:
- Open an issue on GitHub
- Review the troubleshooting section above
- Check PowerShell event logs for detailed errors

---

**⚠️ Disclaimer**: This tool is provided "as is" without warranty of any kind. Always test in a non-production environment first. Verify critical files using official Microsoft tools like `signtool.exe` for mission-critical applications.
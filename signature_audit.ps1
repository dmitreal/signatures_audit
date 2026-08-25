param(
    [Parameter(Mandatory = $true)]
    [string[]]$Roots,

    [Parameter(Mandatory = $true)]
    [string]$LogPath,

    [string[]]$Extensions = @('.exe'),

    [switch]$UnsignedOnly
)

$logDir = Split-Path -Path $LogPath -Parent
if ($logDir -and -not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LogPath -Value "$ts :: $Message"
}

Write-Log "Start scan. Roots=$($Roots -join ', ') Extensions=$($Extensions -join ', ') UnsignedOnly=$UnsignedOnly"

$report = foreach ($root in $Roots) {
    Write-Log "Scanning root: $root"

    Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() } |
        ForEach-Object {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $_.FullName
                $status = [string]$sig.Status

                $row = [pscustomobject]@{
                    Root       = $root
                    Path       = $_.FullName
                    Name       = $_.Name
                    Extension  = $_.Extension
                    SizeMB     = [math]::Round($_.Length / 1MB, 2)
                    Status     = $status
                    Signer     = $sig.SignerCertificate.Subject
                    Thumbprint = $sig.SignerCertificate.Thumbprint
                    NotAfter   = $sig.SignerCertificate.NotAfter
                }

                if (-not $UnsignedOnly -or $status -ne 'Valid') {
                    Write-Log "$status :: $($_.FullName)"
                    $row
                }
            } catch {
                Write-Log "Error :: $($_.FullName) :: $($_.Exception.Message)"
                if (-not $UnsignedOnly) {
                    [pscustomobject]@{
                        Root       = $root
                        Path       = $_.FullName
                        Name       = $_.Name
                        Extension  = $_.Extension
                        SizeMB     = [math]::Round($_.Length / 1MB, 2)
                        Status     = 'Error'
                        Signer     = $null
                        Thumbprint = $null
                        NotAfter   = $null
                    }
                }
            }
        }
}

$csvPath = [System.IO.Path]::ChangeExtension($LogPath, '.csv')
$report | Sort-Object Status, Path | Export-Csv -NoTypeInformation -Encoding UTF8 -Path $csvPath

Write-Log "Finished. CSV=$csvPath"
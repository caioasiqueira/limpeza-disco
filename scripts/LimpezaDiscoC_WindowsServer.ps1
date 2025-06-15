# Caminho do CSV no compartilhamento de rede
$csvPath = "\\SEU_SERVIDOR\COMPARTILHAMENTO\LimpezaDisco.csv"

function Get-FreeDiskSpaceGB {
    $drive = Get-PSDrive -Name C
    return [math]::Round($drive.Free / 1GB, 2)
}

function Get-OSInfo {
    return (Get-CimInstance Win32_OperatingSystem).Caption
}

function Clear-Lixeira {
    try {
        if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) {
            Clear-RecycleBin -DriveLetter C -Force -ErrorAction Stop
        } else {
            Remove-Item -Path "C:\$Recycle.Bin\*" -Recurse -Force -ErrorAction Stop
        }
        Write-Host "Lixeira do C:\ limpa com sucesso." -ForegroundColor Green
    } catch {
        Write-Warning "Erro ao tentar limpar a lixeira: $_"
    }
}

function Clear-WindowsUpdateCache {
    Write-Output "Limpando cache do Windows Update..."
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
}

function Clear-FilesOlderThan7Days {
    $paths = @(
        "C:\Temp",
        "C:\Windows\LiveKernelReports",
        "C:\Program Files\DebugDiag\Logs",
        "C:\Windows\ccmcache",
        "C:\Windows\Temp",
        "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files",
        "C:\Windows\Microsoft.NET\Framework\v4.0.30319\Temporary ASP.NET Files"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Output "Limpando arquivos com mais de 7 dias em: $path"
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Clear-IISLogsOlderThan7Days {
    $paths = @(
        "C:\inetpub\logs\LogFiles",
        "C:\inetpub\mailroot\Badmail",
        "C:\Windows\System32\LogFiles\HTTPERR"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Output "Limpando arquivos com mais de 7 dias em: $path"
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
}

function Clear-Dumps {
    Write-Output "Limpando arquivos de Dump..."
    dir "C:\Windows\*.dmp" | where { ((Get-Date)-$_.CreationTime).days -gt 7} | Remove-Item -Force
    if (test-path "C:\Windows\System32\config\systemprofile\AppData\Local\CrashDumps") {Get-ChildItem -Path "C:\Windows\System32\config\systemprofile\AppData\Local\CrashDumps" -File -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-7))} | Remove-Item}
    if (test-path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\CrashDumps") {Get-ChildItem -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\CrashDumps" -File -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-7))} | Remove-Item}
    if (test-path "C:\Windows\System32\%LOCALAPPDATA%\CrashDumps") {Get-ChildItem -Path "C:\Windows\System32\%LOCALAPPDATA%\CrashDumps" -File -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-7))} | Remove-Item}
}

function Clear-OldUserProfiles {
    param(
        [int]$DaysInactive = 60,
        [switch]$DeleteProfiles = $true,
        [switch]$QuietMode = $true
    )

    # Verifica se o sistema é Windows Server 2019 ou superior
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $caption = $osInfo.Caption
    $version = [version]$osInfo.Version

    if ($caption -notmatch "Windows Server" -or $version -lt [version]"10.0.17763") {
        Write-Host "Sistema operacional não suportado para a limpeza de perfis. Requer Windows Server 2019 ou superior." -ForegroundColor Yellow
        return @()
    }

    $results = @()

    $UnloadedProfiles = Get-WmiObject win32_userprofile -Filter "Loaded = 'False' and Special = 'False'" -ErrorAction SilentlyContinue

    foreach ($profile in $UnloadedProfiles) {
        try {
            $sid = $profile.SID
            $userInfo = [WMI]"Win32_SID.SID='$sid'"
            $userName = "$($userInfo.ReferencedDomainName)\$($userInfo.AccountName)"
            $lastUse = $null

            $regKey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"
            if (Test-Path $regKey) {
                $low = (Get-ItemProperty -Path $regKey).LocalProfileUnloadTimeLow
                $high = (Get-ItemProperty -Path $regKey).LocalProfileUnloadTimeHigh
                $ft = ([UInt64]$high -shl 32) -bor $low
                $lastUse = [datetime]::FromFileTime($ft)
            }

            $daysOld = if ($lastUse) { ((Get-Date) - $lastUse).Days } else { 99999 }

            $deleted = $false
            if ($daysOld -ge $DaysInactive) {
                if ($DeleteProfiles) {
                    $profile.Delete() | Out-Null
                    $deleted = $true
                }
            }

            $results += [PSCustomObject]@{
                ProfilePath = $profile.LocalPath
                UserName    = $userName
                DaysOld     = $daysOld
                Deleted     = $deleted
            }
        } catch {
            # Handle errors
        }
    }

    return $results
}

function Clear-UsersFilesOldThan7Days {
    $pastasPadrao = @("Documents", "Desktop", "Downloads")
    $pastasAppData = @("AppData\Local\Temp", "AppData\Local\CrashDumps")

    $usuarios = Get-ChildItem -Directory C:\Users | Where-Object {
        $_.Name -notin @("Default", "Default User", "Public", "All Users") -and
        -not ($_.Attributes -match "Hidden")
    }

    foreach ($usuario in $usuarios) {
        foreach ($pasta in $pastasPadrao) {
            $caminho = "C:\Users\$($usuario.Name)\$pasta"
            if (Test-Path $caminho) {
                Write-Output "Limpando: $caminho"
                Get-ChildItem -Path $caminho -File -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }

        foreach ($pasta in $pastasAppData) {
            $caminho = "C:\Users\$($usuario.Name)\$pasta"
            if (Test-Path $caminho) {
                Write-Output "Limpando: $caminho"
                Get-ChildItem -Path $caminho -File -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Run-Cleanup {
    $hostname = $env:COMPUTERNAME
    $so = Get-OSInfo
    $espacoAntes = Get-FreeDiskSpaceGB
    $data = Get-Date -Format "dd-MM-yyyy"

    # Ações de limpeza
    Clear-Lixeira
    Clear-WindowsUpdateCache
    Clear-FilesOlderThan7Days
    Clear-IISLogsOlderThan7Days
    Clear-Dumps
    Clear-OldUserProfiles
    Clear-UsersFilesOldThan7Days

    $espacoDepois = Get-FreeDiskSpaceGB
    $recuperado = [math]::Round($espacoDepois - $espacoAntes, 2)

    # Resultado
    $resultado = [PSCustomObject]@{
        Hostname             = $hostname
        SistemaOperacional   = $so
        EspacoLivreAntesGB   = $espacoAntes
        EspacoLivreDepoisGB  = $espacoDepois
        EspacoRecuperadoGB   = $recuperado
        Data                 = $data
    }

    # Salva no CSV
    if (!(Test-Path $csvPath)) {
        $resultado | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    } else {
        $resultado | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Append
    }

    return $resultado
}

# Executar
Run-Cleanup

$filePath = "\\tsclient\home\.local\share\winapps\sleep_marker"
$networkPath = "\\tsclient\home"

function Monitor-File {
    while ($true) {
        try {
            $null = Test-Path -Path $networkPath -ErrorAction Stop
            if (Test-Path -Path $filePath) {
                w32tm /resync /quiet
                Remove-Item -Path $filePath -Force
            }
        }
        catch {}
        Start-Sleep -Seconds 3000
    }
}

Monitor-File

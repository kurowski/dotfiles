$currentProfile = (Get-NetConnectionProfile).Name
$profilesKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles"
$profiles = Get-ChildItem -Path $profilesKey

foreach ($profile in $profiles) {
    $profilePath = "$profilesKey\$($profile.PSChildName)"
    $profileName = (Get-ItemProperty -Path $profilePath).ProfileName
    if ($profileName -ne $currentProfile) {
        Remove-Item -Path $profilePath -Recurse
    }
}

$profiles = Get-ChildItem -Path $profilesKey
foreach ($profile in $profiles) {
    $profilePath = "$profilesKey\$($profile.PSChildName)"
    $profileName = (Get-ItemProperty -Path $profilePath).ProfileName
    if ($profileName -eq $currentProfile) {
        Set-ItemProperty -Path $profilePath -Name "ProfileName" -Value "WinApps"
    }
}

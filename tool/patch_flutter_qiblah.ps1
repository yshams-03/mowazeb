# Re-applies after `flutter pub get` — flutter_qiblah still references deprecated jcenter().
$path = Join-Path $env:LOCALAPPDATA "Pub\Cache\hosted\pub.dev\flutter_qiblah-3.1.0+1\android\build.gradle"
if (-not (Test-Path $path)) {
    Write-Host "flutter_qiblah not found at $path — skip patch."
    exit 0
}
$content = Get-Content $path -Raw
$patched = $content -replace 'jcenter\(\)', 'mavenCentral()'
if ($content -eq $patched) {
    Write-Host "flutter_qiblah already patched."
    exit 0
}
Set-Content -Path $path -Value $patched -NoNewline
Write-Host "Patched flutter_qiblah: jcenter() -> mavenCentral()"

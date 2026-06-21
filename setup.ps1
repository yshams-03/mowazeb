# Run from project root after Flutter is installed and on PATH.

Write-Host "Generating Flutter platform folders..." -ForegroundColor Cyan
& "$env:LOCALAPPDATA\flutter\bin\flutter.bat" create . --project-name ummah_pulse --org com.ummahpulse

Write-Host "Installing dependencies..." -ForegroundColor Cyan
& "$env:LOCALAPPDATA\flutter\bin\flutter.bat" pub get

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "  1. flutterfire configure"
Write-Host "  2. Enable Email/Password + Google auth in Firebase Console"
Write-Host "  3. Deploy firestore.rules"
Write-Host "  4. flutter run"

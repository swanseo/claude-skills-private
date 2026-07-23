# PICASEO Claude Skills 윈도우 동기화 스크립트

$skillsPath = "$env:USERPROFILE\.claude\skills"

Write-Host "PICASEO Claude Skills 동기화 시작" -ForegroundColor Cyan
Set-Location $skillsPath

Write-Host "원격 변경 사항 확인 중..." -ForegroundColor Yellow
git fetch

$status = git status -uno

if ($status -match "Your branch is behind") {
    Write-Host "원격에 새 변경 사항 있음. Pull 진행..." -ForegroundColor Green
    git pull
} elseif ($status -match "Your branch is up to date") {
    Write-Host "이미 최신 상태입니다." -ForegroundColor Green
} else {
    Write-Host "로컬 변경 사항 있음:" -ForegroundColor Yellow
    git status --short
    $confirm = Read-Host "커밋하고 푸시하시겠습니까? (y/n)"
    if ($confirm -eq "y") {
        $message = Read-Host "커밋 메시지"
        git add .
        git commit -m $message
        git push
    }
}

Write-Host "완료." -ForegroundColor Cyan

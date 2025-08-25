@echo off
echo ====================================
echo  Git Commit, Push & Discord Notify
echo ====================================
echo.

:: Step 1: Commit and push changes
echo Step 1: Committing and pushing changes...
call commit_and_push.bat
if %ERRORLEVEL% neq 0 (
    echo.
    echo Commit/Push failed. Discord notification skipped.
    pause
    exit /b 1
)

echo.
echo Step 2: Sending Discord notification...
echo.

:: Step 2: Send Discord notification
powershell -ExecutionPolicy Bypass -File discord_notify.ps1

echo.
echo ====================================
echo All operations completed!
echo ====================================
pause

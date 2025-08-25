@echo off
echo Starting Git commit and push process...
echo Repository: %cd%
echo.

:: Check if there are changes
echo Checking for changes...
git status --porcelain > temp_status.txt
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to check git status
    pause
    exit /b 1
)

:: Check if temp file has content (changes exist)
for /f %%i in ("temp_status.txt") do set size=%%~zi
if %size% equ 0 (
    echo No changes to commit
    del temp_status.txt
    pause
    exit /b 0
)

echo Changes detected:
type temp_status.txt
del temp_status.txt
echo.

:: Add all changes
echo Adding all changes to staging area...
git add .
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to add changes
    pause
    exit /b 1
)
echo Changes added successfully
echo.

:: Get commit message from user
set /p commit_msg="Enter commit message (or press Enter for auto-generated): "
if "%commit_msg%"=="" (
    for /f "tokens=1-4 delims=/ " %%i in ('date /t') do set mydate=%%i/%%j/%%k
    for /f "tokens=1-2 delims=: " %%i in ('time /t') do set mytime=%%i:%%j
    set commit_msg=Auto-commit: Updates on %mydate% %mytime%
)

:: Commit changes
echo Committing changes with message: "%commit_msg%"
git commit -m "%commit_msg%"
if %ERRORLEVEL% neq 0 (
    echo Error: Failed to commit changes
    pause
    exit /b 1
)
echo Changes committed successfully
echo.

:: Get current branch
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set current_branch=%%i
if "%current_branch%"=="" (
    for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set current_branch=%%i
)
if "%current_branch%"=="" set current_branch=main

:: Push changes
echo Pushing to remote repository on branch: %current_branch%
git push origin %current_branch%
if %ERRORLEVEL% neq 0 (
    echo Warning: Push failed. This might be because:
    echo - No remote repository is configured
    echo - Authentication issues
    echo - Network connectivity problems
    echo.
    echo To configure a remote repository, run:
    echo git remote add origin YOUR_REPOSITORY_URL
    echo.
    echo Commit was successful even if push failed.
    pause
    exit /b 1
)
echo Changes pushed successfully
echo.

:: Get commit information for Discord notification
echo Getting commit information...
for /f "tokens=*" %%i in ('git log -1 --pretty^=format:"%%H|%%an|%%ae|%%s|%%ad" --date^=iso 2^>nul') do set commit_info=%%i

:: Save commit info to file for Discord notification
echo Commit Info: %commit_info% > commit_info.txt
echo Branch: %current_branch% >> commit_info.txt
echo Repository: test_dir >> commit_info.txt

echo.
echo ================================
echo Process completed successfully!
echo Committed and pushed to branch: %current_branch%
echo Commit info saved to commit_info.txt
echo ================================
echo.
echo Next: Run the Discord notification script or manually send notification
pause

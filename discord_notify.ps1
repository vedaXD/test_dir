# Discord Notification Script for Git Commits
# PowerShell script to send commit notifications to Discord

param(
    [string]$WebhookUrl = "",
    [string]$CommitInfoFile = "commit_info.txt"
)

# Discord webhook URL - REPLACE WITH YOUR ACTUAL WEBHOOK URL
if ($WebhookUrl -eq "") {
    $WebhookUrl = "YOUR_DISCORD_WEBHOOK_URL_HERE"
}

# Check if webhook URL is configured
if ($WebhookUrl -eq "YOUR_DISCORD_WEBHOOK_URL_HERE" -or $WebhookUrl -eq "") {
    Write-Host "⚠️  Discord webhook URL not configured!" -ForegroundColor Yellow
    Write-Host "To enable Discord notifications:" -ForegroundColor Cyan
    Write-Host "1. Create a webhook in your Discord server" -ForegroundColor Cyan
    Write-Host "2. Replace 'YOUR_DISCORD_WEBHOOK_URL_HERE' in this script with your webhook URL" -ForegroundColor Cyan
    Write-Host "3. Or run: .\discord_notify.ps1 -WebhookUrl 'YOUR_WEBHOOK_URL'" -ForegroundColor Cyan
    Read-Host "Press Enter to continue"
    exit 1
}

# Check if commit info file exists
if (-not (Test-Path $CommitInfoFile)) {
    Write-Host "❌ Commit info file not found: $CommitInfoFile" -ForegroundColor Red
    Write-Host "Make sure to run commit_and_push.bat first" -ForegroundColor Yellow
    Read-Host "Press Enter to continue"
    exit 1
}

# Read commit information
try {
    $commitData = Get-Content $CommitInfoFile
    $commitInfo = $commitData[0] -replace "Commit Info: ", ""
    $branch = $commitData[1] -replace "Branch: ", ""
    $repo = $commitData[2] -replace "Repository: ", ""
    
    # Parse commit info
    $parts = $commitInfo -split "\|"
    if ($parts.Count -eq 5) {
        $hash = $parts[0].Substring(0, 8)  # Short hash
        $author = $parts[1]
        $email = $parts[2]
        $message = $parts[3]
        $date = $parts[4]
    } else {
        throw "Invalid commit info format"
    }
} catch {
    Write-Host "❌ Error parsing commit information: $_" -ForegroundColor Red
    Read-Host "Press Enter to continue"
    exit 1
}

# Create Discord embed
$embed = @{
    title = "📝 New Commit to $repo"
    description = $message
    color = 3447003  # Blue color
    fields = @(
        @{
            name = "👤 Author"
            value = $author
            inline = $true
        },
        @{
            name = "🌿 Branch"
            value = $branch
            inline = $true
        },
        @{
            name = "🔗 Commit Hash"
            value = "``$hash``"
            inline = $true
        },
        @{
            name = "📅 Date"
            value = $date
            inline = $false
        }
    )
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    footer = @{
        text = "Git Auto-Commit Bot"
    }
}

# Create payload
$payload = @{
    username = "Git Bot"
    embeds = @($embed)
} | ConvertTo-Json -Depth 10

# Send to Discord
try {
    Write-Host "📢 Sending Discord notification..." -ForegroundColor Cyan
    
    $headers = @{
        'Content-Type' = 'application/json'
    }
    
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -Headers $headers
    
    Write-Host "✅ Discord notification sent successfully!" -ForegroundColor Green
    
    # Clean up commit info file
    Remove-Item $CommitInfoFile -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "❌ Failed to send Discord notification: $_" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Process completed!" -ForegroundColor Green
Read-Host "Press Enter to continue"

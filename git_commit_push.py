#!/usr/bin/env python3
"""
Git Commit & Push with Discord Notification Script
This script automates committing and pushing changes, then sends a Discord notification.
"""

import subprocess
import json
import requests
import sys
import os
from datetime import datetime

# Configuration
REPO_PATH = r"C:\Users\HP\Desktop\test_dir"
DISCORD_WEBHOOK_URL = "YOUR_DISCORD_WEBHOOK_URL_HERE"  # Replace with your Discord webhook URL

def run_git_command(command, cwd=REPO_PATH):
    """Execute a git command and return the result."""
    try:
        result = subprocess.run(command, 
                              shell=True, 
                              cwd=cwd, 
                              capture_output=True, 
                              text=True, 
                              check=True)
        return result.stdout.strip(), True
    except subprocess.CalledProcessError as e:
        print(f"Git command failed: {command}")
        print(f"Error: {e.stderr}")
        return e.stderr.strip(), False

def check_git_status():
    """Check if there are any changes to commit."""
    output, success = run_git_command("git status --porcelain")
    if not success:
        return False, "Failed to check git status"
    
    if not output:
        return False, "No changes to commit"
    
    return True, output

def add_all_changes():
    """Add all changes to staging area."""
    output, success = run_git_command("git add .")
    return success, output

def commit_changes(message=None):
    """Commit the staged changes."""
    if not message:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        message = f"Auto-commit: Updates on {timestamp}"
    
    command = f'git commit -m "{message}"'
    output, success = run_git_command(command)
    return success, output

def push_changes():
    """Push changes to remote repository."""
    # First, try to get the current branch
    branch_output, branch_success = run_git_command("git branch --show-current")
    if not branch_success:
        branch_output, branch_success = run_git_command("git rev-parse --abbrev-ref HEAD")
    
    if branch_success and branch_output:
        branch_name = branch_output.strip()
        command = f"git push origin {branch_name}"
    else:
        command = "git push"
    
    output, success = run_git_command(command)
    return success, output, branch_name if branch_success else "unknown"

def get_last_commit_info():
    """Get information about the last commit."""
    command = 'git log -1 --pretty=format:"%H|%an|%ae|%s|%ad" --date=iso'
    output, success = run_git_command(command)
    
    if success and output:
        parts = output.split('|')
        if len(parts) == 5:
            return {
                'hash': parts[0][:8],  # Short hash
                'author': parts[1],
                'email': parts[2],
                'message': parts[3],
                'date': parts[4]
            }
    return None

def send_discord_notification(commit_info, branch_name, repo_name="test_dir"):
    """Send notification to Discord webhook."""
    if not DISCORD_WEBHOOK_URL or DISCORD_WEBHOOK_URL == "YOUR_DISCORD_WEBHOOK_URL_HERE":
        print("⚠️  Discord webhook URL not configured. Skipping Discord notification.")
        print("To enable Discord notifications:")
        print("1. Create a webhook in your Discord server")
        print("2. Replace 'YOUR_DISCORD_WEBHOOK_URL_HERE' with your webhook URL")
        return False
    
    if not commit_info:
        print("❌ Could not retrieve commit information for Discord notification")
        return False
    
    # Create embed for Discord
    embed = {
        "title": f"📝 New Commit to {repo_name}",
        "description": commit_info['message'],
        "color": 3447003,  # Blue color
        "fields": [
            {
                "name": "👤 Author",
                "value": commit_info['author'],
                "inline": True
            },
            {
                "name": "🌿 Branch",
                "value": branch_name,
                "inline": True
            },
            {
                "name": "🔗 Commit Hash",
                "value": f"`{commit_info['hash']}`",
                "inline": True
            },
            {
                "name": "📅 Date",
                "value": commit_info['date'],
                "inline": False
            }
        ],
        "timestamp": datetime.now().isoformat(),
        "footer": {
            "text": "Git Auto-Commit Bot"
        }
    }
    
    payload = {
        "username": "Git Bot",
        "embeds": [embed]
    }
    
    try:
        response = requests.post(DISCORD_WEBHOOK_URL, 
                               json=payload,
                               headers={'Content-Type': 'application/json'})
        
        if response.status_code == 204:
            print("✅ Discord notification sent successfully!")
            return True
        else:
            print(f"❌ Discord notification failed: {response.status_code}")
            print(response.text)
            return False
            
    except requests.RequestException as e:
        print(f"❌ Failed to send Discord notification: {e}")
        return False

def main():
    """Main function to orchestrate the git operations and notification."""
    print("🚀 Starting Git commit and push process...")
    print(f"📁 Repository: {REPO_PATH}")
    print("-" * 50)
    
    # Check if there are changes to commit
    has_changes, status_output = check_git_status()
    if not has_changes:
        print(f"ℹ️  {status_output}")
        return
    
    print("📋 Changes detected:")
    for line in status_output.split('\n'):
        if line.strip():
            print(f"   {line}")
    
    # Add all changes
    print("\n📦 Adding changes to staging area...")
    add_success, add_output = add_all_changes()
    if not add_success:
        print(f"❌ Failed to add changes: {add_output}")
        return
    print("✅ Changes added successfully")
    
    # Commit changes
    print("\n💾 Committing changes...")
    commit_message = input("Enter commit message (or press Enter for auto-generated): ").strip()
    commit_success, commit_output = commit_changes(commit_message if commit_message else None)
    if not commit_success:
        print(f"❌ Failed to commit changes: {commit_output}")
        return
    print("✅ Changes committed successfully")
    
    # Push changes
    print("\n🚀 Pushing to remote repository...")
    push_success, push_output, branch_name = push_changes()
    if not push_success:
        print(f"❌ Failed to push changes: {push_output}")
        print("Note: Make sure you have a remote repository configured and proper access rights")
        return
    print("✅ Changes pushed successfully")
    
    # Get commit information
    print("\n📊 Retrieving commit information...")
    commit_info = get_last_commit_info()
    
    # Send Discord notification
    print("\n📢 Sending Discord notification...")
    discord_success = send_discord_notification(commit_info, branch_name)
    
    print("\n" + "="*50)
    print("🎉 Process completed!")
    print(f"✅ Committed and pushed to branch: {branch_name}")
    if discord_success:
        print("✅ Discord notification sent")
    print("="*50)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n❌ Process interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")
        sys.exit(1)

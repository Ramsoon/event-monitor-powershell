<#
.SYNOPSIS
Monitors Windows Event Logs for critical or error-level events and sends alerts.

.DESCRIPTION
This script retrieves new critical/error log events from the System and Application logs,
records them to a log file, and sends webhook notifications (e.g., Slack, Teams, Telegram)
whenever new alerts are found. It remembers the last run time to avoid duplicate alerts.

.PARAMETER LogFile
Path to the file where detected events should be logged.

.PARAMETER WebhookUrl
Webhook URL for sending alerts (Slack/Teams/Telegram).

.EXAMPLE
.\EventMonitor.ps1 -LogFile "C:\Users\Delice\Documents\Devops\powershellScripts\EventMonitor\Alerts.log" -WebhookUrl "https://hooks.slack.com/services/XXXX"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$LogFile,

    [Parameter(Mandatory = $true)]
    [string]$WebhookUrl
)

# Track last run time (to avoid repeat alerts)
$LastRunFile = Join-Path (Split-Path $LogFile) "LastRun.txt"

if (Test-Path $LastRunFile) {
    $LastRun = Get-Content $LastRunFile
} else {
    # If first run, only alert events from last 10 minutes
    $LastRun = (Get-Date).AddMinutes(-10)
}

# Write new timestamp for next run
(Get-Date) | Out-File $LastRunFile -Force

# Query System + Application logs for Critical / Error events
$Events = Get-WinEvent -FilterHashtable @{
    LogName = @("System","Application")
    Level = 1,2  # 1 = Critical, 2 = Error
    StartTime = $LastRun
}

foreach ($Event in $Events) {

    $Entry = "[{0}] {1} - {2}" -f $Event.TimeCreated, $Event.ProviderName, $Event.Message

    # Log it locally
    $Entry | Out-File -Append $LogFile

    # Send webhook notification payload
    $Payload = @{
        text = "⚠️ *Critical System Event Detected*`nServer: $env:COMPUTERNAME`nTime: $($Event.TimeCreated)`nSource: $($Event.ProviderName)`nMessage: $($Event.Message)"
    } | ConvertTo-Json

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Payload -ContentType 'application/json'
    }
    catch {
        "[$(Get-Date)] Failed to send alert: $_" | Out-File -Append $LogFile
    }
}

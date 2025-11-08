# event-monitor-powershell
This script retrieves new critical/error log events from the System and Application logs, records them to a log file, and sends webhook notifications (e.g., Slack, Teams, Telegram) whenever new alerts are found. It remembers the last run time to avoid duplicate alerts.

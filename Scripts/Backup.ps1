# Load the configuration file
$dbConfigPath = ".\Config\dbConfig.json"
$dbConfig = Get-Content -Path $dbConfigPath | ConvertFrom-Json

$dirConfigPath = ".\Config\dirConfig.json"
$dirConfig = Get-Content -Path $dirConfigPath | ConvertFrom-Json
# $projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition  # Get the current project directory

# Define SQL Server instance and database details from config
$serverName = $dbConfig.ServerName
$databaseName = $dbConfig.DatabaseName
$backupFolder = $dirConfig.BackupFolder
$logFolder = $dirConfig.LogFolder 

# Ensure the output and logs directories exist
if (-not (Test-Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory
}

if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory
}

# Define the backup file path with timestamp
$backupFile = "$backupFolder\$databaseName_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
$logFile = "$logFolder\backup_$(Get-Date -Format 'yyyyMMdd').log"

# Define the SQL Server connection string
$connectionString = "Server=$serverName;Integrated Security=True;"

# SQL query to perform the backup
$query = "BACKUP DATABASE [$databaseName] TO DISK = N'$backupFile' WITH NOFORMAT, NOINIT, NAME = N'$databaseName Full Backup', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

# Load the SQL Server module
Import-Module SqlServer

# Log the start time
$startTime = Get-Date
"Backup started at $startTime" | Out-File -FilePath $logFile -Append

try {
    # Perform the backup
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $query

    # Confirm backup success and log it
    if (Test-Path $backupFile) {
        $endTime = Get-Date
        "Backup completed successfully at $endTime. Backup file: $backupFile" | Out-File -FilePath $logFile -Append
        Write-Host "Backup completed successfully: $backupFile"
    } else {
        throw "Backup file not created."
    }
} catch {
    $errorTime = Get-Date
    "Backup failed at $errorTime. Error: $_" | Out-File -FilePath $logFile -Append
    Write-Host "Backup failed."
}

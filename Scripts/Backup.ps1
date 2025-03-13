# Load configuration files
$dbConfigPath = ".\Config\dbConfig.json"
$dirConfigPath = ".\Config\dirConfig.json"

if (!(Test-Path -Path $dbConfigPath)) {
    Write-Host "Database config file not found: $dbConfigPath"
    exit
}

if (!(Test-Path -Path $dirConfigPath)) {
    Write-Host "Directory config file not found: $dirConfigPath"
    exit
}

$dbConfig = Get-Content -Path $dbConfigPath | ConvertFrom-Json
$dirConfig = Get-Content -Path $dirConfigPath | ConvertFrom-Json

# Extract configurations
$serverName = $dbConfig.ServerName
$databaseName = $dbConfig.DatabaseName
$userName = $dbConfig.UserName
$password = $dbConfig.Password
$backupFolder = $dirConfig.BackupFolder
$logFolder = $dirConfig.LogFolder 

# Ensure the backup and log directories exist
if (!(Test-Path -Path $backupFolder)) {
    New-Item -Path $backupFolder -ItemType Directory -Force
}

if (!(Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

# Define the backup file and log file paths
$backupFile = "$backupFolder\$databaseName_$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
$logFile = "$logFolder\backup_$(Get-Date -Format 'yyyyMMdd').log"

# Define SQL Server connection string
$connectionString = "Server=$serverName;Database=$databaseName;User ID=$userName;Password=$password;TrustServerCertificate=True;MultipleActiveResultSets=True;"

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
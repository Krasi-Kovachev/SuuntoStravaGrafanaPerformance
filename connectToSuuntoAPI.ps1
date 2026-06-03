# --- 1. Configuration & Credentials ---
# In production, pull these from $env:VARIABLES or Azure Key Vault
$SuuntoAccessToken = $env:SUUNTO_ACCESS_TOKEN
$SuuntoSubscriptionKey = $env:SUUNTO_SUBSCRIPTION_KEY
$SuuntoApiUrl = "https://cloudapi.suunto.com/v2/activities"

$DbHost = $env:PG_HOST
$DbName = $env:PG_DB
$DbUser = $env:PG_USER
$DbPass = $env:PG_PASS

# Import the SQL module
Import-Module SimplySql

function Get-SuuntoActivities {
    Write-Host "Connecting to Suunto API..."
    
    $Headers = @{
        "Authorization" = "Bearer $SuuntoAccessToken"
        "Ocp-Apim-Subscription-Key" = $SuuntoSubscriptionKey
    }

    try {
        # Invoke-RestMethod automatically parses JSON into PowerShell Objects
        $Response = Invoke-RestMethod -Uri $SuuntoApiUrl -Headers $Headers -Method Get
        return $Response
    } catch {
        Write-Error "Failed to fetch data from Suunto: $_"
        return $null
    }
}

function Write-ActivitiesToDb {
    param (
        [Parameter(Mandatory=$true)]
        $Activities
    )

    if (-not $Activities) {
        Write-Host "No activities to insert."
        return
    }

    Write-Host "Connecting to PostgreSQL..."
    $ConnString = "Server=$DbHost;Database=$DbName;User Id=$DbUser;Password=$DbPass;"

    try {
        # Open connection to Postgres
        Open-SqlConnection -ConnectionProvider PostgreSQL -ConnectionString $ConnString
        
        # Create Table (if it doesn't exist)
        $CreateQuery = @"
            CREATE TABLE IF NOT EXISTS suunto_activities (
                activity_id VARCHAR(100) PRIMARY KEY,
                start_time TIMESTAMP,
                activity_type VARCHAR(50),
                duration_seconds REAL,
                distance_meters REAL,
                raw_data JSONB
            );
"@
        Invoke-SqlQuery -Query $CreateQuery

        Write-Host "Writing data to PostgreSQL..."
        $Count = 0

        # Process and insert each activity
        foreach ($Activity in $Activities) {
            # Map the properties (adjust property names based on actual Suunto JSON structure)
            $ActivityId  = $Activity.activityId
            $StartTime   = $Activity.startTime
            $ActivityType = $Activity.activityType
            $Duration    = if ($Activity.duration) { $Activity.duration } else { 0 }
            $Distance    = if ($Activity.distance) { $Activity.distance } else { 0 }
            
            # Convert the PowerShell Custom Object back into a raw JSON string for the JSONB column
            $RawJson = $Activity | ConvertTo-Json -Depth 10 -Compress
            
            $InsertQuery = @"
                INSERT INTO suunto_activities 
                (activity_id, start_time, activity_type, duration_seconds, distance_meters, raw_data)
                VALUES (@Id, @Start, @Type, @Dur, @Dist, CAST(@Raw AS jsonb))
                ON CONFLICT (activity_id) DO UPDATE SET
                start_time = EXCLUDED.start_time,
                duration_seconds = EXCLUDED.duration_seconds,
                distance_meters = EXCLUDED.distance_meters,
                raw_data = EXCLUDED.raw_data;
"@
            # Bind parameters safely to prevent SQL injection
            $Parameters = @{
                "Id"    = [string]$ActivityId
                "Start" = [datetime]$StartTime
                "Type"  = [string]$ActivityType
                "Dur"   = [single]$Duration
                "Dist"  = [single]$Distance
                "Raw"   = [string]$RawJson
            }

            Invoke-SqlQuery -Query $InsertQuery -Parameters $Parameters
            $Count++
        }
        
        Write-Host "Successfully processed and saved $Count activities."

    } catch {
        Write-Error "Database error: $_"
    } finally {
        # Ensure the connection is always closed, even if the script fails
        Close-SqlConnection
    }
}

# --- Main Execution ---
$WorkoutData = Get-SuuntoActivities
if ($WorkoutData) {
    Write-ActivitiesToDb -Activities $WorkoutData
}
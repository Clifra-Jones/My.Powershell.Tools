function ConvertTo-LocalTime() {
    param( 
        [parameter(Mandatory=$true)]
        [Datetime]$DateTime 
    )
    $tz = Get-TimeZone
    $result = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($DateTime, $tz.StandardName)
    return $result
}

function ConvertFrom-LocalTime() {
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [DateTime]$DateTime,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = "Name"
        )]
        [String]$StandardName,
        [Parameter(
            Mandatory =$true,
            ParameterSetName = "tz"
        )]
        [TieZoneInfo]$Tz
    )
    if ($StandardName) {
        $Tz = Get-TimeZone -Name $StandardName
    }

    $result = [System.TimeZoneInfo]::ConvertTime($datetime, $Tz)
    return $result
}

function ConvertFrom-UTC() {
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [datetime]$DateTime
    )
    $tz = Get-TimeZone
    $result = [System.TimeZoneInfo]::ConvertTimeFromUtc($Datetime, $tz)
    return $result
}

function ConvertTo-UTC() {
    Param(
        [Parameter(
            Mandatory = $true
        )]
        [DateTime]$time
    )
    $tz = Get-TimeZone
    $result = [System.TimeZoneInfo]::ConvertTimeToUtc($datetime, $tz)
    return $result
}

function Invoke-PSNotification {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Position=0, Mandatory, ValueFromPipeline)]
        [string]
        $Body,

        [string]
        $Summary = 'PowerShell Notification',

        [ValidateSet('Low', 'Normal', 'Critical')]
        [string]
        $Urgency,

        [int]
        $ExpireTime,

        [string[]]
        $Icon,

        [ValidateSet(
            "device","device.added","device.error","device.removed",
            "email","email.arrived","email.bounced", 
            "im","im.error","im.received",
            "network","network.connected","network.disconnected","network.error",
            "presence","presence.offline","presence.online",
            "transfer","transfer.complete","transfer.error" )]
        [string[]]
        $Category
    )
    begin {
        $notifySendArgs = [System.Collections.Generic.List[psobject]]@()

        if ($Urgency) {
            $notifySendArgs.Add("--urgency=$Urgency")
        }

        if ($ExpireTime) {
            $notifySendArgs.Add("--expire-time=$ExpireTime")
        }

        if ($Icon) {
            $notifySendArgs.Add("--icon=$($Icon -join ',')")
        }

        if ($Catagory) {
            $notifySendArgs.Add("--category=$($Category -join ',')")
        }

        $notifySendArgs.Add($Summary)
        #$notifySendArgs.Add("")
    }

    process {
        $notifySendArgs.Add($Body)
        $_notifySendArgs = $notifySendArgs.ToArray()
        Start-Process -FilePath 'notify-send' -NoNewWindow -Wait -ArgumentList $_notifySendArgs        
    }

    end {}
}

function Write-Log() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$logFolder,
        [Parameter(Mandatory = $true)]
        [String]$logFileName,
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [int]$rotatePeriod = 0 # in days, 0 = rotate every day
    )
    # Get most recent log file.
    $lastLog = (Get-ChildItem -Path $logFolder -File).Where({$_Name -Like "$logFileName*"}) | Sort-Object LastWriteTime | Select-Object -Last 1
    $today = Get-Date
    If ($lastLog.LastWriteTime.AddDays($rotatePeriod) -lt $today) {
        $logDate = Get-Date -Format "yyyyMMdd"
        $LogFileName = "{0}/{1}{2}.log" -f $logFolder, $logFileName, $logDate
    } else {
        $logFileName = $lastLog.Name
    }
    $DateTime = get-date -Format "yyyy-MM-dd HH:mm"
    $msg = "{0} -- {1}" -f $DateTime, $Message
    Add-Content -Path $logFile -Value $Msg
}

function Invoke-LogFileCleanup() {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$logFolder,
        [Parameter(Mandatory = $true)]
        [String]$logFileName,
        [int]$CleanupPeriod = 10 # in days
    )

    [datetime]$cleanupDate = (Get-Date).AddDays($CleanupPeriod * -1).ToShortDateString()
    $logFileSpec = "{0}/{1}*.log" -f $logFolder, $logFileName

    $logFiles = (Get-ChildItem -Path $logFileSpec).Where({$_.LastWriteTime -lt $cleanupDate})
    $logFiles | ForEach-Object {
        Remove-Item -Path $_.FullName -Force
    }
}
$ORG = "Test"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$url = "https://config.zscaler.com/api/zscaler.net/hubs/cidr/json/recommended"

$downloadFolder = "$scriptDir\download"
$backupFolder = "$scriptDir\backup"
$zscalerFile = Join-Path $downloadFolder "zscaler_ipv4.json"

$sfFile = "force-app/main/default/settings/Security.settings-meta.xml"

# Ensure folders exist
foreach ($folder in @($downloadFolder, $backupFolder)) {
    if (!(Test-Path $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
}

# Convert IPv4 CIDR to start/end range
function Convert-CIDRToRange {
    param($cidr)

    # Validate IPv4 CIDR
    if ($cidr -notmatch '^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$') { return $null }

    $ip,$prefix = $cidr.Split("/")
    $prefix = [int]$prefix

    $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    [array]::Reverse($ipBytes)
    $ipInt = [BitConverter]::ToUInt32($ipBytes,0)

    $mask = ([uint32]::MaxValue) -shl (32 - $prefix)
    $network = $ipInt -band $mask
    $broadcast = $network + ((1 -shl (32 - $prefix)) - 1)

    $startBytes = [BitConverter]::GetBytes([uint32]$network)
    $endBytes = [BitConverter]::GetBytes([uint32]$broadcast)
    [array]::Reverse($startBytes)
    [array]::Reverse($endBytes)

    return @{start=([System.Net.IPAddress]::new($startBytes)).ToString(); end=([System.Net.IPAddress]::new($endBytes)).ToString(); cidr=$cidr}
}

try {
    Write-Host "Downloading Zscaler CIDRs..."
    $response = Invoke-RestMethod -Uri $url

    if (!$response) { throw "Download failed or empty response" }

    # Filter only IPv4
    $ipv4Cidrs = $response.hubPrefixes | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}/\d{1,2}$' }
    Write-Host "IPv4 CIDRs found:" $ipv4Cidrs.Count

    # Save JSON file
    $ipv4Cidrs | ConvertTo-Json | Set-Content -Path $zscalerFile

    # Retrieve Salesforce security settings
    Write-Host "Retrieving Salesforce Security Settings..." -ForegroundColor Cyan
    sf project retrieve start -m Settings:Security -o $ORG
    if ($LASTEXITCODE -ne 0) { throw "Salesforce retrieve failed" }

    # Backup XML file
    if (!(Test-Path $sfFile)) { throw "Salesforce XML file not found: $sfFile" }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupFolder "$($sfFile.Split('/')[-1]).$timestamp.bak"
    Copy-Item $sfFile $backupFile -Force
    Write-Host "Backup created: $backupFile" -ForegroundColor Green

    # Load XML
    $content = Get-Content $sfFile -Raw    
    $newRanges = ""

    # Loop over IPv4 CIDRs
    foreach ($cidr in $ipv4Cidrs) {
        $range = Convert-CIDRToRange $cidr
        if (-not $range) { continue }

        $start = $range.start
        $end = $range.end

        if ($content.Contains($start) -and $content.Contains($end)) {
            Write-Host "Skipping duplicate range $start - $end"
            continue
        }

        $newRanges += @"
        <ipRanges>
            <start>$start</start>
            <end>$end</end>
        </ipRanges>
"@
    }

    # Update XML
    if ($newRanges -ne "") {
        if ($content -match "<networkAccess\s*/>") {
            $content = $content -replace "<networkAccess\s*/>", "<networkAccess>`n$newRanges</networkAccess>"
        }
        elseif ($content -match "</networkAccess>") {
            $content = $content -replace "</networkAccess>", "$newRanges</networkAccess>"
        }
        else { throw "No <networkAccess> tag found in XML" }

        Set-Content $sfFile $content
        Write-Host "New IP ranges added successfully" -ForegroundColor Green
    }
    else {
        Write-Host "No new IP ranges required" -ForegroundColor Yellow
    }

    Write-Host "STEP 6 : Deploying Security Settings"    
    sf project deploy start --source-dir $sfFile --target-org $ORG

    if ($LASTEXITCODE -ne 0) {
        throw "Deployment failed"
    }
    else {
        Write-Host "Deployment successful" -ForegroundColor Green
    }

}
catch {
    Write-Host "Script failed: $_" -ForegroundColor Red
}
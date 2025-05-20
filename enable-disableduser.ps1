function Disable-EntraUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][String] $UPN
    )
    process {
        $aadUser = "AzureAD\$UPN"

        # STEP 2: Get SID of the AzureAD user
        try {
            $sid = (New-Object System.Security.Principal.NTAccount($aadUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
            Write-Host "User SID is: $sid"
        } catch { 
            Write-Error "Could not resolve SID for $aadUser"
            exit
        }

        # STEP 3: Export current security policy
        $infPath = "$env:TEMP\secpol.inf"
        $seceditDbPath = "$env:TEMP\secedit.sdb"
        secedit /export /cfg $infPath /areas USER_RIGHTS

        # STEP 4: Load and modify INF to remove the SID
        $inf = Get-Content $infPath
        $policyLine = "SeDenyInteractiveLogonRight"

        for ($i = 0; $i -lt $inf.Count; $i++) { 
            if ($inf[$i] -match "^$policyLine\s*=") { 
                $currentValue = $inf[$i] -replace "$policyLine\s*=\s*", ""
                $updatedSIDs = $currentValue.Split(',') | Where-Object { $_ -ne $sid }
                if ($updatedSIDs.Count -eq 0) {
                    $inf = $inf[0..($i - 1)] + $inf[($i + 1)..($inf.Count - 1)]
                } else { 
                    $inf[$i] = "$policyLine = " + ($updatedSIDs -join ",")
                } 
                break
            }
        }

        # STEP 5: Save and apply updated policy
        $inf | Set-Content $infPath -Encoding Unicode
        secedit /configure /db $seceditDbPath /cfg $infPath /areas USER_RIGHTS /quiet

        # Cleanup
        Remove-Item $infPath -Force
        Remove-Item $seceditDbPath -Force

        Write-Host "Removed $UPN from Deny logon locally"
    }
} 

if ($args.Length -lt 1) {
    Write-Error "Please supply a user's UPN as an argument."
} else {
    Disable-EntraUser -UPN $args[0]
}
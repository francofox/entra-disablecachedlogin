function Disable-User {
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

        # STEP 4: Update the INF file
        $inf = Get-Content $infPath
        $policyLine = "SeDenyInteractiveLogonRight"
        $policySet = $false

        for ($i = 0; $i -lt $inf.Count; $i++) {
            if ($inf[$i] -match "^$policyLine\s*=") {
                if ($inf[$i] -notmatch $sid) {
                    $inf[$i] += ",$sid"
                } 
                $policySet = $true
                break
            }
        }

        if (-not $policySet) {
            $privIndex = $inf.IndexOf("[Privilege Rights]")
            if ($privIndex -ge 0) {
                $inf = $inf[0..$privIndex] + "$policyLine = $sid" + $inf[($privIndex + 1)..($inf.Count - 1)]
            } else {
                $inf += "[Privilege Rights]"
                $inf += "$policyLine = $sid"
            }
        }

        # STEP 5: Save and apply the modified INF
        $inf | Set-Content $infPath -Encoding Unicode
        secedit /configure /db $seceditDbPath /cfg $infPath /areas USER_RIGHTS /quiet

        # Cleanup
        Remove-Item $infPath -Force
        Remove-Item $seceditDbPath -Force

        Write-Host "Deny logon policy applied to $UPN"
    }
}

if ($args.Length -lt 1) {
    Write-Host "Please supply a UPN to disable."
} else {
    Disable-User -UPN $args[0]
}
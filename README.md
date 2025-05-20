# EntraID Disable Cached Login 
Powershell script to disable login using cached credentials on Entra-joined devices for a specific user's UPN

## When is this useful?
EntraID-joined devices auto-cache login credentials, even after a user has been disabled in EntraID. It also caches the password, which means that, even if you reset the password in Entra and then disable the account, the user will still be able to log into their computer using their previous password. 

What this means is that users are able to continue using their computers and logging in even after termination, potentially putting company data and IT resources at risk. 

## Why this script?
Most of the previous ways of disabling accounts no longer function with Entra-joined computers. This is the only way I have found that truly works. 

I have provided multiple versions of this script to fit different needs.
* `modifiable` files are the script, uncondensed, with a `$userUPN` field to be modified
* `twoliner` files are the same as the `modifiable` but formatted as a two-liner, with the first line being defining the UPN of the user to disable/enable.
* `disable-user.ps1` and `enable-disableduser.ps1` are standalone scripts that take the UPN as an argument.
* `entra-disableenableuser.psm1` is a module which can be imported with the `Enable-EntraUser` and `Disable-EntraUser` Cmdlets contained inside it. Both take the -UPN parameter. 

This file should be run on the machine from an admin user. This can be run from an RMM software, or any other software which gives you a remote shell on the machine. I have provided the twoliner versions for cases where you need to act fast manually and it is easiest just to copy-paste a line or two of code into a shell.
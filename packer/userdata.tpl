<powershell>
function Register-NativeMethod
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string]$dll,
 
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [string]$methodSignature
    )
 
    $script:nativeMethods += [PSCustomObject]@{ Dll = $dll; Signature = $methodSignature; }
}

function Add-NativeMethods
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param($typeName = 'NativeMethods')
 
    $nativeMethodsCode = $script:nativeMethods | ForEach-Object { "
        [DllImport(`"$($_.Dll)`")]
        public static extern $($_.Signature);
    " }
 
    Add-Type @"
        using System;
        using System.Text;
        using System.Runtime.InteropServices;
        public static class $typeName {
            $nativeMethodsCode
        }
"@
}

function CreateUserProfile
{
    Param(
        [string]$UserName
    )

    $methodName = 'UserEnvCP'
    $script:nativeMethods = @();

    Register-NativeMethod "userenv.dll" "int CreateProfile([MarshalAs(UnmanagedType.LPWStr)] string pszUserSid,`
    [MarshalAs(UnmanagedType.LPWStr)] string pszUserName,`
    [Out][MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszProfilePath, uint cchProfilePath)";

    Add-NativeMethods -typeName $MethodName;

    $localUser = New-Object System.Security.Principal.NTAccount("$UserName");
    $userSID = $localUser.Translate([System.Security.Principal.SecurityIdentifier]);
    $sb = new-object System.Text.StringBuilder(260);
    $pathLen = $sb.Capacity;

    try
    {
        [UserEnvCP]::CreateProfile($userSID.Value, $Username, $sb, $pathLen) | Out-Null;
    }
    catch
    {
        Write-Error $_.Exception.Message;
        break;
    }
}

Set-Service -Name AmazonSSMAgent -StartupType 'Automatic'
Restart-Service AmazonSSMAgent

net user Administrator /active:yes
wmic useraccount where "name='Administrator'" set PasswordExpires=FALSE

# Install the OpenSSH Client
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
# Install the OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

#Register Administrator SSH Public key
if ( -not (Test-Path -Path "C:\ProgramData\ssh")) {
    mkdir C:\ProgramData\ssh\
} 
$PubKey = "${admin_key}"
$PubKey | Out-File -Encoding Ascii -Append C:\ProgramData\ssh\administrators_authorized_keys
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /remove:g "Authenticated Users"

# Create Normal User and Register SSH Public Key
$UserName = "${user_name}" 
$GroupName = "Users"
New-LocalUser -Name $UserName -NoPassword 
Add-LocalGroupMember -Group $GroupName -Member $UserName
CreateUserProfile $UserName
if ( -not (Test-Path -Path "C:\Users\$UserName\.ssh")) {
    mkdir C:\Users\$UserName\.ssh
}
$PubKeyUserA = "${user_key}" 
$PubKeyUserA | Out-File -Encoding Ascii -Append C:\Users\$UserName\.ssh\authorized_keys 

Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

#Disable PasswordAuthentication
(Get-Content -Encoding Ascii  $env:programdata\ssh\sshd_config) | foreach { $_ -replace "#PasswordAuthentication yes","PasswordAuthentication no" } | Set-Content $env:programdata\ssh\sshd_config
Restart-Service sshd 

# Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
}

</powershell>

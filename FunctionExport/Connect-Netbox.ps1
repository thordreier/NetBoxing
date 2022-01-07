function Connect-Netbox
{
    <#
        .SYNOPSIS
            Connect to NetBox

        .DESCRIPTION
            Connect to Netbox.
            Or that is, tell the PowerShell module URI and token - so the other functions in the module know what to connect to.
            This function doesn't actually connect to anything.

        .PARAMETER Uri
            Uri. Eg. https://netbox.yourdomain.tld

        .PARAMETER Token
            API token created in NetBox

        .EXAMPLE
            Connect-Netbox -Uri https://netbox.yourdomain.tld -Token abcabcabc
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,

        [Parameter(Mandatory = $true)]
        [String]
        $Token
    )

    $origErrorActionPreference = $ErrorActionPreference

    try
    {
        $ErrorActionPreference = 'Stop'

        $script:baseUri = $Uri -replace '/$'
        $script:apiToken = $Token
    }
    catch
    {
        $msg = $_.ToString() + "`r`n" + $_.InvocationInfo.PositionMessage.ToString()
        Write-Verbose -Message "Encountered an error: $msg"
        Write-Error -ErrorAction $origErrorActionPreference -Message $msg
    }
}

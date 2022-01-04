function Connect-Netbox
{
    <#
        .SYNOPSIS
            xxx

        .DESCRIPTION
            xxx
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

        $script:baseUri = $Uri
        $script:apiToken = $Token
    }
    catch
    {
        $msg = $_.ToString() + "`r`n" + $_.InvocationInfo.PositionMessage.ToString()
        Write-Verbose -Message "Encountered an error: $msg"
        Write-Error -ErrorAction $origErrorActionPreference -Message $msg
    }
}

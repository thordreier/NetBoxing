function Invoke-NetboxPatch
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
        [Parameter()]
        [string]
        $Uri,
        
        [Parameter(Mandatory = $true)]
        [PSObject]
        $Orig,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Changes,
        
        [Parameter()]
        [switch]
        $NoUpdate,
        
        [Parameter()]
        [switch]
        $Wait
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = $PSBoundParameters.ContainsKey('Verbose') -or ($VerbosePreference -ne 'SilentlyContinue')
    }

    process
    {
        Write-Verbose -Message "Process begin (ErrorActionPreference: $ErrorActionPreference)"

        try
        {
            # Make sure that we don't continue on error, and that we catches the error
            $ErrorActionPreference = 'Stop'

            if (-not $Uri)
            {
                $Uri = $Orig.url
            }
            if (-not $Uri)
            {
                throw 'Cannot find URI for Netbox object'
            }

            $body = ChangesOnly -Orig $Orig -Changes $Changes

            if ($body.Count)
            {
                if ($NoUpdate)
                {
                    Write-Warning -Message "Skipping changes on $Uri"
                    Write-Warning -Message ($body | ConvertTo-Json -Depth 9)
                }
                else
                {
                    Invoke-NetboxRequest -Uri $Uri -FullResponse -Method Patch -Body $body
                    if ($Wait)
                    {
                        Read-Host -Prompt 'Press enter to continue'
                    }
                }
            }
        }
        catch
        {
            Write-Verbose -Message "Encountered an error: $_"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception
        }
        finally
        {
            $ErrorActionPreference = $origErrorActionPreference
        }

        Write-Verbose -Message 'Process end'
    }

    end
    {
        Write-Verbose -Message 'End'
    }
}

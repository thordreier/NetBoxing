function Invoke-NetboxPatch
{
    <#
        .SYNOPSIS
            Patch object in Netbox

        .DESCRIPTION
            Patch object in Netbox

        .PARAMETER Uri
            Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")

        .PARAMETER Item
            Original unpatched object

        .PARAMETER Changes
            Hashtable with changes to be made to object

        .PARAMETER NoUpdate
            Don't update object, only show what would be sent to server (as a warning)

        .PARAMETER Wait
            After patch is sent to NetBox, wait with a "Press enter to continue" prompt

        .EXAMPLE
            Invoke-NetboxPatch -Uri tenancy/tenants/3/ -Changes @{description = 'example'}
            Patch tenant 3 with description.
            This is always sent to Netbox, even if description hasn't changes.
            The function doesn't know the previous state of the properties.

        .EXAMPLE
            $v = Invoke-NetboxRequest ipam/vlans/1/ ; Invoke-NetboxPatch -Item $v -Changes @{description = 'example'}
            Fetch VLAN object with id 1 and change description.
            If description is already correct, then a patch request isn't sent to Netbox.
            Old versions of Netbox didn't have an "url" property in objects. If that's the case, then this should be added:
             -Uri "ipam/vlans/$($v.id)/"
    #>

    [CmdletBinding()]
    param
    (
        [Parameter()]
        [string]
        $Uri,
        
        [Parameter()]
        [PSObject]
        $Item,
        
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
                $Uri = $Item.url
            }
            if (-not $Uri)
            {
                throw 'Cannot find URI for Netbox object'
            }

            $body = ChangesOnly -Item $Item -Changes $Changes

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

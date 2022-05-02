function Invoke-NetboxUpsert
{
    <#
        .SYNOPSIS
            Update (patch) or create NetBox object

        .DESCRIPTION
            Update (patch) or create NetBox object
            If existing object is found

        .PARAMETER Uri
            Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")

        .PARAMETER Properties
            Properties that should be set when updating or creating object

        .PARAMETER PropertiesNew
            Properties that should only be set when creating object - not when updating

        .PARAMETER FindBy
            Which properties should be used to find existing object

        .PARAMETER Item
            Existing NetBox object can be passed (normally not used).

        .PARAMETER Multi
            Changes to multiple objects is allowed.
            Normally only changes to one object is allowed.
            If this is set, no new objects will be created, only existing will be updated.

        .PARAMETER NoCreate
            Don't create object, only show what would be sent to server (as a warning)

        .PARAMETER NoUpdate
            Don't update object, only show what would be sent to server (as a warning)

        .PARAMETER Wait
            After post/patch is sent to NetBox, wait with a "Press enter to continue" prompt

        .EXAMPLE
            Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'prefix' -Properties @{prefix='10.0.0.0/30'; description='example'}
            If prefix 10.0.0.0/30 already exist, then set description. If it doesn't exist, then create it.

        .EXAMPLE
            Invoke-NetboxUpsert -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan=@{vid=3999}; description='example'} -Multi -NoUpdate
            Find all prefixes attached to VLAN 3999 and show which changes that should be made (as warning).
            Remove -NoUpdate to send patch requests to NetBox
    #>

    [CmdletBinding(DefaultParameterSetName='Findby')]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Properties,
        
        [Parameter()]
        [hashtable]
        $PropertiesNew = @{},
        
        [Parameter(Mandatory = $true, ParameterSetName  = 'Findby')]
        [string[]]
        $FindBy,

        [Parameter(Mandatory = $true, ParameterSetName = 'Item')]
        [PSObject[]]
        $Item,
        
        [Parameter()]
        [switch]
        $Multi,

        [Parameter()]
        [switch]
        $NoCreate,
        
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

            if ($Item -or ($Item = @(Find-NetboxObject -Uri $Uri -Properties $Properties -FindBy $FindBy)))
            {
                if ($Item.Count -eq 1 -or $Multi)
                {
                    foreach ($itemObj in $Item)
                    {
                        if (-not ($itemUri = $itemObj.url))
                        {
                            if (-not $itemObj.id) {throw 'No ID found on NetBox object'}
                            $itemUri = '{0}{1}/' -f $Uri, $itemObj.id
                        }
                        if ($updatedItem = Invoke-NetboxPatch -Uri $itemUri -Item $itemObj -Changes $Properties -NoUpdate:$NoUpdate -Wait:$Wait)
                        {
                            $updatedItem
                        }
                        else
                        {
                            $itemObj
                        }
                    }
                }
                else
                {
                    throw "$($findUri) matched more than one item - matched $($Item.Count)"
                }
            }
            elseif (-not $Multi)
            {
                $body = ChangesOnly -Item @{} -Changes ($Properties + $PropertiesNew)
                if ($NoCreate)
                {
                    Write-Warning -Message "Not creating $Uri"
                    Write-Warning -Message ($body | ConvertTo-Json -Depth 9)
                }
                else
                {
                    Invoke-NetboxRequest -Uri $Uri -Method Post -FullResponse -Body $body
                    if ($Wait)
                    {
                        Read-Host -Prompt 'Press enter to continue'
                    }
                }
            }
            else
            {
                Write-Verbose -Message 'Multi=true, but zero objects found'
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

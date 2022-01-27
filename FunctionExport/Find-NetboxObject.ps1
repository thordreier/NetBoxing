function Find-NetboxObject
{
    <#
        .SYNOPSIS
            Find object(s) in NetBox

        .DESCRIPTION
            Find object(s) in NetBox

        .PARAMETER Uri
            Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")

        .PARAMETER Properties
            Hashtable with properties

        .PARAMETER FindBy
            Which properties should be used to find object

        .EXAMPLE
            Find-NetboxObject -Uri ipam/prefixes/ -Properties @{vlan = @{vid = 3999}}
            Find all prefixes attaced to VLAN 3999.

        .EXAMPLE
            Find-NetboxObject -Uri ipam/prefixes/ -FindBy 'vlan.vid' -Properties @{vlan = @{vid = 3999}; otherproperty='foobar'}
            Find all prefixes attaced to VLAN 3999. "otherproperty" is ignored in search.

        .EXAMPLE
            Find-NetboxObject ipam/vlans/ -Properties @{group=@{slug='test'}} -FindBy 'group=group.slug'
            Find all VLANs belonging to VLAN group "test".
            Sometimes the NetBox API want queries "different". It's not "?group_slug=test" but "?group=test"
            If the "Findby" is omitted in this example, then NetBox will return all VLAN objects back, and the filtering will be done only on client side.
            Stuff like "Got 18 objects back from server and returned 2" can be seen in verbose output.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Uri,
        
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Properties,
        
        [Parameter()]
        [string[]]
        $FindBy
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

            if (-not $FindBy)
            {
                $FindBy = (FlattenHash -Hash $Properties).Keys
            }

            $queryProperties = @{}
            $queryData = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            foreach ($f in $Findby)
            {
                $key = $f -replace '^custom_fields.','cf.' -replace '\.','_'
                if (($a, $b = $f -split '=') -and $b) {
                    $f   = $b
                    $key = $a
                }

                # Is it insecure? Yes! Is it quick and dirty? Yes! Does it do the job? Yes!
                $val = .([scriptblock]::Create("`$Properties.$f"))
                AddToHash -Hash $queryProperties -Key ($f -split '\.') -Value $val
                $queryData.Add($key, $val)
            }
            $findUri = '{0}?{1}' -f $uri, $queryData.ToString()

            # Return (sometimes we risk getting more data back from Netbox than we wanted - that's why we also check locally)
            $cAll = $cReturned = 0
            Invoke-NetboxRequest -Uri $findUri -Follow | Where-Object -FilterScript {
                ++$cAll
                -not (ChangesOnly -Orig $_ -Changes $queryProperties).Count -and ++$cReturned
            }
            Write-Verbose -Message "Got $cAll objects back from server and returned $cReturned"
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

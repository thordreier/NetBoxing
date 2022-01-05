function Find-NetboxObject
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
        [hashtable]
        $Properties,
        
        [Parameter(Mandatory = $true)]
        [array]
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
            Invoke-NetboxRequest -Uri $findUri -Follow | Where-Object -FilterScript {
                -not (ChangesOnly -Orig $_ -Changes $queryProperties).Count
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

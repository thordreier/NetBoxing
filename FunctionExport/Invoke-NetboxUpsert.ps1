function Invoke-NetboxUpsert
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
        
        [Parameter()]
        [hashtable]
        $PropertiesNew = @{},
        
        [Parameter(Mandatory = $true)]
        [array]
        $FindBy,
        
        [Parameter()]
        [switch]
        $NoCreate,
        
        [Parameter()]
        [switch]
        $NoUpdate
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

            $queryData = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
            foreach ($f in $Findby)
            {
                $key = $f -replace '\.','_'
                if (($a, $b = $f -split '=') -and $b) {
                    $f   = $b
                    $key = $a
                }

                # Is it insecure? Yes! Is it quick and dirty? Yes! Does it do the job? Yes!
                $val = .([scriptblock]::Create("`$Properties.$f"))
                $queryData.Add($key, $val)
            }
            $findUri = '{0}?{1}' -f $uri, $queryData.ToString()

            if ($item = @(Invoke-NetboxRequest -Uri $findUri))
            {
                if ($item.Count -eq 1)
                {
                    $item = $item[0]
                    if (-not ($itemUri = $item.url))
                    {
                        $itemUri = '{0}{1}/' -f $Uri, $item.id
                    }
                    if ($updatedItem = Invoke-NetboxPatch -Uri $itemUri -Orig $item -Changes $Properties -NoUpdate:$NoUpdate)
                    {
                        $updatedItem
                    }
                    else
                    {
                        $item
                    }
                }
                else
                {
                    throw "$($findUri) matched more than one item - matched $($item.Count)"
                }
            }
            else
            {
                if ($NoCreate)
                {
                    Write-Warning -Message "Not creating $Uri"
                    Write-Warning -Message (($Properties + $PropertiesNew) | ConvertTo-Json -Depth 9)
                }
                else
                {
                    Invoke-NetboxRequest -Uri $Uri -Method Post -FullResponse -Body ($Properties + $PropertiesNew)
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

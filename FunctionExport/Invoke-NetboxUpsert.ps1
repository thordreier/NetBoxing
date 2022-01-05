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
        $Multi,

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

            if ($items = @(Find-NetboxObject -Uri $Uri -Properties $Properties -FindBy $FindBy))
            {
                if ($items.Count -eq 1 -or $Multi)
                {
                    foreach ($item in $items)
                    {
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
                }
                else
                {
                    throw "$($findUri) matched more than one item - matched $($items.Count)"
                }
            }
            elseif (-not $Multi)
            {
                $body = ChangesOnly -Orig @{} -Changes ($Properties + $PropertiesNew)
                if ($NoCreate)
                {
                    Write-Warning -Message "Not creating $Uri"
                    Write-Warning -Message ($body | ConvertTo-Json -Depth 9)
                }
                else
                {
                    Invoke-NetboxRequest -Uri $Uri -Method Post -FullResponse -Body $body
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

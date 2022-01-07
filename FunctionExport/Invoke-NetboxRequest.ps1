function Invoke-NetboxRequest
{
    <#
        .SYNOPSIS
            Send HTTP request to NetBox

        .DESCRIPTION
            Send HTTP request to NetBox

        .PARAMETER Uri
            Either API part ("dcim/sites/") or full URI ("https://netbox.yourdomain.tld/api/dcim/sites/")

        .PARAMETER Method
            HTTP method
            Get, Post, ...

        .PARAMETER Body
            Object (or hashtable) that should be sent if Method is POST or PATCH

        .PARAMETER FullResponse
            Return the full object returned from Netbox - and not only the "relevant" part

        .PARAMETER Follow
            If result from NetBox contains more than 50 objects, then follow next-page links and get it all

        .EXAMPLE
            Invoke-NetboxRequest dcim/sites/ -Follow
            Fetch all sites from NetBox

        .EXAMPLE
            Invoke-NetboxRequest -Uri https://netbox.yourdomain.tld/api/dcim/sites/1/
            Fetch site with ID 1 from Netbox

        .EXAMPLE
            Invoke-NetboxRequest -Uri tenancy/tenants/ -Method Post -Body @{name='Example Tenant'; slug='example-tenant'}
            Create new tenant
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]
        $Uri,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method,

        [Parameter()]
        [PSObject]
        $Body,

        [Parameter()]
        [switch]
        $FullResponse,

        [Parameter()]
        [switch]
        $Follow
    )

    begin
    {
        Write-Verbose -Message "Begin (ErrorActionPreference: $ErrorActionPreference)"
        $origErrorActionPreference = $ErrorActionPreference
        $verbose = $PSBoundParameters.ContainsKey('Verbose') -or ($VerbosePreference -ne 'SilentlyContinue')
        $origSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol

        if (-not $script:baseUri -or -not $script:apiToken)
        {
            throw 'Please login with Connect-Netbox first'
        }
    }

    process
    {
        Write-Verbose -Message "Process begin (ErrorActionPreference: $ErrorActionPreference)"

        try
        {
            # Make sure that we don't continue on error, and that we catches the error
            $ErrorActionPreference = 'Stop'

            # Why isn't this default!?
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            $null = $PSBoundParameters.Remove('FullResponse')
            $null = $PSBoundParameters.Remove('Follow')
            $PSBoundParameters['Uri']             = $Uri
            $PSBoundParameters['Headers']         = @{Authorization = "Token $($script:apiToken)"}
            $PSBoundParameters['ContentType']     = 'application/json; charset=utf-8'
            $PSBoundParameters['UseBasicParsing'] = $true
            if ($Body)
            {
                $PSBoundParameters['Body'] = $Body | ConvertTo-Json -Depth 99
                Write-Verbose -Message $PSBoundParameters['Body']
            }
            if ($PSBoundParameters['Uri'] -notmatch '^http(s)?://')
            {
                $PSBoundParameters['Uri'] = "$($script:baseUri)/api/$($PSBoundParameters['Uri'] -replace '^/')"
            }

            do
            {
                # Server send UTF8 back but does not send info about it in header
                #$response = Invoke-RestMethod @PSBoundParameters
                'Sending request to {0}' -f $PSBoundParameters['Uri'] | Write-Verbose
                $resp = Invoke-WebRequest @PSBoundParameters
                $response = [system.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray()) | ConvertFrom-Json

                if ($FullResponse -or $response.results -isnot [array])
                {
                    $response
                }
                else
                {
                    $response.results
                }
            }
            while ($Follow -and ($PSBoundParameters['Uri'] = $response.next))
        }
        catch
        {
            # If error was encountered inside this function then stop doing more
            # But still respect the ErrorAction that comes when calling this function
            # And also return the line number where the original error occured
            $msg = $_.ToString() + "`r`n" + $_.InvocationInfo.PositionMessage.ToString()
            Write-Verbose -Message "Encountered an error: $msg"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception -Message $msg
        }
        finally
        {
            $ErrorActionPreference = $origErrorActionPreference
            [Net.ServicePointManager]::SecurityProtocol = $origSecurityProtocol
        }

        Write-Verbose -Message 'Process end'
    }

    end
    {
        Write-Verbose -Message 'End'
    }
}

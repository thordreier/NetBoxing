function Invoke-NetboxRequest
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
                $PSBoundParameters['Uri'] = "$($script:baseUri)/api/$($PSBoundParameters['Uri'])"
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
            Write-Verbose -Message "Encountered an error: $_"
            Write-Error -ErrorAction $origErrorActionPreference -Exception $_.Exception
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

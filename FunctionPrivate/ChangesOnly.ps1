function ChangesOnly ([PSObject] $Orig, [hashtable] $Changes)
{
    function NotIdentical ($Orig, $Changes)
    {
        ($Changes -is [hashtable] -and (ChangesOnly -Orig $Orig -Changes $Changes).Count) -or
        ($Changes -isnot [hashtable] -and $Orig -cne $Changes)
    }

    $expand = $null
    $Changes = $Changes.Clone()
    foreach ($key in @($Changes.Keys))
    {
        if ($key -ceq '___EXPAND')
        {
            $expand = $Changes.$key
            $null = $Changes.Remove($key)
        }
        elseif ($Changes.$key -is [hashtable])
        {
            if (-not ($Changes.$key = ChangesOnly -Orig $Orig.$key -Changes $Changes.$key).Count)
            {
                $Changes.Remove($key)
            }
        }
        elseif ($Changes.$key -is [array])
        {
            if ($Changes.$key.Count -and $Changes.$key[0] -is [hashtable] -and $Changes.$key[0].___APPEND)
            {
                $append, $Changes.$key = $Changes.$key
                if (($ok = $Orig.$key) -isnot [array])
                {
                    $ok = @()
                }
                $identical = $true
                $combined = @($ok | Select-Object -Property $append.___APPEND)
                foreach ($c in $Changes.$key)
                {
                    $exist = $false
                    foreach ($o in $ok)
                    {
                        if (-not (NotIdentical -Orig $o -Changes $c))
                        {
                            $exist = $true
                            break
                        }
                    }
                    if (-not $exist)
                    {
                        $combined += $c
                        $identical = $false
                    }
                }
                if ($identical)
                {
                    $Changes.Remove($key)
                }
                else
                {
                    $Changes.$key = $combined
                }
            }
            else
            {
                if ($Orig.$key -is [array] -and $Orig.$key.Count -eq $Changes.$key.Count)
                {
                    $identical = $true
                    for ($i=0; $i -lt $Changes.$key.Count; $i++)
                    {
                        if (NotIdentical -Orig $Orig.$key[$i] -Changes $Changes.$key[$i])
                        {
                            $identical = $false
                            break
                        }
                    }
                    if ($identical)
                    {
                        $Changes.Remove($key)
                    }
                }
                elseif ($Orig.$key -eq $null -and $Changes.$key.Count -eq 0)
                {
                    $Changes.Remove($key)
                }
            }
        }
        else
        {
            if ($Orig.$key -ceq $Changes.$key)
            {
                $null = $Changes.Remove($key)
            }
        }
    }
    if ($expand)
    {
        $Changes.$expand
    }
    else
    {
        $Changes
    }
}

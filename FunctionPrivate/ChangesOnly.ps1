function ChangesOnly ([PSObject] $Item, [hashtable] $Changes)
{
    function NotIdentical ($Item, $Changes)
    {
        ($Changes -is [hashtable] -and (ChangesOnly -Item $Item -Changes $Changes).Count) -or
        ($Changes -isnot [hashtable] -and $Item -cne $Changes)
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
            if (-not ($Changes.$key = ChangesOnly -Item $Item.$key -Changes $Changes.$key).Count)
            {
                $Changes.Remove($key)
            }
        }
        elseif ($Changes.$key -is [array])
        {
            if ($Changes.$key.Count -and $Changes.$key[0] -is [hashtable] -and $Changes.$key[0].___APPEND)
            {
                $append, $Changes.$key = $Changes.$key
                if (($ik = $Item.$key) -isnot [array])
                {
                    $ik = @()
                }
                $identical = $true
                $combined = @($ik | Select-Object -Property $append.___APPEND)
                foreach ($c in $Changes.$key)
                {
                    $exist = $false
                    foreach ($i in $ik)
                    {
                        if (-not (NotIdentical -Item $i -Changes $c))
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
                if ($Item.$key -is [array] -and $Item.$key.Count -eq $Changes.$key.Count)
                {
                    $identical = $true
                    for ($i=0; $i -lt $Changes.$key.Count; $i++)
                    {
                        if (NotIdentical -Item $Item.$key[$i] -Changes $Changes.$key[$i])
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
                elseif ($Item.$key -eq $null -and $Changes.$key.Count -eq 0)
                {
                    $Changes.Remove($key)
                }
            }
        }
        else
        {
            if ($Item.$key -ceq $Changes.$key)
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

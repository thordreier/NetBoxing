function ChangesOnly ([PSObject] $Orig, [hashtable] $Changes)
{
    $expand = $null
    @($Changes.Keys) | ForEach-Object -Process {
        if ($_ -ceq '___EXPAND')
        {
            $expand = $Changes.$_
            $null = $Changes.Remove($_)
        }
        elseif ($Changes.$_ -is [hashtable])
        {
            if (-not ($Changes.$_ = ChangesOnly -Orig $Orig.$_ -Changes $Changes.$_).Count)
            {
                $Changes.Remove($_)
            }
        }
        else
        {
            if ($Orig.$_ -ceq $Changes.$_)
            {
                $null = $Changes.Remove($_)
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

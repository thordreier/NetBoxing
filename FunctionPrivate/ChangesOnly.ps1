function ChangesOnly ([PSObject] $Orig, [hashtable] $Changes)
{
    @($Changes.Keys) | ForEach-Object -Process {
        if ($Changes.$_ -is [hashtable])
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
    $Changes
}

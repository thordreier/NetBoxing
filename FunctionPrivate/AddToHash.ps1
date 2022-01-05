function AddToHash ([hashtable] $Hash, [string[]] $Key, $Value)
{
    $k, $Key = $Key
    if ($Key)
    {
        if ($Hash[$K] -isnot [hashtable]) {$Hash[$K] = @{}}
        AddToHash -Hash $Hash[$K] -Key $Key -Value $Value
    }
    else
    {
        $Hash[$K] = $Value
    }
}

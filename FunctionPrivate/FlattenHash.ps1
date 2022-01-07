function FlattenHash ([hashtable] $Hash, [string] $Prefix)
{
    $return = @{}
    @($Hash.Keys) | ForEach-Object -Process {
        $n = if ($Prefix) {$Prefix + '.' + $_} else {$_}
        if ($Hash[$_] -is [hashtable])
        {
            $return += FlattenHash -Hash $Hash[$_] -Prefix $n
        }
        else
        {
            
            $return[$n] = $Hash[$_]
        }
    }
    $return
}

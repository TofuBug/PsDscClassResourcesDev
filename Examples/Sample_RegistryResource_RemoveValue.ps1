<#
    .SYNOPSIS
        Removes the registry key value MyValue from the key
        'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'.
#>
Configuration Sample_RegistryResource_RemoveValue
{
    Import-DscResource -ModuleName 'PsDscClassResourcesDev'

    Node localhost
    {
        Registry Registry1
        {
            Key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
            Ensure = 'Absent'
            ValueName = 'MyValue'
        }
    }
}

param
(
    [Parameter(Mandatory = $true)]
    [String]
    $ConfigurationName
)

Configuration $ConfigurationName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Key,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [String]
        [AllowEmptyString()]
        $ValueName
    )

    Import-DscResource -ModuleName 'PsDscClassResourcesDev'

    Node localhost
    {
        Registry Registry1
        {
            Key = $Key
            Ensure = $Ensure
            ValueName = $ValueName
            Force = $true
        }
    }
}

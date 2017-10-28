<#
    .SYNOPSIS
        Sets the Secure Socket Tunneling Protocol and DHCP Client services to run under the
        built-in account LocalService.
#>
Configuration ServiceSetBuiltInAccountExample
{
    Import-DscResource -ModuleName 'PsDscClassResources'

    ServiceSet ServiceSet1
    {
        Name           = @( 'SstpSvc', 'Dhcp'  )
        Ensure         = 'Present'
        BuiltInAccount = 'LocalService'
        State          = 'Ignore'
    }
}

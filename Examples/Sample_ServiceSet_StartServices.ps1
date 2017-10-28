<#
    .SYNOPSIS
        Ensures that the DHCP Client and Windows Firewall services are running.
#>
Configuration ServiceSetStartExample
{
    Import-DscResource -ModuleName 'PsDscClassResources'

    ServiceSet ServiceSet1
    {
        Name   = @( 'Dhcp', 'MpsSvc' )
        Ensure = 'Present'
        State  = 'Running'
    }
}

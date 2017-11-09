using namespace System.Management.Automation
using namespace Microsoft.PowerShell.Commands

<#
    .SYNOPSIS
        Sets up Class with Static Helper Methods and Properties
        (Replaces CommonResourceHelper.psm1's cmdlet based helper methods)
#>
class CRHelper 
{
    static [string] $UICulture = $PSUICulture
    static [bool] $IsNanoServer = [CRHelper]::Test_IsNanoServer([CRHelper]::Get_ComputerInfo())

    # Delegate hooks for unit testing
    #
    # To PROPERRLY test this class you MUST Assert that the Delegates you DO NOT override are null
    hidden static [Func[string,bool]] $TestCommandExistsFunc = $null
    hidden static [Func[ComputerInfo]] $GetComputerInfoFunc = $null
    hidden static [Func[ComputerInfo,bool]] $TestIsNanoServerFunc = $null
 
    <#
        .SYNOPSIS
            Helper Function to Reset Func Delegates to normal for testing
    #>
    hidden static [void] ResetFuncsToNormal()
    {
        [CRHelper]::TestCommandExistsFunc = $null
        [CRHelper]::GetComputerInfoFunc =   $null
        [CRHelper]::TestIsNanoServerFunc =  $null
    }

    <#
        .SYNOPSIS
            Tests if the current machine is a Nano server.
            Visible Method

        .PARAMETER computerInfo
            ComputerInfo Object
    #>
    static [bool] Test_IsNanoServer() 
    {
        return [CRHelper]::Test_IsNanoServer([CRHelper]::Get_ComputerInfo())
    }

    <#
        .SYNOPSIS
            Tests if the current machine is a Nano server.
            Hidden Method called by visible Method

        .PARAMETER computerInfo
            ComputerInfo Object
    #>
    hidden static [bool] Test_IsNanoServer([Microsoft.PowerShell.Commands.ComputerInfo] $computerInfo) 
    {
        if ($null -ne [CRHelper]::TestIsNanoServerFunc) 
        {
            return [CRHelper]::TestIsNanoServerFunc.Invoke($computerInfo)
        }
        return (
                    $null -ne $computerInfo -and 
                    $computerInfo.OsProductType -eq [Microsoft.PowerShell.Commands.ProductType]::Server -and
                    $computerInfo.OsServerLevel -eq [Microsoft.PowerShell.Commands.ServerLevel]::NanoServer
               )        
    }

    <#
        .SYNOPSIS
            Gets Computer Info broken out for unit testing and mocking.
    #>
    hidden static [Microsoft.PowerShell.Commands.ComputerInfo] Get_ComputerInfo()
    {
        # If we have an alternate Func call that instead (Allows for Unit Testing)
        if ($null -ne [CRHelper]::GetComputerInfoFunc) 
        {
            return [CRHelper]::GetComputerInfoFunc.Invoke()
        }
        $computerInfo = $null
        if ([CRHelper]::Test_CommandExists('Get-ComputerInfo'))
        {
            $computerInfo = Get-ComputerInfo -ErrorAction 'SilentlyContinue'    
        }
        return $computerInfo
    }

    <#
        .SYNOPSIS
            Tests whether or not the command with the specified name exists.
    
        .PARAMETER Name
            The name of the command to test for.
    #>
    static [bool] Test_CommandExists(
        [String] $Name
    ) 
    {
        # If we have an alternate Func call that instead (Allows for Unit Testinga)
        if ($null -ne [CRHelper]::TestCommandExistsFunc) 
        {
            return [CRHelper]::TestCommandExistsFunc.Invoke($Name)
        }
        return ($null -ne (Get-Command -Name $Name  -ErrorAction 'SilentlyContinue' )) 
    }
    
    <#
        .SYNOPSIS
            Creates and throws an invalid argument exception
    
        .PARAMETER Message
            The message explaining why this error is being thrown
    
        .PARAMETER ArgumentName
            The name of the invalid argument that is causing this error to be thrown
    #>
    static [void] New_InvalidArgumentException(
        [String] $Message, 
        [String] $ArgumentName
    ) 
    {   

        $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @($Message, $ArgumentName)
        $newObjectParams = @{
            TypeName = 'System.Management.Automation.ErrorRecord'
            ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
        }
        $errorRecord = New-Object @newObjectParams    
        throw $errorRecord
    }
    
    <#
        .SYNOPSIS
            Creates and throws an invalid operation exception
    
        .PARAMETER Message
            The message explaining why this error is being thrown
    
        .PARAMETER ErrorRecord
            The error record containing the exception that is causing this terminating error
    #>
    static [void] New_InvalidOperationException(
        [String] $Message, 
        [ErrorRecord] $ErrorRecord
    ) 
    {   
        # If we have an alternate Func call that instead (Allows for Unit Testinga)
        if ($null -eq $Message) 
        {
            $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
        }
        elseif ($null -eq $ErrorRecord) 
        {
            $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @($Message)
        }
        else 
        {
            $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @($Message, $ErrorRecord.Exception)
        }    
        $newObjectParams = @{
            TypeName = 'System.Management.Automation.ErrorRecord'
            ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect', 'InvalidOperation', $null )
        }    
        $errorRecordToThrow = New-Object @newObjectParams
        throw $errorRecordToThrow
    }
    
    <#
        .SYNOPSIS
            Retrieves the localized string data based on the machine's culture.
            Falls back to en-US strings if the machine's culture is not supported.
    
        .PARAMETER ResourceName
            The name of the resource as it appears before '.strings.psd1' of the localized string file.
            For example:
                For WindowsOptionalFeature: MSFT_WindowsOptionalFeature
                For Service: MSFT_ServiceResource
                For Registry: MSFT_RegistryResource
    #>
    static [hashtable] Get_LocalizedData(
        [String] $ResourceName
    ) 
    { 

        Write-Verbose "ResourceName: $ResourceName"
        $resourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath $ResourceName
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath ([CRHelper]::UICulture)
        Write-Verbose "LocalizedPath: $($localizedStringFileLocation)"
        if (-not (Test-Path -Path $localizedStringFileLocation)) 
        { 
            # Fallback to en-US
            $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
        }
        return Import-LocalizedData -FileName "$ResourceName.strings.psd1" -BaseDirectory $localizedStringFileLocation 
    }
}

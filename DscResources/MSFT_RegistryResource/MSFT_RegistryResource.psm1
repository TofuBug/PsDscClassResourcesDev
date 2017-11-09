using namespace System
using namespace System.Collections.Generic
using namespace System.Collections
using namespace System.Globalization
using namespace Microsoft.Win32
# Import CommonResourceHelper for Get-LocalizedData
using module ..\CRHelper.psm1

# Ensure enumeration for testing the DSC resource
enum Ensure 
{
    Absent
    Present
}

# Enumeration to limit choices to the 5 registry hives still in use in Windows 10 (No more DynData and PerformanceData) 
enum Hive 
{
    ClassesRoot = [RegistryHive]::ClassesRoot
    CurrentConfig = [RegistryHive]::CurrentConfig
    CurrentUser = [RegistryHive]::CurrentUser
    LocalMachine = [RegistryHive]::LocalMachine
    Users = [RegistryHive]::Users
}

[DscResource()]
class xRegistryKey 
{

    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [Hive] $Hive

    [DscProperty(Key)]
    [ValidateNotNullOrEmpty()]
    [string] $Key

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty()]
    [Boolean] $Force = $false

    # We only need one set of Localization Data So we make it static
    hidden static [hashtable] $LocalizedData

    <#
        .SYNOPSIS
            Static Constructor to Initialize xRegistry's static properties
    #>
    static xRegistryKey() 
    {
        # Populate Localization Data
        Write-Verbose -Message "Static Constructor"
        [xRegistryKey]::LocalizedData = [CRHelper]::Get_LocalizedData('MSFT_RegistryResource')
    }
     
    <# 
       .SYNOPSIS 
           Retrieves the current state of the Registry resource with the given Hive and Key. 
    #>
    [xRegistryKey] Get() 
    {
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.GetStartMessage -f $this.Hive, $this.Key)
        # Set Ensure if the registry key exists or not
        if ($this.KeyExists($this.key)) 
        {
            Write-Verbose -Message ([xRegistryKey]::LocalizedData.RegistryKeyExists -f $this.Hive, $this.Key)
            $this.Ensure = [Ensure]::Present
        }
        else
        {
            Write-Verbose -Message ([xRegistryKey]::LocalizedData.RegistryKeyDoesNotExist -f $this.hive, $this.Key)
            $this.Ensure = [Ensure]::Absent
        }
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.GetEndMessage -f $this.Hive, $this.Key)
        return $this
    }
 
    <# 
        .SYNOPSIS 
            Sets the Registry resource with the given Key to the specified state. 
    #>
    [void] Set()
    {
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.SetStartMessage -f $this.Hive, $this.Key)
        # Check if the registry key exists
        if ($this.KeyExists($this.Key)) 
        {
            Write-Verbose -Message ([xRegistryKey]::LocalizedData::RegistryKeyExist -f $this.Hive, $this.Key)
            # Check if the user wants to remove the registry key
            if ($this.Ensure -eq [Ensure]::Absent) 
            {
                # Check if the registry key has subkeys and the user does not want to forcibly remove the registry key
                if ($this.HasSubKeys($this.Key) -and -not $this.Force) 
                {
                    [CRHelper]::New_InvalidOperationException(([xRegistryKey].LocalizedData.CannotRemoveExistingRegistryKeyWithSubKeysWithoutForce -f $this.Hive, $this.Key))
                }
                else
                {
                    # Remove the registry key
                    Write-Verbose -Message ([xRegistryKey]::LocalizedData.RemovingRegistryKey -f $this.Hive, $this.Key)
                    Remove-Item -Path "$($this.Hive):\$($this.Key)" -Recurse -Force
                }
            }
        }
        else
        {
            Write-Verbose -Message ([xRegistryKey]::LocalizedData.RegistryKeyDoesNotExist -f $this.Hive, $this.Key)
            # Check if the user wants the registry key to exist
            if ($this.Ensure -eq [Ensure]::Present)
            {
                Write-Verbose -Message ([xRegistryKey]::LocalizedData.CreatingRegistryKey -f $this.Hive, $this.Key)
                $this.New_RegistryKey()
            }
        }
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.SetEndMessage -f $this.Hive, $this.Key)
    }
    
    <# 
        .SYNOPSIS 
            Tests if the Registry resource with the given key is in the specified state. 
    #>
    [bool] Test() 
    {
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.TestStartMessage -f $this.Hive, $this.Key)
        $registryResourceInDesiredState = if ($this.KeyExists($this.Key)) {$this.ensure -eq [Ensure]::Present } else{$this.ensure -eq [Ensure]::Absent }
        Write-Verbose -Message ([xRegistryKey]::LocalizedData.TestEndMessage -f $this.Hive, $this.Key)
        return $registryResourceInDesiredState
    }
                     
    <# 
        .SYNOPSIS 
            Mounts the registry drive with the specified name. 
    #>
    hidden [void] Mount_RegistryDrive() 
    {
        $registryDriveInfo = Get-PSDrive -Name $this.Hive -ErrorAction 'SilentlyContinue'
        if ($null -eq $registryDriveInfo) 
        {
            $newPSDriveParameters = @{
                Name = $this.Hive
                Root = [Registry]::"$($this.Hive)".Name
                PSProvider = 'Registry'
                Scope = 'Script'
            }
            $registryDriveInfo = New-PSDrive @newPSDriveParameters
        }    
        # Validate that the specified PSDrive is valid
        if (($null -eq $registryDriveInfo) -or ($null -eq $registryDriveInfo.Provider) -or ($registryDriveInfo.Provider.Name -ine 'Registry')) 
        {
            [CRHelper]::New_InvalidOperationException(([xRegistryKey]::LocalizedData.RegistryDriveCouldNotBeMounted -f $this.Hive))
        }
    }
     
    <# 
        .SYNOPSIS 
            Opens the specified registry sub key under the specified registry parent key. 
            This is a wrapper function for unit testing. 
  
        .PARAMETER ParentKey 
            The parent registry key which contains the sub key to open. 
  
        .PARAMETER SubKey 
            The sub key to open. 
  
        .PARAMETER WriteAccessAllowed 
            Specifies whether or not to open the sub key with permissions to write to it. 
    #>
    hidden [RegistryKey] Open_RegistrySubKey([RegistryKey] $ParentKey, [String] $SubKey, [bool] $WriteAccessAllowed) 
    {
        return $ParentKey.OpenSubKey($SubKey, $WriteAccessAllowed) 
    }
          
    <# 
        .SYNOPSIS 
            Opens and retrieves the registry key at the specified path. 
  
        .PARAMETER RegistryKeyPath 
            The path to the registry key to open. 
            The path must include the registry drive. 
  
        .PARAMETER WriteAccessAllowed 
            Specifies whether or not to open the key with permissions to write to it. 
  
        .NOTES 
            This method is used instead of Get-Item so that there is no ambiguity between 
            forward slashes as path separators vs literal characters in a key name 
            (which is valid in the registry). 
    #>
    hidden [RegistryKey] Get_RegistryKey([String] $RegistryKeyPath,[bool] $WriteAccessAllowed) 
    {
        # Mount the registry drive if needed
        $this.Mount_RegistryDrive()
        # Retrieve the registry drive key
        $registryDriveKey = Get-Item -LiteralPath ("$($this.Hive):")
        # Open and return the registry drive subkey
        return $this.Open_RegistrySubKey($registryDriveKey,$RegistryKeyPath,$WriteAccessAllowed)
    }
    
    <# 
        .SYNOPSIS 
            Creates a new subkey with the specified name under the specified registry key. 
            This is a wrapper function for unit testing. 
  
        .PARAMETER ParentRegistryKey 
            The parent registry key to create the new subkey under. 
  
        .PARAMETER SubKeyName 
            The name of the new subkey to create. 
    #>
    hidden [RegistryKey] New_RegistrySubKey([RegistryKey] $ParentRegistryKey,[String] $SubKeyName) 
    {
        return $ParentRegistryKey.CreateSubKey($SubKeyName) 
    }
    
    <# 
        .SYNOPSIS 
            Creates a new registry key at the specified registry key path. 
    #>
    hidden [RegistryKey] New_RegistryKey() 
    {
        # Registry key names can contain forward slashes, so we can't use Split-Path here (it will split on /)
        Write-Verbose -Message "Key: $($this.Key)"
        $Tokens = $this.Key -split '\\'
        Write-Verbose -Message "Tokens = $Tokens"
        $RegKey = if (-not $this.KeyExists(($ParentPath = $Tokens[0]))) 
        {
            Write-Verbose -Message "Creating Path $([Registry]::"$($this.Hive)")"
            $this.New_RegistrySubKey([Registry]::"$($this.Hive)",$ParentPath) 
        }
        else
        {
            $this.Get_RegistryKey($ParentPath,$true) 
        }
        for ($i = 1; $i -lt $Tokens.Count; $i++)
        {
            $RegKey = if (-not $this.KeyExists(($ParentPath += "\$($Tokens[$i])"))) 
            {
                $this.New_RegistrySubKey($RegKey,$Tokens[$i]) 
            }
            else
            {
                $this.Get_RegistryKey($ParentPath, $true) 
            }           
        }
        return $RegKey        
    }
    
    <# 
        .SYNOPSIS 
            Checks if a key has subkeys under the specificregistry key. 
            This is a wrapper function for unit testing. 

        .PARAMETER Path 
            The path to the registry key to retrieve the subkeys of. 
    #>
    hidden [bool] HasSubKeys([String] $RegistryKeyPath ) 
    {
        return ($this.Get_RegistryKey($RegistryKeyPath, $false).SubKeyCount -gt 0) 
    }

    <# 
        .SYNOPSIS 
            Tests if a Key Exists at the specified path. 
  
        .PARAMETER Path 
            The path to the registry key to open. 
    #>
    hidden [bool] KeyExists([String] $RegistryKeyPath) 
    {
        return ($null -ne $this.Get_RegistryKey($RegistryKeyPath, $false)) 
    }
}

# Enumeration to limit choices to only the valid ValueTypes
enum ValueKind 
{
    Binary = [RegistryValueKind]::Binary
    DWord = [RegistryValueKind]::DWord
    MultiString = [RegistryValueKind]::MultiString
    QWord = [RegistryValueKind]::QWord
    String = [RegistryValueKind]::String
}

[DscResource()]
class xRegistryValue : xRegistryKey 
{

    [DscProperty(Key)]
    [String] $ValueName = $this.Get_RegistryKeyValueDisplayName()

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(Mandatory)]
    [ValueKind] $ValueType

    [DscProperty()]
    [object] $ValueData

    [DscProperty()]
    [Boolean] $Hex = $false

    <# 
       .SYNOPSIS 
           Retrieves the current state of the Registry resource with the given Key, and Value. 
    #>
    [xRegistryValue] Get() 
    {
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.GetTargetResourceStartMessage -f $this.Hive, $this.Key)
        # Calling Key Base Class Get method
        ([xRegistryKey]$this).Get()
        # Is the Key part Present? then check the value Part (No need for further processing if Absent, if the Key does
        # not exist obviously the Value cannot exist)
        if ($this.Ensure -eq [Ensure]::Present) 
        {
            # Calls method from base class to get registry key
            $RegistryKey = ([xRegistryKey]$this).Get_RegistryKey($this.Key,$true)
            # Retrieve the value with the specified name from the retrieved registry key
            $registryKeyValue = $this.Get_RegistryKeyValue($registryKey)
            # Check if the registry key value does not exist, set Ensure and done
            if ($null -eq $registryKeyValue) 
            {
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueDoesNotExist -f $this.Hive, $this.Key, $this.ValueName) 
                $this.Ensure = [Ensure]::Absent
            }
            # Other wise it exists so set the other properties and done
            else
            {
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueExists -f $this.Hive, $this.Key, $this.ValueName)
                # If the registry key value exists, retrieve its type
                $this.ValueType = $this.Get_RegistryKeyValueType($registryKey)
                # If the registry key value exists, convert it to a readable string
                $this.ValueData = $this.ConvertTo_ReadableString($registryKeyValue)
                $this.Ensure = [Ensure]::Present
            }
        }
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.GetTargetResourceEndMessage -f $this.Hive, $this.Key)
        return $this
   }
 
    <# 
        .SYNOPSIS 
            Sets the Registry resource with the given Key, and value to the specified state. 
    #>
    [void] Set() 
    {
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.SetTargetResourceStartMessage -f $this.Hive, $this.Key)
        # If we wish the value to be present
        if ($this.Ensure -eq [Ensure]::Present) 
        {
            # Start by creating or verifying the Key part
            ([xRegistryKey]$this).Set()
            # Get the registry key
            $RegistryKey = ([xRegistryKey]$this).Get_RegistryKey($this.Key,$true)
            # Retrieve the existing registry key value
            $actualRegistryKeyValue = $this.Get_RegistryKeyValue($RegistryKey)
            # Convert the specified registry key value to the specified type 
            # No need to check for ValueData being null Convert Methods set default values
            $expectedRegistryKeyValue = switch ($this.ValueType) 
            {
               ([ValueKind]::Binary)      {$this.ConvertTo_Binary(); break }
               ([ValueKind]::DWord)       {$this.ConvertTo_DWord(); break }
               ([ValueKind]::MultiString) {$this.ConvertTo_MultiString(); break }
               ([ValueKind]::QWord)       {$this.ConvertTo_QWord(); break }
               ([ValueKind]::String)      {$this.ConvertTo_String(); break}
            }
            # Check if the registry key value exists
            if ($null -eq $actualRegistryKeyValue) 
            {
                # If the registry key value does not exist, set the new value
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.SettingRegistryKeyValue -f $this.ValueName, $this.Hive, $this.Key)
                $this.Set_RegistryKeyValue($RegistryKey,$expectedRegistryKeyValue)
            }
            else
            {
                # If the registry key value exists, check if the specified registry key value matches the retrieved registry key value
                if ($this.Test_RegistryKeyValuesMatch($expectedRegistryKeyValue,$actualRegistryKeyValue,$this.ValueType)) 
                {
                    # If the specified registry key value matches the retrieved registry key value, no change is needed
                    Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueAlreadySet -f $this.ValueName, $this.Hive, $this.Key)
                }
                else
                {
                    # If the specified registry key value matches the retrieved registry key value, check if the user wants to overwrite the value
                    if (-not $this.Force) 
                    {
                        # If the user does not want to overwrite the value, throw an error
                        [CRHelper]::New_InvalidOperationException(([xRegistryValue].LocalizedData.CannotOverwriteExistingRegistryKeyValueWithoutForce -f $this.Hive, $this.Key, $this.ValueName))
                    }
                    else
                    {
                        # If the user does want to overwrite the value, overwrite the value
                        Write-Verbose -Message ([xRegistryValue]::LocalizedData.OverwritingRegistryKeyValue -f $this.ValueName, $this.Hive, $this.Key)
                        $this.Set_RegistryKeyValue($RegistryKey,$expectedRegistryKeyValue)
                    }
                }   
            }
        }
        # Otherwise we want the value to be absent
        else
        {
            <# 
                If we want the value to be absent and the base class passes its test 
                By extension the value cannot exist so we are done
            #>
            if (([xRegistryKey]$this).Test()) 
            {
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyDoesNotExist -f $this.Hive, $this.Key)
            }
            else
            {
                # Retrieve the registry key at the specified path
                $RegistryKey = ([xRegistryKey]$this).Get_RegistryKey($this.Key,$true)
                # Retrieve the existing registry key value
                $actualRegistryKeyValue = $this.Get_RegistryKeyValue($RegistryKey)
                # Does the value not exist then we are done
                if ($null -eq $actualRegistryKeyValue) 
                {
                    Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueDoesNotExist -f $this.Hive, $this.Key, $this.ValueName)
                }
                # So the value exists lets remove it
                else
                {
                    $this
                    Write-Verbose -Message ([xRegistryValue]::LocalizedData.RemovingRegistryKeyValue -f $this.ValueName, $this.Hive, $this.Key)
                }
            }
        }
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.SetTargetResourceEndMessage -f $this.Hive, $this.Key)
    }
    
    <# 
        .SYNOPSIS 
            Tests if the Registry resource with the given key and value is in the specified state. 
    #>
    [bool] Test() 
    {
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.TestTargetResourceStartMessage -f $this.Hive, $this.Key)
        [bool] $registryResourceInDesiredState = $false
        # Test if the Key passes or fails
        [bool] $KeyInDesiredState = ([xRegistryKey]$this).Test()
        # Get the registry Key
        $RegistryKey = ([xRegistryKey]$this).Get_RegistryKey($this.Key, $true)
        # Key Test Pass & Ensure Absent is almost the same result as a Key Test Fail & Ensure Present
        if (($KeyInDesiredState -and $this.Ensure -eq [Ensure]::Absent) -or (-not $KeyInDesiredState -and $this.Ensure -eq [Ensure]::Present)) 
        {
        
            # In both cases the Registry Key does not exist
            Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyDoesNotExist -f $this.Hive, $this.Key)
            # If the Registry Key does not exist the Registry Value can NOT exist by extention
            Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueDoesNotExist -f $this.Hive, $this.Key, $this.ValueName)
            # If we wanted it to be Absent then it will be true elsefalse
            $registryResourceInDesiredState = $this.Ensure -eq [Ensure]::Absent
        }
        # We have a Key now we check the ensure 
        else
        {
            # If we made it here we KNOW we have a registry Key
            Write-Verbose -Message ([xRegistryValue].LocalizedData.RegistryKeyExists -f $this.Hive, $this.Key)
            # Get the current value from the Registr key
            $ActualRegistryKeyValue = $this.Get_RegistryKeyValue($RegistryKey)
            # See if we have do NOT have a value in the registry key
            if ($null -eq $ActualRegistryKeyValue) 
            {
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueDoesNotExist -f $this.Hive, $this.Key, $this.ValueName)
                # If we wanted Absent its true, false if Present
                $registryResourceInDesiredState = ($this.Ensure -eq [Ensure]::Absent)
            }
            # We have a value
            else
            {
                Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueExists -f $this.Hive, $this.Key, $this.ValueName)
                $ActualRegistryKeyValueType = $this.Get_RegistryKeyValueType($registryKey)
                $ActualRegistryKeyValueData = $this.ConvertTo_ReadableString($ActualRegistryKeyValue)
                if ($this.ValueType -ne $ActualRegistryKeyValueType) 
                {
                    Write-Verbose -Message ([xRegistryValue]::LocalizedData.RegistryKeyValueTypeDoesNotMatch -f $this.ValueName, $this.Hive, $this.Key, $this.ValueType, $ActualRegistryKeyValueType)
                    # Assume if Value is of a different Type the one we want is not there hence Ensure Absent is true
                    $registryResourceInDesiredState = ($this.Ensure -eq [Ensure]::Absent)
                }
                else
                {
                    # Convert the specified registry key value to the specified type
                    # No need to check for null convert methods return default values for each type
                    $expectedRegistryKeyValue = switch ($this.ValueType) 
                    {
                        ([ValueKind]::Binary)      {$this.ConvertTo_Binary(); break }
                        ([ValueKind]::DWord)       {$this.ConvertTo_DWord(); break }
                        ([ValueKind]::MultiString) {$this.ConvertTo_MultiString(); break }
                        ([ValueKind]::QWord)       {$this.ConvertTo_QWord(); break }
                        ([ValueKind]::String)      {$this.ConvertTo_String(); break }
                    }
                    if (-not ( $this.Test_RegistryKeyValuesMatch($expectedRegistryKeyValue, $ActualRegistryKeyValue,$this.ValueType))) 
                    {
                        Write-Verbose -Message ([xRegistryValue].LocalizedData.RegistryKeyValueDoesNotMatch -f $this.ValueName, $this.Hive, $this.Key, $this.ValueData, $ActualRegistryKeyValueData)
                        # Assume if Value has a different Value Data than we want it is not there hence Ensure Absent is true
                        $registryResourceInDesiredState = ($this.Ensure -eq [Ensure]::Absent)
                    }
                    # It did match so was Ensure set to Present
                    else
                    {
                        $registryResourceInDesiredState = ($this.Ensure -eq [Ensure]::Present) 
                    }
                }
            }
        }
        Write-Verbose -Message ([xRegistryValue]::LocalizedData.TestTargetResourceEndMessage -f $this.Hive, $this.Key)
        return $registryResourceInDesiredState
    }

    <# 
        .SYNOPSIS 
            Retrieves the display name of the default registry key value if needed. 
    #>
    [void] Get_RegistryKeyValueDisplayName() 
    {
        if ([String]::IsNullOrEmpty($this.ValueName)) 
        {
            $this.ValueName = [xRegistryValue]::LocalizedData.DefaultValueDisplayName 
        } 
    }
    
    <# 
        .SYNOPSIS 
            Retrieves the registry key value with the specified name from the specified registry key. 
            This is a wrapper function for unit testing. 
    
        .PARAMETER RegistryKey 
            The registry key to retrieve the value from. 
    #>
    hidden [object[]] Get_RegistryKeyValue([RegistryKey] $RegistryKey) 
    {
        $registryKeyValue = $RegistryKey.GetValue($this.ValueName, $null, [RegistryValueOptions]::DoNotExpandEnvironmentNames)
        return ,$registryKeyValue
    }
    
    <# 
        .SYNOPSIS 
            Retrieves the type of the registry key value with the specified name from the the specified 
            registry key. 
            This is a wrapper function for unit testing. 
    
        .PARAMETER RegistryKey 
            The registry key to retrieve the type of the value from. 
    #>
    hidden [ValueKind] Get_RegistryKeyValueType([RegistryKey] $RegistryKey) 
    {
        return [ValueKind]$RegistryKey.GetValueKind($this.ValueName) 
    }
    
    <# 
        .SYNOPSIS 
            Converts the specified byte array to a hex string. 
    
        .PARAMETER ByteArray 
            The byte array to convert. 
    #>
    hidden [string] Convert_ByteArrayToHexString([Object[]] $ByteArray ) 
    {
        $hexString = ''
        foreach ($byte in $ByteArray) 
        {
            $hexString += ('{0:x2}' -f $byte) 
        }
        return $hexString
    }
    
    <# 
        .SYNOPSIS 
            Converts the specified registry key value to a readable string. 
    
        .PARAMETER RegistryKeyValue 
            The registry key value to convert. 
    
    #>
    hidden [string] ConvertTo_ReadableString([Object[]] $RegistryKeyValue) 
    {
        $registryKeyValueAsString = [String]::Empty
        if ($null -ne $RegistryKeyValue)
        {
            # For Binary type data, convert the received bytes back to a readable hex-string
            if ($this.ValueType -eq [RegistryValueKind]::Binary) 
            {
                $RegistryKeyValue = $this.Convert_ByteArrayToHexString($RegistryKeyValue) 
            }
            if ($this.ValueType -ne [RegistryValueKind]::MultiString) 
            {
                $RegistryKeyValue = [String[]] @() + $RegistryKeyValue 
            }
            if ($RegistryKeyValue.Count -eq 1 -and -not [String]::IsNullOrEmpty($RegistryKeyValue[0])) 
            {
                $registryKeyValueAsString = $RegistryKeyValue[0].ToString() 
            }
            elseif ($RegistryKeyValue.Count -gt 1) 
            {
                $registryKeyValueAsString = "($($RegistryKeyValue -join ', '))" 
            }
        }
        return @() + $registryKeyValueAsString
    }
             
    <# 
        .SYNOPSIS 
            Converts $this.ValueData to a byte array for the Binary registry type. 
    #>
    hidden [byte[]] ConvertTo_Binary() 
    {
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -gt 1)) 
        {
            [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.ArrayNotAllowedForExpectedType -f 'Binary'))
        }
        $binaryRegistryKeyValue = [Byte[]] @()
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -eq 1) -and (-not [String]::IsNullOrEmpty($this.ValueData[0]))) 
        {
            $singleRegistryKeyValue = $this.ValueData[0]
            if ($singleRegistryKeyValue.StartsWith('0x'))
            {
                $singleRegistryKeyValue = $singleRegistryKeyValue.Substring('0x'.Length) 
            }
            if (($singleRegistryKeyValue.Length % 2) -ne 0) 
            {
                $singleRegistryKeyValue = $singleRegistryKeyValue.PadLeft($singleRegistryKeyValue.Length + 1, '0') 
            }
            try 
            {
                for ($singleRegistryKeyValueIndex = 0 ; $singleRegistryKeyValueIndex -lt ($singleRegistryKeyValue.Length - 1) ; $singleRegistryKeyValueIndex = $singleRegistryKeyValueIndex + 2) 
                {
                    $binaryRegistryKeyValue += [Byte]::Parse($singleRegistryKeyValue.Substring($singleRegistryKeyValueIndex, 2), 'HexNumber')
                }
            }
            catch 
            {
                [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.BinaryDataNotInHexFormat -f $singleRegistryKeyValue)) 
            }
        }
        return $binaryRegistryKeyValue
    }   
    
    <# 
        .SYNOPSIS 
            Converts $this.ValueData to an Int32 for the DWord registry type. 
    #>
    hidden [Int32] ConvertTo_DWord() 
    {
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -gt 1)) 
        {
            [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.ArrayNotAllowedForExpectedType -f 'Dword'))
        }
        $dwordRegistryKeyValue = [Int32] 0
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -eq 1) -and (-not [String]::IsNullOrEmpty($this.ValueData[0])))
        {
            $singleRegistryKeyValue = $this.ValueData[0]
            if ($this.Hex) 
            {
                if ($singleRegistryKeyValue.StartsWith('0x')) 
                {
                    $singleRegistryKeyValue = $singleRegistryKeyValue.Substring('0x'.Length) 
                }
                $currentCultureInfo = [CultureInfo]::CurrentCulture
                $referenceValue = $null
                if ([Int32]::TryParse($singleRegistryKeyValue, 'HexNumber', $currentCultureInfo, [Ref] $referenceValue)) 
                {
                    $dwordRegistryKeyValue = $referenceValue 
                }
                else
                {
                    [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.DWordDataNotInHexFormat -f $singleRegistryKeyValue)) 
                }
            }
            else
            {
                $dwordRegistryKeyValue = [Int32]::Parse($singleRegistryKeyValue) 
            }
        }
        return $dwordRegistryKeyValue
    }
    
    <# 
        .SYNOPSIS 
            Converts $this.ValueData to a string array for the MultiString registry type. 
    #>
    hidden [string[]] ConvertTo_MultiString() 
    {
        if (($null -ne $this.ValueData) -and ($this.ValueData.Length -gt 0)) 
        {
            return [String[]]$this.ValueData 
        }
        else
        {
            return [String[]] @() 
        }
    }
    
    <# 
        .SYNOPSIS 
            Converts $this.ValueData to an Int64 for the QWord registry type. 
    #>
    hidden [Int64] ConvertTo_QWord() 
    {
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -gt 1)) 
        {
            [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.ArrayNotAllowedForExpectedType -f 'Qword'))
        }
        $qwordRegistryKeyValue = [Int64] 0  
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -eq 1) -and (-not [String]::IsNullOrEmpty($this.ValueData[0]))) 
        {
            $singleRegistryKeyValue = $this.ValueData[0]
            if ($this.Hex) 
            {
                if ($singleRegistryKeyValue.StartsWith('0x')) 
                {
                    $singleRegistryKeyValue = $singleRegistryKeyValue.Substring('0x'.Length) 
                }
                $currentCultureInfo = [CultureInfo]::CurrentCulture
                $referenceValue = $null
                if ([Int64]::TryParse($singleRegistryKeyValue, 'HexNumber', $currentCultureInfo, [Ref] $referenceValue)) 
                {
                    $qwordRegistryKeyValue = $referenceValue 
                }
                else
                {
                    [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.QWordDataNotInHexFormat -f $singleRegistryKeyValue)) 
                }
            }
            else
            {
                $qwordRegistryKeyValue = [Int64]::Parse($singleRegistryKeyValue) 
            }
        }
        return $qwordRegistryKeyValue
    }
    
    <# 
        .SYNOPSIS 
            Converts $this.ValueData to a string for the String or ExpandString registry types. 
    #>
    hidden [string] ConvertTo_String() 
    {
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -gt 1)) 
        {
            [CRHelper]::New_InvalidArgumentException('ValueData',([xRegistryValue]::LocalizedData.ArrayNotAllowedForExpectedType -f 'String or ExpandString'))
        }
        if (($null -ne $this.ValueData) -and ($this.ValueData.Count -eq 1)) 
        {
            return [String]$this.ValueData[0] 
        }
        else
        {
            return [String]::Empty 
        }
    }
    
    <# 
        .SYNOPSIS 
            Sets the specified registry key value with the specified name to the specified value. 
            This is a wrapper function for unit testing. 
    
        .PARAMETER RegistryKey 
            The key to set the value in. 
    
        .PARAMETER RegistryKeyValue 
            The new value to set the registry key value to. 
    #>
    hidden [void] Set_RegistryKeyValue([RegistryKey] $RegistryKey, [Object] $RegistryKeyValue) 
    {
        if ($this.ValueType -eq [ValueKind]::Binary) 
        {
            $RegistryKeyValue = [Byte[]]$RegistryKeyValue 
        }
        elseif ($this.ValueType -eq [ValueKind]::MultiString) 
        {
            $RegistryKeyValue = [String[]]$RegistryKeyValue 
        }
        $RegistryKey.SetValue($this.ValueName, $RegistryKeyValue, $this.ValueType)
    }
    
    <# 
        .SYNOPSIS 
            Tests if the actual registry key value matches the expected registry key value. 
    
        .PARAMETER ExpectedRegistryKeyValue 
            The expected registry key value to test against. 
    
        .PARAMETER ActualRegistryKeyValue 
            The actual registry key value to test. 
    
        .PARAMETER RegistryKeyValueType 
            The type of the registry key values. 
    #>
    hidden [bool] Test_RegistryKeyValuesMatch([Object] $ExpectedRegistryKeyValue, [Object] $ActualRegistryKeyValue, [ValueKind] $RegistryKeyValueType) 
    {
        if ($RegistryKeyValueType -eq [ValueKind]::MultiString -or $RegistryKeyValueType -eq [ValueKind]::Binary) 
        {
            if ($null -eq $ExpectedRegistryKeyValue) 
            {
                $ExpectedRegistryKeyValue = @() 
            }
            if ($null -eq $ActualRegistryKeyValue) 
            {
                $ActualRegistryKeyValue = @() 
            }
            return ($null -eq (Compare-Object -ReferenceObject $ExpectedRegistryKeyValue -DifferenceObject $ActualRegistryKeyValue))
        }
        else
        {
            if ($null -eq $ExpectedRegistryKeyValue) 
            {
                $ExpectedRegistryKeyValue = '' 
            }
            if ($null -eq $ActualRegistryKeyValue) 
            {
                $ActualRegistryKeyValue = '' 
            }
            return ($ExpectedRegistryKeyValue -ieq $ActualRegistryKeyValue)
        }
    }
    
    <# 
        .SYNOPSIS 
            Removes the value of the specified registry key. 
            This is a wrapper function for unit testing. 
        
        .PARAMETER RegistryKey 
            The registry key to remove the value of. 
    #>
    hidden [void] Remove_KeyValue([RegistryKey] $RegistryKey ) 
    {
        # If we are working with the Default Value delete it
        if ($this.ValueName -eq [xRegistryValue]::LocalizedData.DefaultValueDisplayName) 
        {
            $RegistryKey.DeleteValue('')
        } 
        # Otherwise remove the specific value
        else
        {
            Remove-ItemProperty -Path "$($this.Hive):\$($this.Key)" -Name $this.ValueName -Force
        }
    }
}

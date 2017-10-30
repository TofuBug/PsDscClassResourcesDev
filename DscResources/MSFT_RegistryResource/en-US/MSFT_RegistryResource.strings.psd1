# Localized resources for MSFT_RegistryResource

ConvertFrom-StringData @'
    DefaultValueDisplayName = (Default)

    GetStartMessage = Get() is starting for Registry resource with Hive {0}, and Key {1}
    GetEndMessage = Get() has finished for Registry resource with Hive {0}, Key {1}
    RegistryKeyDoesNotExist = The registry key at path {0}:\{1} does not exist.
    RegistryKeyExists = The registry key at path {0}:\{1} exists.
    RegistryKeyValueDoesNotExist = The registry key at path {0}:\{1} does not have a value named {2}.
    RegistryKeyValueExists = The registry key at path {0}:\{1} has a value named {2}.

    SetStartMessage = Set() is starting for Registry resource with  Hive {0}, Key {1}
    SetEndMessage = Set() has finished for Registry resource with  Hive {0}, Key {1}
    CreatingRegistryKey = Creating registry key at path {0}:\{1}...
    SettingRegistryKeyValue = Setting the value {0} under the registry key at path {1}:\{2}...
    OverwritingRegistryKeyValue = Overwriting the value {0} under the registry key at path {1}:\{2}...
    RemovingRegistryKey = Removing registry key at path {0}:\{1}...
    RegistryKeyValueAlreadySet = The value {0} under the registry key at path {1}:\{2} has already been set to the specified value.
    RemovingRegistryKeyValue = Removing the value {0} from the registry key at path {1}:\{2}...

    TestStartMessage = Test() is starting for Registry resource with Hive {0}, Key {1}
    TestEndMessage = Test() has finished for Registry resource with Hive {0}, Key {1}
    RegistryKeyValueTypeDoesNotMatch = The type of the value {0} under the registry key at path {1}:\{2} does not match the expected type. Expected {3} but was {4}.
    RegistryKeyValueDoesNotMatch = The value {0} under the registry key at path {1}:\{2} does not match the expected value. Expected {3} but was {4}.

    CannotRemoveExistingRegistryKeyWithSubKeysWithoutForce = The registry key at path {0}:\{1} has subkeys. To remove this registry key please specifiy the Force parameter as $true.
    CannotOverwriteExistingRegistryKeyValueWithoutForce = The registry key at path {0}:\{1} already has a value with the name {2}. To overwrite this registry key value please specifiy the Force parameter as $true.
    CannotRemoveExistingRegistryKeyValueWithoutForce = The registry key at path {0}:\{1} already has a value with the name {2}. To remove this registry key value please specifiy the Force parameter as $true.
    RegistryDriveInvalid = The registry drive specified in the registry key path {0}:\{1} is missing or invalid.
    ArrayNotAllowedForExpectedType = The specified value data has been declared as a string array, but the registry key type {0} cannot be converted from an array. Please declare the value data as only one string or use the registry type MultiString.
    DWordDataNotInHexFormat = The specified registry key value data {0} is not in the correct hex format to parse as an Int32 (dword).
    QWordDataNotInHexFormat = The specified registry key value data {0} is not in the correct hex format to parse as an Int64 (qword). 
    BinaryDataNotInHexFormat = The specified registry key value data {0} is not in the correct hex format to parse as a Byte array (Binary).
    InvalidRegistryDrive = The registry drive {0} is invalid. Please update the Key parameter to include a valid registry drive.
    InvalidRegistryDriveAbbreviation = The registry drive abbreviation {0} is invalid. Please update the Key parameter to include a valid registry drive.
    RegistryDriveCouldNotBeMounted = The registry drive with the abbreviation {0} could not be mounted.
'@

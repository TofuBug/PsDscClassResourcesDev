using namespace Microsoft.PowerShell.Commands
#using module ($PSScriptRoot | Split-Path | Split-Path | Join-Path -ChildPath "DscResources\CommonClassResourceHelper.psm1")
using module ..\..\DscResources\CommonClassResourceHelper.psm1

$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Describe 'CommonClassResourceHelper Unit Tests' {
    BeforeAll {
    }
    Describe 'Test-IsNanoServer' {
        BeforeAll {
        # Setup class to mock ComputerInfo (Properties are only internally settable)
        class MockComputerInfo : ComputerInfo
        {
            [ServerLevel] $OsServerLevel
            [ProductType] $OsProductType            
        }    
        }
        # Initialize our Test Case Objects
        $testComputerInfoNanoServer = [MockComputerInfo]::new()
        $testComputerInfoServerNotNano = [MockComputerInfo]::new()
        $testComputerInfoNotServer = [MockComputerInfo]::new()
        #Setup Each Test Cases
        $testComputerInfoNanoServer.OsProductType = [ProductType]::Server
        $testComputerInfoNanoServer.OsServerLevel = [ServerLevel]::NanoServer
        $testComputerInfoServerNotNano.OsProductType = [ProductType]::Server
        $testComputerInfoServerNotNano.OsServerLevel = [ServerLevel]::FullServer
        $testComputerInfoNotServer.OsProductType = [ProductType]::WorkStation
        $testComputerInfoNotServer.OsServerLevel = [ServerLevel]::Unknown
        Context 'Get-ComputerInfo command exists and succeeds' {
        Context 'Computer OS type is Server and OS server level is NanoServer' {
            [CommonClassResourceHelper]::GetComputerInfoFunc = { return $testComputerInfoNanoServer }
            It 'Should not throw' {
                { 
                    $null = [CommonClassResourceHelper]::Test_IsNanoServer() 
                } | Should Not Throw
            }
            It 'Should return true' {
                [CommonClassResourceHelper]::Test_IsNanoServer() | Should Be $true
            }
            Context 'Only Get_ComputerInfo has been "Mocked"' {
                It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
                    [CommonClassResourceHelper]::GetComputerInfoFunc | Should Not Be $null
                }
                It 'TestCommandExistsFunc Should be null' {
                    [CommonClassResourceHelper]::TestCommandExistsFunc | Should Be $null
                }
                It 'TestIsNanoServerFunc Should be null' {
                    [CommonClassResourceHelper]::TestIsNanoServerFunc | Should Be $null
                }
            }
        }   
        Context 'Computer OS type is Server and OS server level is not NanoServer' {
            [CommonClassResourceHelper]::GetComputerInfoFunc = { return $testComputerInfoServerNotNano }        
            It 'Should not throw' {
                { $null = [CommonClassResourceHelper]::IsNanoServer } | Should Not Throw
            }
            It 'Should return false' {
                [CommonClassResourceHelper]::Test_IsNanoServer()  | Should Be $false
            }
            Context 'Only Get_ComputerInfo has been "Mocked"' {
                It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
                    [CommonClassResourceHelper]::GetComputerInfoFunc | Should Not Be $null
                }
                It 'TestCommandExistsFunc Should be null' {
                    [CommonClassResourceHelper]::TestCommandExistsFunc | Should Be $null
                }
                It 'TestIsNanoServerFunc Should be null' {
                    [CommonClassResourceHelper]::TestIsNanoServerFunc | Should Be $null
                }
            }
        }
        Context 'Computer OS type is not Server' {
            [CommonClassResourceHelper]::GetComputerInfoFunc = { return $testComputerInfoNotServer }
            It 'Should not throw' {
                { $null = [CommonClassResourceHelper]::Test_IsNanoServer() } | Should Not Throw
            }
            It 'Should return false' {
                [CommonClassResourceHelper]::Test_IsNanoServer() | Should Be $false
            }
            Context 'Only Get_ComputerInfo has been "Mocked"' {
                It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
                    [CommonClassResourceHelper]::GetComputerInfoFunc | Should Not Be $null
                }
                It 'TestCommandExistsFunc Should be null' {
                    [CommonClassResourceHelper]::TestCommandExistsFunc | Should Be $null
                }
                It 'TestIsNanoServerFunc Should be null' {
                    [CommonClassResourceHelper]::TestIsNanoServerFunc | Should Be $null
                }
            }                    
        }
        }
        Context 'Get-ComputerInfo command exists but throws an error and returns null' {
        [CommonClassResourceHelper]::ResetFuncsToNormal()
        [CommonClassResourceHelper]::GetComputerInfoFunc = { return $null }
        It 'Should not throw' {
            { $null = [CommonClassResourceHelper]::IsNanoServer } | Should Not Throw
        }
        It 'Should return false' {
            [CommonClassResourceHelper]::IsNanoServer | Should Be $false
        }
        Context 'Only Get_ComputerInfo has been "Mocked"' {    
            It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
                [CommonClassResourceHelper]::GetComputerInfoFunc | Should Not Be $null
            }
            It 'TestCommandExistsFunc Should be null' {
                [CommonClassResourceHelper]::TestCommandExistsFunc | Should Be $null
            }
            It 'TestIsNanoServerFunc Should be null' {
                [CommonClassResourceHelper]::TestIsNanoServerFunc | Should Be $null
            }
        }                                        
        }
        Context 'Get-ComputerInfo command does not exist' {
        [CommonClassResourceHelper]::ResetFuncsToNormal()
        [CommonClassResourceHelper]::TestCommandExistsFunc = { return $false }
        It 'Should not throw' {
            { $null = [CommonClassResourceHelper]::IsNanoServer } | Should Not Throw
        }
        It 'Should return false' {
            [CommonClassResourceHelper]::IsNanoServer | Should Be $false
        }
        Context 'Only Test_CommandExists has been "Mocked"' {
            It 'GetComputerInfoFunc Should be null' {
                [CommonClassResourceHelper]::GetComputerInfoFunc | Should Be $null
            }
            It 'TestCommandExistsFunc Should NOT be null (It has been mocked' {
                [CommonClassResourceHelper]::TestCommandExistsFunc | Should Not Be $null
            }
            It 'TestIsNanoServerFunc Should be null' {
                [CommonClassResourceHelper]::TestIsNanoServerFunc | Should Be $null
            }
        }        
        [CommonClassResourceHelper]::ResetFuncsToNormal()                                
        }
    }
    Describe 'Test_CommandExists' {
        $testCommandName = 'TestCommandName'
        [CommonClassResourceHelper]::ResetFuncsToNormal()
        Mock -CommandName 'Get-Command' -MockWith { return $Name } -ModuleName CommonClassResourceHelper
        Context 'Get-Command returns the command' {
            It 'Should not throw' {
                { $null = [CommonClassResourceHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
            }
            It 'Should retrieve the command with the specified name' {
                $getCommandParameterFilter = {
                    return $Name -eq $testCommandName
                }
                Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context' -ModuleName CommonClassResourceHelper
            }
            It 'Should return true' {
                [CommonClassResourceHelper]::Test_CommandExists($testCommandName) | Should Be $true
            }
        }
        Context 'Get-Command returns null' {
            Mock -CommandName 'Get-Command' -MockWith { return $null } -ModuleName CommonClassResourceHelper
            It 'Should not throw' {
                { $null = [CommonClassResourceHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
            }
            It 'Should retrieve the command with the specified name' {
                $getCommandParameterFilter = {
                    return $Name -eq $testCommandName
                }
                Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context' -ModuleName CommonClassResourceHelper
            }
            It 'Should return false' {
                [CommonClassResourceHelper]::Test_CommandExists($testCommandName) | Should Be $false
            }
        }
    }
}

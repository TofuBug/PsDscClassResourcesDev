using namespace Microsoft.PowerShell.Commands
using module ..\..\DscResources\CRHelper.psm1 

$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Describe 'CRHelper Unit Tests' {
    BeforeAll {
    }

    InModuleScope 'CRHelper' {

        Describe 'Test_IsNanoServer' {

            [CRHelper]::ResetFuncsToNormal()
            $testComputerInfoNanoServer = [Microsoft.PowerShell.Commands.ComputerInfo]::new()
            $testComputerInfoNanoServer.OsProductType = [Microsoft.PowerShell.Commands.ProductType]::Server
            $testComputerInfoNanoServer.OsServerLevel = [Microsoft.PowerShell.Commands.ServerLevel]::NanoServer

            $testComputerInfoServerNotNano = [Microsoft.PowerShell.Commands.ComputerInfo]::new()
            $testComputerInfoServerNotNano.OsProductType = [Microsoft.PowerShell.Commands.ProductType]::Server
            $testComputerInfoServerNotNano.OsServerLevel = [Microsoft.PowerShell.Commands.ServerLevel]::FullServer

            $testComputerInfoNotServer = [Microsoft.PowerShell.Commands.ComputerInfo]::new()
            $testComputerInfoNotServer.OsProductType = [Microsoft.PowerShell.Commands.ProductType]::WorkStation
            $testComputerInfoNotServer.OsServerLevel = [Microsoft.PowerShell.Commands.ServerLevel]::Unknown

            Context 'Get-ComputerInfo command exists and succeeds' {
                
                Context 'Computer OS type is Server and OS server level is NanoServer' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoNanoServer }

                    It 'Should not throw' {
                        { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                    }

                    It 'Should return true' {
                        [CRHelper]::IsNanoServer | Should Be $true
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
                            [CRHelper]::GetComputerInfoFunc | Should Not Be $null
                        }

                        It 'TestCommandExistsFunc Should be null' {
                            [CRHelper]::TestCommandExistsFunc | Should Be $null
                        }

                        It 'TestIsNanoServerFunc Should be null' {
                            [CRHelper]::TestIsNanoServerFunc | Should Be $null
                        }
                    }
                }

                Context 'Computer OS type is Server and OS server level is not NanoServer' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoServerNotNano }
                    
                    It 'Should not throw' {
                        { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                    }

                    It 'Should return false' {
                        [CRHelper]::IsNanoServer | Should Be $false
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
                            [CRHelper]::GetComputerInfoFunc | Should Not Be $null
                        }

                        It 'TestCommandExistsFunc Should be null' {
                            [CRHelper]::TestCommandExistsFunc | Should Be $null
                        }

                        It 'TestIsNanoServerFunc Should be null' {
                            [CRHelper]::TestIsNanoServerFunc | Should Be $null
                        }
                    }
                }

                Context 'Computer OS type is not Server' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoNotServer }

                    It 'Should not throw' {
                        { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                    }

                    It 'Should return false' {
                        [CRHelper]::IsNanoServer | Should Be $false
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
                            [CRHelper]::GetComputerInfoFunc | Should Not Be $null
                        }

                        It 'TestCommandExistsFunc Should be null' {
                            [CRHelper]::TestCommandExistsFunc | Should Be $null
                        }

                        It 'TestIsNanoServerFunc Should be null' {
                            [CRHelper]::TestIsNanoServerFunc | Should Be $null
                        }
                    }                    
                }
            }

            Context 'Get-ComputerInfo command exists but throws an error and returns null' {

                [CRHelper]::ResetFuncsToNormal()
                [CRHelper]::GetComputerInfoFunc = { return $null }

                It 'Should not throw' {
                    { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                }

                It 'Should return false' {
                    [CRHelper]::IsNanoServer | Should Be $false
                }

                Context 'Only Get_ComputerInfo has been "Mocked"' {
                    
                    It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
                        [CRHelper]::GetComputerInfoFunc | Should Not Be $null
                    }
                    
                    It 'TestCommandExistsFunc Should be null' {
                        [CRHelper]::TestCommandExistsFunc | Should Be $null
                    }
                    
                    It 'TestIsNanoServerFunc Should be null' {
                        [CRHelper]::TestIsNanoServerFunc | Should Be $null
                    }
                }                                        
            }

            Context 'Get-ComputerInfo command does not exist' {
                [CRHelper]::ResetFuncsToNormal()
                [CRHelper]::TestCommandExistsFunc = { return $false }

                It 'Should not throw' {
                    { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                }

                It 'Should return false' {
                    [CRHelper]::IsNanoServer | Should Be $false
                }

                Context 'Only Test_CommandExists has been "Mocked"' {
                    
                    It 'GetComputerInfoFunc Should be null' {
                        [CRHelper]::GetComputerInfoFunc | Should Be $null
                    }
                    
                    It 'TestCommandExistsFunc Should NOT be null (It has been mocked' {
                        [CRHelper]::TestCommandExistsFunc | Should Not Be $null
                    }
                    
                    It 'TestIsNanoServerFunc Should be null' {
                        [CRHelper]::TestIsNanoServerFunc | Should Be $null
                    }
                }        
                [CRHelerp]::ResetFuncsToNormal()                                
            }
        }

        Describe 'Test_CommandExists' {

            $testCommandName = 'TestCommandName'
            [CRHelper]::ResetFuncsToNormal()

            Mock -CommandName 'Get-Command' -MockWith { return $Name }

            Context 'Get-Command returns the command' {

                It 'Should not throw' {
                    { $null = [CRHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
                }

                It 'Should retrieve the command with the specified name' {
                    $getCommandParameterFilter = {
                        return $Name -eq $testCommandName
                    }

                    Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context'
                }

                It 'Should return true' {
                    [CRHelper]::Test_CommandExists($testCommandName) | Should Be $true
                }
            }

            Context 'Get-Command returns null' {
                Mock -CommandName 'Get-Command' -MockWith { return $null }

                It 'Should not throw' {
                    { $null = [CRHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
                }

                It 'Should retrieve the command with the specified name' {
                    $getCommandParameterFilter = {
                        return $Name -eq $testCommandName
                    }

                    Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context'
                }

                It 'Should return false' {
                    [CRHelper]::Test_CommandExists($testCommandName) | Should Be $false
                }
            }
        }
    }
}
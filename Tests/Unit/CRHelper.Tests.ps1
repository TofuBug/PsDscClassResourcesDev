using namespace Microsoft.PowerShell.Commands
#using module "C:\Users\tofub_000\classtests.psm1"
using module ..\..\DscResources\CRHelper.psm1

$errorActionPreference = 'Stop'
Set-StrictMode -Version 'Latest'

Describe 'CRHelper Unit Tests' {
    BeforeAll {
    }

<<<<<<< HEAD
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
=======
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
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63

            Context 'Get-ComputerInfo command exists and succeeds' {
                
                Context 'Computer OS type is Server and OS server level is NanoServer' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoNanoServer }

                    It 'Should not throw' {
                        { 
                            $null = [CRHelper]::Test_IsNanoServer() 
                        } | Should Not Throw
                    }

                    It 'Should return true' {
                        [CRHelper]::Test_IsNanoServer() | Should Be $true
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

<<<<<<< HEAD
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
=======
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
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
<<<<<<< HEAD

                Context 'Computer OS type is Server and OS server level is not NanoServer' {

=======

                Context 'Computer OS type is Server and OS server level is not NanoServer' {

>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoServerNotNano }
                    
                    It 'Should not throw' {
                        { $null = [CRHelper]::IsNanoServer } | Should Not Throw
                    }

                    It 'Should return false' {
                        [CRHelper]::Test_IsNanoServer()  | Should Be $false
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

<<<<<<< HEAD
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
=======
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
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
<<<<<<< HEAD

                Context 'Computer OS type is not Server' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoNotServer }

                    It 'Should not throw' {
                        { $null = [CRHelper]::Test_IsNanoServer() } | Should Not Throw
=======

                Context 'Computer OS type is not Server' {

                    [CRHelper]::GetComputerInfoFunc = { return $testComputerInfoNotServer }

                    It 'Should not throw' {
                        { $null = [CRHelper]::IsNanoServer } | Should Not Throw
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
                    }

                    It 'Should return false' {
                        [CRHelper]::Test_IsNanoServer() | Should Be $false
                    }

                    Context 'Only Get_ComputerInfo has been "Mocked"' {

<<<<<<< HEAD
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked)' {
=======
                        It 'GetComputerInfoFunc Should NOT be null (It has been mocked' {
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
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
<<<<<<< HEAD
                [CRHelper]::ResetFuncsToNormal()                                
=======
                [CRHelerp]::ResetFuncsToNormal()                                
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
            }
        }

        Describe 'Test_CommandExists' {

            $testCommandName = 'TestCommandName'
            [CRHelper]::ResetFuncsToNormal()

            Mock -CommandName 'Get-Command' -MockWith { return $Name } -ModuleName CRHelper

            Context 'Get-Command returns the command' {

                It 'Should not throw' {
                    { $null = [CRHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
                }

                It 'Should retrieve the command with the specified name' {
                    $getCommandParameterFilter = {
                        return $Name -eq $testCommandName
                    }

                    Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context' -ModuleName CRHelper
                }

                It 'Should return true' {
                    [CRHelper]::Test_CommandExists($testCommandName) | Should Be $true
                }
            }

            Context 'Get-Command returns null' {
                Mock -CommandName 'Get-Command' -MockWith { return $null } -ModuleName CRHelper

                It 'Should not throw' {
                    { $null = [CRHelper]::Test_CommandExists($testCommandName) } | Should Not Throw
                }

                It 'Should retrieve the command with the specified name' {
                    $getCommandParameterFilter = {
                        return $Name -eq $testCommandName
                    }

                    Assert-MockCalled -CommandName 'Get-Command' -ParameterFilter $getCommandParameterFilter -Exactly 1 -Scope 'Context' -ModuleName CRHelper
                }

                It 'Should return false' {
                    [CRHelper]::Test_CommandExists($testCommandName) | Should Be $false
                }
            }
        }
<<<<<<< HEAD
=======
    }
>>>>>>> 2948b9ccfc7bbee75c290c5baa572f54a7fefb63
}
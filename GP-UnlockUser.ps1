#Requires -Version 3.0

<#
###
the purpose of this PowerShell scripting tool is to provide an easy way for Dynamics GP admins to unlock user accounts
without having to go through all the manual steps of resetting their passwords in SQL, unlocking them in SQL, logging
into GP and resetting their passwords, etc..

the tool runs under the context of the user that is launching the script, so that user will need suitable permissions 
on the SQL instance being accessed. It's a simple tool, it can probably be improved a lot or refined. hope that someone 
may find that it saves them some time and is useful. 


###
Copyright (c) 2015 Greg Besso

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

#
# global variables that may be used throughout this tool...
#
# replace this with your own logo, it can be a UNC path or URL...
$global:logoURL = 'https://bodostorage1.blob.core.windows.net/wordpress/logo_microsoft_dynamics.jpg'
$global:gpServerName = 'YourGPServerName'
$global:gpSQLInstance = 'YourGPServerName\YourSQLInstanceNameIfAny'


# this function returns any locked SQL logins that might exist...
function Get-GPLockedUsers() {
<# 
.SYNOPSIS 
Queries SQL to get a list of any locked user accounts
.DESCRIPTION 
Queries sys.sql_logins to get a list of user accounts with LOGINPROPERTY isLocked set to TRUE, returning the list to a variable
.PARAMETER Server
The netbios hostname, fully qualified name, or IP address of the Windows server that is hosting the SQL instance.
.PARAMETER ServerInstance
The name of the actual SQL instance being accessed, such as SERVER1 or SERVER1\GPInstance
.EXAMPLE 
Get-GPLockedUsers -Server 'GPSERVER01' -ServerInstance 'GPSERVER01\GPSQL'
#>
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Server,
        [string]$ServerInstance      
    )

    Try {
        #create a new session and load the SharePoint plugins...
        $sessionGP = New-PSSession -ComputerName $Server
        $getLockedUsers = Invoke-Command -Session $sessionGP -ScriptBlock {
            # get input from function calling remote session
            Param ($ServerInstance)

            Add-PSSnapin SqlServerCmdletSnapin100
            Add-PSSnapin SqlServerProviderSnapin100

            $getLockedUsers = Invoke-Sqlcmd -Query "SELECT name FROM sys.sql_logins WHERE LOGINPROPERTY(name, N'isLocked') = 1 ORDER BY name;" -ServerInstance "$ServerInstance"
            $getLockedUsers
        } -ArgumentList $ServerInstance
        $sessionGP | Remove-PSSession

        #give output
        Return $getLockedUsers
    } Catch {
        Return $_.Exception.Message
    }
}

# this function unlocks the chosen SQL login...
function Set-GPUnlockUser() {
<# 
.SYNOPSIS 
Unlocks an existing SQL login on the SQL instance.
.DESCRIPTION 
Alters a SQL login to turn off password policy, then turns it back on to effectively unlock a login without having to change the password.
.PARAMETER Server
The netbios hostname, fully qualified name, or IP address of the Windows server that is hosting the SQL instance.
.PARAMETER ServerInstance
The name of the actual SQL instance being accessed, such as SERVER1 or SERVER1\GPInstance
.PARAMETER GPUser
The name of the SQL login that needs to be unlocked.
.EXAMPLE 
Set-GPLockedUser -Server 'GPSERVER01' -ServerInstance 'GPSERVER01\GPSQL' -GPUser 'gregb'
#>
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string]$Server,
        [string]$ServerInstance,
        [string]$GPUser      
    )

    Try {
        #create a new session and load the SharePoint plugins...
        $sessionGP = New-PSSession -ComputerName $Server
        $unlockUser = Invoke-Command -Session $sessionGP -ScriptBlock {
            # get input from function calling remote session
            Param ($ServerInstance, $GPUser)

            Add-PSSnapin SqlServerCmdletSnapin100
            Add-PSSnapin SqlServerProviderSnapin100

            $unlockUser = Invoke-Sqlcmd -Query "ALTER LOGIN $GPUser WITH CHECK_POLICY = OFF;" -ServerInstance "$ServerInstance"
            $unlockUser = Invoke-Sqlcmd -Query "ALTER LOGIN $GPUser WITH CHECK_POLICY = ON, CHECK_EXPIRATION = ON;" -ServerInstance "$ServerInstance"
            $unlockUser
        } -ArgumentList $ServerInstance, $GPUser
        $sessionGP | Remove-PSSession

        #give output
        Return $unlockUser
    } Catch {
        Return $_.Exception.Message
    }
}

# this function brings up a GUI form for selecting and unlocking SQL logins...
function Get-EnableDisableUserForm() {
<# 
.SYNOPSIS 
This is just a function that creates the GUI form to allow an admin to check for, and unlock SQL accounts if needed.
.DESCRIPTION 
The form gets created, the server is checked for locked users, and the form is then ready to be used to unlock user(s). 
.EXAMPLE 
Get-EnableDisableUserForm
#>
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

    $objForm = New-Object System.Windows.Forms.Form 
    $objForm.Text = "Dynamics GP User Unlock Tool"
    $objForm.AutoSize = $True
    $objForm.StartPosition = "CenterScreen"
    $objForm.BackColor = "#333333"
    $objForm.ForeColor = "#ffffff"
    $Font = New-Object System.Drawing.Font("Lucida Sans Console",10,[System.Drawing.FontStyle]::Regular)
    $objForm.Font = $Font
    $itemY = 0

    $objForm.KeyPreview = $True
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") {$x=$objTextBox.Text;$objForm.Close()}})
    $objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") {$objForm.Close()}})

    # add an image
    $pictureBox = new-object Windows.Forms.PictureBox
    $pictureBox.Width =  231
    $pictureBox.Height =  60
    $pictureBox.ImageLocation = $global:logoURL
    $pictureBox.Location = New-Object Drawing.Point 10,10
    $objForm.controls.add($pictureBox)

    # add the GUI title
    $objLabelTitle = New-Object System.Windows.Forms.Label
    $objLabelTitle.Location = New-Object System.Drawing.Size(250,20) 
    $objLabelTitle.AutoSize = $True 
    $objLabelTitle.Text = "Dynamics GP User Unlock Tool"
    $Font = New-Object System.Drawing.Font("Lucida Sans Console",12,[System.Drawing.FontStyle]::Bold)
    $objLabelTitle.Font = $Font
    $objForm.Controls.Add($objLabelTitle) 


    # user's name information (first, initial, last)
    $objLabelA = New-Object System.Windows.Forms.Label
    $objLabelA.Location = New-Object System.Drawing.Size(10,($itemY+=90)) 
    $objLabelA.AutoSize = $True 
    $objLabelA.Text = "Pick a locked GP user (if any)..."
    $objForm.Controls.Add($objLabelA) 

    # choose an existing user template to clone the user from...
    $DropDownChoice = new-object System.Windows.Forms.ComboBox
    $DropDownChoice.Location = new-object System.Drawing.Size(10,($itemY+=30))
    $DropDownChoice.Size = new-object System.Drawing.Size(230,20)
    

    $getLockedUsers = (Get-GPLockedUsers -Server "$global:gpServerName" -ServerInstance "$global:gpSQLInstance" | Sort-Object Name).Name

    ForEach ($getLockedUser in $getLockedUsers) {
        [void] $DropDownChoice.Items.Add($getLockedUser)
    }

    $objForm.Controls.Add($DropDownChoice)   
    
    # buttons to continue/cancel on the form...
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Size(10,($itemY+=50))
    $OKButton.Size = New-Object System.Drawing.Size(100,23)
    $OKButton.Text = "Proceed"

    $OKButton.Add_Click({
        If (($DropDownChoice.Text.Length -gt 1)) {
            $OKButton.Enabled = $False

            $choice = $DropDownChoice.Text

            $result = Set-GPUnlockUser -Server  "$global:gpServerName" -ServerInstance "$global:gpSQLInstance" -GPUser $choice 
                
            # display the results
            $objLabelResults.Text = "OK the GP user account for $choice has been unlocked."

            $DropDownChoice.Text = ""
            $OKButton.Enabled = $True

        }
    })
    $objForm.Controls.Add($OKButton)

    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = New-Object System.Drawing.Size(($OKButton.Right + 7),($itemY))
    $CancelButton.Size = New-Object System.Drawing.Size(100,23)
    $CancelButton.Text = "Exit"
    $CancelButton.Add_Click({
        #close any sessions that were opened, then close the form...
        Get-PSSession | Remove-PSSession
        $objForm.Close()
    })
    $objForm.Controls.Add($CancelButton)

    # display the results
    $objLabelResults = New-Object System.Windows.Forms.Label
    $objLabelResults.Location = New-Object System.Drawing.Size(10,($itemY+=40)) 
    $objLabelResults.AutoSize = $True 
    $objLabelResults.Text = ""
    $objForm.Controls.Add($objLabelResults) 

    $objForm.Topmost = $True

    $Icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
    $objForm.Icon = $Icon

    $objForm.Add_Shown({$objForm.Activate()})
    [void] $objForm.ShowDialog()
}

# bring up the GUI form that will get the process started...
Get-EnableDisableUserForm
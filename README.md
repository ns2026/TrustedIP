TrustedIP

A simple script to update your trusted IP automatically.

Installation
1. Choose a Location for the Project

Select a directory where the project will be stored.

Example:

C:\Projects\

2. Clone the Repository
Open Command Prompt or PowerShell and run:

C:\Projects\git clone https://github.com/ns2026/TrustedIP.git

This will download the project into:

C:\Projects\TrustedIP

3. Navigate to the Project Folder
cd C:\Projects\TrustedIP

4. This change only applies to the current PowerShell session.
C:\Projects\TrustedIP>Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

5. Run the Script

Execute the script to update your trusted IP:

C:\Projects\TrustedIP>.\scripts\run.ps1


PowerShell Script Execution Error:

Error 1: 
PS C:\DEV\TrustedIP> .\scripts\run.ps1
.\scripts\run.ps1 : File C:\DEV\TrustedIP\scripts\run.ps1 cannot be loaded because running scripts is disabled on this system. For more 
information, see about_Execution_Policies at https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ .\scripts\run.ps1
+ ~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
PS C:\DEV\TrustedIP>

Reason: PowerShell does not allow scripts to run because the execution policy is restricted.

Solution: Run the following command from the project directory:

C:\DEV\TrustedIP> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Then execute the script again: .\scripts\run.ps1


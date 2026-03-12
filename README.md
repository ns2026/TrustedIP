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


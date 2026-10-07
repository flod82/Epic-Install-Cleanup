Epic Games Launcher – Orphaned Installation Cleanup
PowerShell script to remove stale/orphaned local installation records from the Epic Games Launcher when the actual game files are gone or the old installation drive no longer exists.
Important: This tool does not remove games from your Epic Games account/library and does not delete game files. It only removes local installation records that point to paths that no longer exist.

The problem
Epic Games Launcher can continue to show a game as installed after its files have been manually deleted or after an old HDD/SSD has been removed.
Epic stores local installation information in .item manifest files. Epic Online Services can also keep corresponding .egi installation records. Removing only the .item files may not be sufficient: the launcher can recreate them from the remaining Epic Online Services records.
This script removes the two matching local records together:
EpicGamesLauncher\Data\Manifests\<ID>.item
EpicOnlineServicesShared\InstallHelper\InstalledItems\<ID>.egi
Only records whose InstallLocation no longer exists are selected.
Features
- Automatically finds orphaned Epic installations
- Works with different Windows usernames and drive letters
- Handles missing drives such as D: or E:
- Removes matching .item and .egi records
- Creates a timestamped backup before making changes
- Supports a safe -DryRun mode
- Does not delete game files
- Does not modify your Epic account or online library
- Does not remove Epic Online Services core files such as overlay.egi, service.egi, or support.egi
- Works with Windows PowerShell 5.1 and PowerShell 7+

Requirements
- Windows
- Epic Games Launcher installed
- PowerShell 5.1 or newer
- Epic Games Launcher must be completely closed while the script runs
Administrator privileges are normally not required, but Windows may require an elevated PowerShell session depending on local permissions.

Usage
PowerShell execution policy
If Windows reports that script execution is disabled, this is a PowerShell security setting and does not necessarily indicate a problem with the script.
Recommended: run without changing the system policy
You can allow this script to run for this invocation only:
powershell.exe -ExecutionPolicy Bypass -File .\Cleanup-EpicOrphanedInstalls.ps1 -DryRun
After checking the results, run the cleanup with:
powershell.exe -ExecutionPolicy Bypass -File .\Cleanup-EpicOrphanedInstalls.ps1
-ExecutionPolicy Bypass applies to this PowerShell process only. It does not permanently change the system or user execution policy.
Alternative: unblock a downloaded script
Windows may mark files downloaded from the Internet with a security zone identifier. If you trust the source of the script, you can remove that marker with:
Unblock-File .\Cleanup-EpicOrphanedInstalls.ps1
Then run the script normally:
.\Cleanup-EpicOrphanedInstalls.ps1 -DryRun
Do not lower the system-wide PowerShell execution policy just to run this tool.
1. Download the script
Download Cleanup-EpicOrphanedInstalls.ps1 from this repository.
2. Close Epic Games Launcher
Exit Epic Games Launcher completely. Check the Windows system tray and make sure no Epic launcher window is still running.
The script also checks for Epic processes and stops before making changes if they are still running.
3. Recommended: run a dry run first
Open PowerShell in the directory containing the script:
.\Cleanup-EpicOrphanedInstalls.ps1 -DryRun
The command only scans and displays the records that would be removed. Nothing is changed.
4. Run the cleanup
.\Cleanup-EpicOrphanedInstalls.ps1
The script will:
1. Scan the Epic manifests.
2. Find installations whose InstallLocation does not exist.
3. Display the affected games.
4. Ask for confirmation.
5. Create a backup on the Desktop.
6. Remove the matching .item and .egi records.
Start Epic Games Launcher afterwards.
Backup
Before removing anything, the script creates a backup similar to:
Desktop\Epic-Orphaned-Backup\20261007-102530\
├── Manifests\
└── InstalledItems\
The backup contains only the affected .item and .egi files.
If something goes wrong, the files can be copied back while Epic Games Launcher is closed.
Command-line options
Dry run
.\Cleanup-EpicOrphanedInstalls.ps1 -DryRun
Finds orphaned records without changing anything.
Automatic confirmation
.\Cleanup-EpicOrphanedInstalls.ps1 -Force
Skips the final confirmation prompt. A backup is still created.
Disable backup
.\Cleanup-EpicOrphanedInstalls.ps1 -NoBackup
Disables the backup. Not recommended.
PowerShell -WhatIf
The script also supports PowerShell's standard -WhatIf mechanism:
.\Cleanup-EpicOrphanedInstalls.ps1 -WhatIf
For a simple read-only scan, -DryRun is recommended.
Important safety note
A missing installation path does not always mean that the game is permanently gone. For example, the path may belong to:
- a disconnected external HDD/SSD
- a temporarily unavailable network location
- a removable drive
- a drive letter that has changed
Make sure the old installation really is no longer needed before confirming the cleanup.
If you simply disconnected an external drive, reconnect it before running the cleanup.
What this script does NOT do
This script does not:
- delete game installation files
- uninstall games through Epic Games Launcher
- remove games from your Epic account
- remove games from your Epic online library
- modify Epic account data
- remove Epic Online Services itself
- remove overlay.egi, service.egi, or support.egi
It only cleans local records for installations whose configured installation path no longer exists.
Why are both .item and .egi files removed?
Epic Games Launcher uses .item files to store local installation information. Epic Online Services can maintain corresponding .egi records.
If only the .item file is removed, Epic may recreate it when the launcher starts because the corresponding .egi record still exists.
This script therefore uses the shared identifier in the filename and removes both records for the same orphaned installation.
Example
Suppose Epic contains:
Cyberpunk 2077
InstallLocation = E:\Spiele\Cyberpunk2077
but the E: drive no longer exists.
The script can find:
BB272BA84773181AB93511986AED711B.item
BB272BA84773181AB93511986AED711B.egi
It backs them up and removes both local records. The next time Epic starts, Cyberpunk 2077 is no longer treated as locally installed, while it remains available in the user's Epic Games account/library for reinstallation.
Troubleshooting
Epic is still showing the games as installed
Make sure Epic Games Launcher is completely closed before running the script. If the records return after a cleanup, check whether another Epic process or service is recreating them.
Run the dry run again:
.\Cleanup-EpicOrphanedInstalls.ps1 -DryRun
If the same records are found again, open an issue and include the script output. Do not post personal account information or complete paths if they contain sensitive information.
PowerShell says scripts cannot be executed
Windows may block locally downloaded PowerShell scripts. You can inspect the file first and, if you trust the source, unblock it:
Unblock-File .\Cleanup-EpicOrphanedInstalls.ps1
Then run it again.
Access denied
Close Epic Games Launcher completely. If access is still denied, open PowerShell as Administrator and run the script again.
Contributing
Pull requests and issue reports are welcome.
When reporting a problem, please include:
- Windows version
- PowerShell version ($PSVersionTable.PSVersion)
- whether Epic Games Launcher was closed
- the non-sensitive output of -DryRun
Do not upload your Epic account credentials, cookies, authentication tokens, or private game/account data.

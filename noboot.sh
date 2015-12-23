#!/bin/sh

#############################
# Requires 10.10 or higher. #
#############################
#
# Created by Amsys
# Use at your own risk.  Amsys will accept
# no responsibility for loss or damage
# caused by this script.
#
# Modified by Everette_Allen@ncsu.edu 12212015
# Use at your own risk.  NCSU will accept
# no responsibility for loss or damage
# caused by this script.

# Installer sees arg 3 as target volume for install.
# like $3=="/Volumes/Macintosh HD" 
if [ "$3" != "" ];then
    TVOL="$3"
else
    TVOL="/Volumes/Macintosh HD"
fi

#log the path for the target volume for diagnostics
echo $TVOL

###############
## variables ##
###############
##tools
DEFAULTS="$TVOL/usr/bin/defaults"
PLBUDDY="$TVOL/usr/libexec/PlistBuddy"
ARD="$TVOL/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"
DIRADM="$TVOL/usr/bin/dscl" 
PERL="$TVOL/usr/bin/perl"
##files
USER_TEMPLATE="/System/Library/User Template/Non_localized"
## values
BUILDVERSION=$("$TVOL"/usr/bin/sw_vers -buildVersion)
PRODUCTVERSION=$("$TVOL"/usr/bin/sw_vers -productVersion)
SUBMIT_TO_APPLE=NO
SUBMIT_TO_APP_DEVELOPERS=NO

#####################
## Script Commands ##
#####################

# Switch on Apple Remote Desktop early so can authorize at end. Needs some time for some reason.
"$ARD" -configure -activate -targetdisk "$TVOL"
"$ARD" -configure -access -on -targetdisk "$TVOL"
"$ARD" -configure -allowAccessFor -specifiedUsers -targetdisk "$TVOL"


# Set the time zone automatically by location
"$DEFAULTS" write "$TVOL"/Library/Preferences/com.apple.timezone.auto Active -bool true

# Configure a specific NTP server
echo "server time.ncsu.edu" >> /etc/ntp.conf

# Configure energy saver settings
# "$DEFAULTS" write "$TVOL/Library/Preferences/SystemConfiguration/com.apple.PowerManagement"

# Configure energy saver schedule
# "$DEFAULTS" write "$TVOL/Library/Preferences/SystemConfiguration/com.apple.AutoWake"

# Configure Login Window to username and password text fields
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.loginwindow" SHOWFULLNAME 1

# Enable admin info at the Login Window
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.loginwindow" AdminHostInfo HostName

# Disable External Accounts at the Login Window
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.loginwindow EnableExternalAccounts" 0

# Stop automatic updates
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.commerce" AutoUpdate -bool false
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.commerce" AutoUpdateRestartRequired -bool false
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.SoftwareUpdate" AutomaticCheckEnabled -bool false

# Disable iCloud for new users at login
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" DidSeeCloudSetup -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" DidSeeiCloudSecuritySetup -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" GestureMovieSeen none
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" LastSeenCloudProductVersion "$PRODUCTVERSION"
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" LastSeenBuddyBuildVersion "$BUILDVERSION"
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" RunNonInteractive -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" SkipFirstLoginOptimization -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" DidSeeCloudSetup -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup -bool true
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/com.apple.SetupAssistant" DidSeeSyncSetup2 -bool true


# Disable diagnostics at login
CRASHREPORTER_SUPPORT="$TVOL/Library/Application Support/CrashReporter"
CRASHREPORTER_DIAG_PLIST="$CRASHREPORTER_SUPPORT/DiagnosticMessagesHistory.plist"
 
if [ ! -d "$CRASHREPORTER_SUPPORT" ]; then
     mkdir "$CRASHREPORTER_SUPPORT"
     chmod 775 "$CRASHREPORTER_SUPPORT"
     chown root:admin "$CRASHREPORTER_SUPPORT"
fi
 
for key in AutoSubmit AutoSubmitVersion ThirdPartyDataSubmit ThirdPartyDataSubmitVersion; do
    "$PLBUDDY" -c "Delete :$key" "$CRASHREPORTER_DIAG_PLIST" 2> /dev/null
done
 
"$PLBUDDY" -c "Add :AutoSubmit bool $SUBMIT_TO_APPLE" "$CRASHREPORTER_DIAG_PLIST"
"$PLBUDDY" -c "Add :AutoSubmitVersion integer 4" "$CRASHREPORTER_DIAG_PLIST"
"$PLBUDDY" -c "Add :ThirdPartyDataSubmit bool $SUBMIT_TO_APP_DEVELOPERS" "$CRASHREPORTER_DIAG_PLIST"
"$PLBUDDY" -c "Add :ThirdPartyDataSubmitVersion integer 4" "$CRASHREPORTER_DIAG_PLIST"

# Disable Time Machine Popups offering for new disks
"$DEFAULTS" write "$TVOL"/Library/Preferences/com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Turn off restore windows
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/.GlobalPreferences" NSQuitAlwaysKeepsWindows -bool false

# Stop writing .DS_Store files on the network
"$DEFAULTS" write "$TVOL/$USER_TEMPLATE/Library/Preferences/.GlobalPreferences" DSDontWriteNetworkStores -bool true

# Create a local sign user account
SUSER="sign"
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER UserShell /bin/bash
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER RealName $SUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER UniqueID 505
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER PrimaryGroupID 20
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$SUSER NFSHomeDirectory "$TVOL"/Users/$SUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -passwd /Local/Target/Users/$SUSER "$SUSER"
# "$TVOL"/usr/sbin/createhomedir -l -i $SUSER

# Create a local kiosk user account 
KUSER="kiosk"
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER UserShell /bin/bash
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER RealName $KUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER UniqueID 504
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER PrimaryGroupID 20
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$KUSER NFSHomeDirectory "$TVOL"/Users/$KUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -passwd /Local/Target/Users/$KUSER "$KUSER"
# "$TVOL"/usr/sbin/createhomedir -l -i $KUSER

# Enable Auto-Login in security settings
"$DEFAULTS" write "$TVOL/Library/Preferences/.GlobalPreferences" com.apple.userspref.DisableAutoLogin 0

#setup auto-login of kiosk user
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.loginwindow" autoLoginUser kiosk
"$DEFAULTS" write "$TVOL/Library/Preferences/com.apple.loginwindow" autoLoginUserUID 504
"$PERL" -e 'print pack "H*", "16e03d50b9bcba2ccaca4e82"' >"$TVOL/etc/kcpassword"

# Create a local account with randomized password
APASSWORD=$("$TVOL"/usr/bin/jot -r -s. -c 16 a z)
AUSER="localadmin"
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER UserShell /bin/bash
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER RealName $AUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER UniqueID 449
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER PrimaryGroupID 20
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -create /Local/Target/Users/$AUSER NFSHomeDirectory /Users/$AUSER
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -passwd /Local/Target/Users/$AUSER "$APASSWORD"
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/admin GroupMembership $AUSER
GENUID=$("$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -read /Local/Target/Users/$AUSER GeneratedUID)
"$DIRADM" -f "$TVOL/var/db/dslocal/nodes/Default" localonly -append /Local/Target/Groups/admin GroupMembers $GENUID 
# "$TVOL"/usr/sbin/createhomedir -l -i $AUSER

# keep the setup assistant from appearing at reboot
"$TVOL"/usr/bin/touch "$TVOL"/var/db/.AppleSetupDone

# Configure ARD access for the local user
echo "sleeping..."
sleep 10
"$ARD" -configure -access -on -users "$AUSER" -privs -all -targetdisk "$TVOL"

exit 0

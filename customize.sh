##########################################################################################
#
# MMT Extended Config Script
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maximum android version for your mod
# Uncomment DYNLIB if you want libs installed to vendor for oreo+ and system for anything older
# Uncomment PARTOVER if you have a workaround in place for extra partitions in regular magisk install (can mount them yourself - you will need to do this each boot as well). If unsure, keep commented
# Uncomment PARTITIONS and list additional partitions you will be modifying (other than system and vendor), for example: PARTITIONS="/odm /product /system_ext"
#MINAPI=21
#MAXAPI=25
#DYNLIB=true
#PARTOVER=true
#PARTITIONS=""

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
# Permissions
##########################################################################################

FONT_DIR=$MODPATH/system/fonts
DEF_EMOJI="NotoColorEmoji.ttf"


# Replace faceook & messnger emojis
fb_msg_emoji() {
    DATA_DIR="/data/data/"
    EMOJI_DIR="app_ras_blobs"
    TTF_NAME="FacebookEmoji.ttf"
    apps='com.facebook.orca com.facebook.katana'
    for i in $apps ; do  # NOTE: do not double-quote $services here.
        if [ -d "$DATA_DIR$i" ]; then
            cd $DATA_DIR$i
            if [ ! -d "$EMOJI_DIR" ]; then
                mkdir $EMOJI_DIR
            fi
            cd $EMOJI_DIR
            
            APP_NAME="Facebook"
            if [[ $i == *"orca"* ]]; then
                APP_NAME="Messenger"
            fi
            
            # Change
            if cp $FONT_DIR/$DEF_EMOJI ./$TTF_NAME; then
                TTF_PATH="${DATA_DIR}${i}/${EMOJI_DIR}/${TTF_NAME}"
                set_perm_recursive $TTF_PATH 0 0 0755 700
                ui_print "- Replacing $APP_NAME Emojis ✅"
            else
                ui_print "- Replacing $APP_NAME Emojis ❎"
            fi
        fi
    done
}

# Replace System Emoji
system_emoji(){
    ui_print "- Replacing $DEF_EMOJI ✅"
    emojis='SamsungColorEmoji.ttf AndroidEmoji-htc.ttf ColorUniEmoji.ttf DcmColorEmoji.ttf CombinedColorEmoji.ttf'
    for i in $emojis ; do
        if [ -f "/system/fonts/$i" ]; then
            cp $FONT_DIR/$DEF_EMOJI $FONT_DIR/$i && ui_print "- Replacing $i ✅" || ui_print "- Replacing $i ❎"
        fi
    done
}

# Android 12
android12(){
    android_ver=$(getprop ro.build.version.sdk)
    if [ $android_ver -ge 31 ]; then
        DATA_FONT_DIR="/data/fonts/files"
        if [ -d "$DATA_FONT_DIR" ] && [ "$(ls -A $DATA_FONT_DIR)" ]; then
            ui_print ""
            ui_print " ℹ️ Android 12 ✅"
            ui_print "******************"
            ui_print "- Checking [$DATA_FONT_DIR] ✅"
            for dir in $DATA_FONT_DIR/*/ ; do
                cd $dir
                for file in * ; do
                    if [ "$file" == *ttf ] ; then
                        cp $FONT_DIR/$DEF_EMOJI $file && ui_print "- Replacing $file ✅" || ui_print "- Replacing $file ❎"
                    fi
                done
            done
        fi
    fi
}

system_emoji
fb_msg_emoji
android12

# check GMS's components state
STATE_GMSF() {
    ui_print '- Checking Components'

    local GMS="com.google.android.gms"
    local GMFP="$GMS.fonts.provider.FontsProvider"
    local GMFS="$GMS.fonts.update.UpdateSchedulerService"

    local DCL="disabledComponents:"
    local ECL="enabledComponents:"
    local HSP="Hidden[[:space:]]system[[:space:]]packages:"

    local DATA="dumpsys package $GMS"

    CHECK() { $DATA | sed -n "/$1/,/$2/{/$3/p}" | xargs; }

    for g in $GMFP $GMFS; do
        case $g in
            $(CHECK $DCL $ECL $g))
                case $g in
                    $GMFP) ui_print "  Provider: Disabled" ;;
                    $GMFS) ui_print "  Service: Disabled" ;;
                esac
                ;;
            $(CHECK $ECL $HSP $g))
                case $g in
                    $GMFP) ui_print "  Provider: Enabled" ;;
                    $GMFS) ui_print "  Service: Enabled" ;;
                esac
                ;;
        esac
    done
    ui_print ''
}

# Find GMS' generated fonts
FIND_GMSF() {
    ui_print '- Finding GMS Fonts'
    local GMSFD=com.google.android.gms/files/fonts

    for d in /data/fonts \
        /data/data/$GMSFD \
        /data/user/*/$GMSFD; do
        [ -d $d ] &&
            ui_print "  Found: $d"
    done
    ui_print '  Done'
    ui_print ''
}

# cleanup $MODPATH
CLEANUP() {
    ui_print '- Cleaning up'
    find $MODPATH/* -maxdepth 0 \
        ! -name module.prop \
        ! -name service.sh \
        ! -name uninstall.sh -exec basename {} \; |
        while IFS= read -r CLEAN; do
            rm -f $MODPATH/$CLEAN
            ui_print "  Removed: $CLEAN"
        done
    ui_print '  Done'
    ui_print ''
}

# run functions
STATE_GMSF; FIND_GMSF; CLEANUP; SET_PERM

set_permissions() {
    ui_print '- Setting permissions'
    find $MODPATH/* -maxdepth 0 \
        -exec basename {} \; |
        while IFS= read -r PERM; do
            set_perm $MODPATH/$PERM 0 0 0777 u:object_r:system_file:s0
            ui_print "  Granted: $PERM"
        done
   
  : # Remove this if adding to this function

  # Note that all files/folders in magisk module directory have the $MODPATH prefix - keep this prefix on all of your files/folders
  # Some examples:
  
  # For directories (includes files in them):
  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
   set_perm_recursive $MODPATH/system/lib 0 0 0755 0644
  
  # set_perm_recursive $MODPATH/system/vendor/lib/soundfx 0 0 0755 0644

  # For files (not in directories taken care of above)
  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
   set_perm $MODPATH/system/product/overlay/pill.apk 0 0 0644
  # set_perm /data/local/tmp/file.txt 0 0 644
}

##########################################################################################
# MMT Extended Logic - Don't modify anything after this
##########################################################################################

SKIPUNZIP=1
unzip -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
. $TMPDIR/functions.sh

. ${SH:=$MODPATH/ohmyfont}

### INSTALLATION ###

ui_print '+ Prepare'
prep

ui_print '+ Configure'
config

ui_print '+ Font'
install_font

src

ui_print '+ Rom'
rom

ui_print '- Finalizing'
fontspoof
svc
finish
ui_print '  Done'
ui_print ''
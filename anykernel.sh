# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Flash Kernel for the Pixel (XL) by @nathanchance
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=marlin
device.name2=sailfish
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


# Detect whether we're in recovery or booted up
ps | grep zygote | grep -v grep >/dev/null && in_recovery=false || in_recovery=true;
! $in_recovery || ps -A 2>/dev/null | grep zygote | grep -v grep >/dev/null && in_recovery=false;
! $in_recovery || id | grep -q 'uid=0' || in_recovery=false;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


## AnyKernel install
split_boot;


# Mount system to get some information about the user's setup
if $in_recovery; then
  umount /system;
  umount /system 2>/dev/null;
  mkdir /system_root 2>/dev/null;
  mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root;
  mount -o bind /system_root/system /system;
fi;


# Warn user of their support status
android_version="$(file_getprop /system/build.prop "ro.build.version.release")";
security_patch="$(file_getprop /system/build.prop "ro.build.version.security_patch")";
version_info="$android_version:$security_patch";
case "$version_info" in
    "8.1.0:2018-06-05"|"9:2018-06-05") support_status="a supported";;
    *) support_status="an unsupported";;
esac;
ui_print " "; ui_print "You are on $android_version with the $security_patch security patch level! This is $support_status configuration..."


# Patch dtbo on custom ROMs
hostname="$(file_getprop /system/build.prop "ro.build.host")"
case "$hostname" in
    *corp.google.com|abfarm*) host=google;;
    *) host=custom;;
esac
if [ "$(file_getprop /system/build.prop "ro.build.user")" != "android-build" -o "$host" == "custom" ]; then
  ui_print " "; ui_print "You are on a custom ROM, patching dtb to remove verity...";
  if $in_recovery; then
    # Temporarily block out all custom recovery binaries/libs
    mv /sbin /sbin_tmp;
    # Unset library paths
    OLD_LD_LIB=$LD_LIBRARY_PATH;
    OLD_LD_PRE=$LD_PRELOAD;
    unset LD_LIBRARY_PATH;
    unset LD_PRELOAD;
  fi;
  $bin/magiskboot --dtb-patch /tmp/anykernel/Image.lz4-dtb;
  if $in_recovery; then
    mv /sbin_tmp /sbin 2>/dev/null;
    [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB;
    [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE;
  fi;
else
  ui_print " "; ui_print "You are on stock, not patching dtb to remove verity!";
fi;


# Unmount system
if $in_recovery; then
  umount /system;
  umount /system_root;
  rmdir /system_root;
  mount -o ro -t auto /system;
fi;


# Install the boot image
flash_boot;


## end install


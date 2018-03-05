# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() {
kernel.string=Flash Kernel for the Pixel 2 and Pixel 2 XL by @nathanchance
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=taimen
device.name2=walleye
device.name3=
device.name4=
device.name5=
} # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chown -R root:root $ramdisk/*;


# system_getprop <prop>
system_getprop() { grep "^$1=" /system/build.prop | cut -d= -f2; }


## AnyKernel install
split_boot;


# Mount system to get some information about the user's setup
umount /system;
umount /system 2>/dev/null;
mkdir /system_root 2>/dev/null;
mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root;
mount -o bind /system_root/system /system;


# Warn user of their support status
android_version="$(system_getprop "ro.build.version.release")";
security_patch="$(system_getprop "ro.build.version.security_patch")";
version_info="$android_version:$security_patch";
case "$version_info" in
    "8.1.0:2018-03-05") support_status="a supported";;
    *) support_status="an unsupported";;
esac;
ui_print " "; ui_print "You are on $android_version with the $security_patch security patch level! This is $support_status configuration..."


# Patch dtbo on custom ROMs
if [ "$(system_getprop "ro.build.user")" != "android-build" ]; then
  if [ ! -z /tmp/anykernel/dtbo ]; then
    ui_print " "; ui_print "You are on a custom ROM, patching dtbo to remove verity...";
    $bin/magiskboot --dtb-patch /tmp/anykernel/dtbo;
  fi;
else
  ui_print " "; ui_print "You are on stock, not patching dtbo to remove verity!";
fi;


# Unmount system
umount /system;
umount /system_root;
rmdir /system_root;
mount -o ro -t auto /system;


# Install the boot image
flash_boot;


## end install


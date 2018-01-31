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


if [ -f /tmp/anykernel/version ]; then
  ui_print " ";
  ui_print "Kernel version: $(cat /tmp/anykernel/version)";
fi;

## AnyKernel install
dump_boot;

# begin ramdisk changes

# end ramdisk changes

# Mount system to check if the user is on stock
umount /system;
umount /system 2>/dev/null;
mkdir /system_root 2>/dev/null;
mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root;
mount -o bind /system_root/system /system;

# Patch dtbo on custom ROMs
if [ "$(grep "^ro.build.user=" /system/build.prop | cut -d= -f2)" != "android-build" ]; then
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

# Write the images
write_boot;

## end install


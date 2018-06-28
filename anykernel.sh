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


# Unmount system and restore /sbin and library paths
restore_recovery() {
  if $in_recovery; then
    mv /sbin_tmp /sbin 2>/dev/null;
    [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB;
    [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE;
    umount /system;
    umount /system_root;
    rmdir /system_root;
    mount -o ro -t auto /system;
  fi;
}


# Do recovery restore, print message, and exit
die() {
  restore_recovery;
  ui_print " "; ui_print "$*";
  exit 1;
}


## AnyKernel install
dump_boot;


# Find image setup
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.lz4
if [ -f $compressed_image ]; then
  concatenated_image=false;
else
  concatenated_image=true;
fi;


# Mount system to get some information about the user's setup
if $in_recovery; then
  umount /system;
  umount /system 2>/dev/null;
  mkdir /system_root 2>/dev/null;
  mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root;
  mount -o bind /system_root/system /system;
  # Temporarily block out all custom recovery binaries/libs
  mv /sbin /sbin_tmp;
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH;
  OLD_LD_PRE=$LD_PRELOAD;
  unset LD_LIBRARY_PATH;
  unset LD_PRELOAD;
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


# If the user does not supply a concatenated image
if ! $concatenated_image; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot --decompress $compressed_image $decompressed_image;
    $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D6673 77616E745F696E697472616D6673;
    $bin/magiskboot --compress=lz4 $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.lz4-dtb;
fi;


# Patch dtbo on custom ROMs
hostname="$(file_getprop /system/build.prop "ro.build.host")"
case "$hostname" in
    *corp.google.com|abfarm*) host=google;;
    *) host=custom;;
esac
if [ "$(file_getprop /system/build.prop "ro.build.user")" != "android-build" -o "$host" == "custom" ]; then
  ui_print " "; ui_print "You are on a custom ROM, patching dtb to remove verity...";
  $bin/magiskboot --dtb-patch /tmp/anykernel/Image.lz4-dtb;
else
  ui_print " "; ui_print "You are on stock, not patching dtb to remove verity!";
fi;


# Restore recovery if applicable
restore_recovery;


# Install the boot image
write_boot;

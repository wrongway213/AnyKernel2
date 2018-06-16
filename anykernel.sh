# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Flash Kernel for the OnePlus 6 by @nathanchance
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=OnePlus6
device.name2=enchilada
device.name3=
device.name4=
device.name5=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel install
dump_boot;


# Add skip_override parameter to cmdline so user doesn't have to reflash Magisk
if [ -d $ramdisk/.backup ]; then
  ui_print " "; ui_print "Magisk detected! Patching cmdline so reflashing Magisk is not necessary...";
  patch_cmdline "skip_override" "skip_override";
else
  patch_cmdline "skip_override" "";
fi;


write_boot;

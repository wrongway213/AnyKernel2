# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() {
kernel.string=Flash Kernel by @nathanchance
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=angler
device.name2=Angler
device.name3=
device.name4=
device.name5=
} # end properties

# shell variables
block=/dev/block/platform/soc.0/f9824900.sdhci/by-name/boot;
is_slot_device=0;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel permissions
# set permissions for included ramdisk files
chmod -R 755 $ramdisk


## Alert of unsupported Android version
android_ver=$(mount /system; grep "^ro.build.version.release" /system/build.prop | cut -d= -f2; umount /system);
case "$android_ver" in
  "7.0"|"7.1"|"7.1.1"|"7.1.2") compatibility_string="your version is unsupported, expect no support!";;
  "8.0.0") compatibility_string="your version is supported!";;
esac;
ui_print "Running Android $android_ver, $compatibility_string";


## AnyKernel install
dump_boot;

# begin ramdisk changes

# init.flash.rc
insert_line init.angler.rc "init.flash.rc" after "import init.angler.sensorhub.rc" "import init.flash.rc";

# end ramdisk changes

write_boot;

## end install


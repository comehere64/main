#!/system/bin/sh

SKIPUNZIP=1
ADPDEDT_PATH=/data/adb/ADPDEDT

if [ "$BOOTMODE" ] && [ "$KSU" ]; then
  ui_print "***************************************************"
  ui_print " "
  ui_print "- Installing from KernelSU app"
  ui_print "- KernelSU version: $KSU_KERNEL_VER_CODE (kernel) + $KSU_VER_CODE (ksud)"
  ui_print " "
  if [ "$(which magisk)" ]; then
    ui_print "***************************************************"
    ui_print "! Multiple root implementation is NOT supported!"
    ui_print "! Please uninstall Magisk before installing ADPDEDT"
    abort "***************************************************"
  fi
elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
  ui_print "***************************************************"
  ui_print " "
  ui_print "- Installing from Magisk app"
  ui_print "- Magisk version: $MAGISK_VER_CODE"
  ui_print " "
else
  ui_print "***************************************************"
  ui_print "! Install from recovery is not supported"
  ui_print "! Please install from KernelSU or Magisk app"
  abort "***************************************************"
fi

ui_print "***************************************************"
ui_print " "
ui_print "- ADPDEDT version: $(grep_prop version $TMPDIR/module.prop)"
ui_print " "

ui_print "***************************************************"
ui_print " "
ui_print "- unzip"
unzip -o $ZIPFILE -x 'META-INF/*' -d $MODPATH >&2

ui_print "- create work dir"
rm -rf $ADPDEDT_PATH/log
mkdir -p $ADPDEDT_PATH/log

ui_print "- set file permission"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $ADPDEDT_PATH 0 0 0755 0644
set_perm $MODPATH/action.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/delete.sh 0 0 0755
set_perm $MODPATH/uninstall.sh 0 0 0755
set_perm $MODPATH/recovery.sh 0 0 0755
set_perm $MODPATH/test-along.sh 0 0 0755
set_perm $MODPATH/start-delete.sh 0 0 0755
set_perm $MODPATH/start-recovery.sh 0 0 0755
set_perm $MODPATH/turn-off-ADDisjunctor.sh 0 0 0755
set_perm $MODPATH/turn-on-ADDisjunctor.sh 0 0 0755

# 打开 自动清理
mv $MODPATH/auto-delete-disjunctor.txt $ADPDEDT_PATH/auto-delete-disjunctor.txt
ui_print "Automatic cleanup is already enabled by default."
ui_print " "

ui_print "***************************************************"
ui_print " "
ui_print "- installed"
ui_print "- ADPDEDT root: $ADPDEDT_PATH"
ui_print "- welcome to ADPDEDT"
ui_print " "
ui_print "***************************************************"
#!/bin/bash
#
# Auto maker Script for FlymeOS patchrom
# Script Start

x=`date +%Y`
y=`date +.%-m.%-d`
z=${x: -1:1}
time=`date +%c`
utc=`date +%s`
version=$z$y
build_date=`date +%Y%m%d`

source_dir=~/flyme
out_dir=~/flyme/ROM
push_dir=~/FlymeOTA
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"

name="NoDefine"
ARM_64=0

version_tmp=`cat $source_dir/flyme/release/arm/SYSTEM/build.prop |grep "display.id"`
version_name=${version_tmp:25}

if [ "$1" ]; then
	device=$1
else
	device=i9500
fi

function name(){
	if [ "$device" = "i9500" ]; then
		name="S4(i9500)"
	elif [ "$device" = "i9300" ]; then
		name="S3(i9300)"
	elif [ "$device" = "cancro" ]; then
		name="Xiaomi3W&4"
	elif [ "$device" = "jfltexx" ]; then
		name="S4LTE(i9505)"
	elif [ "$device" = "n7100" ]; then
		name="Note2(n7100)"
	elif [ "$device" = "m7" ]; then
		name="One(m7)"
	elif [ "$device" = "m8" ]; then
		name="One(m8)"
	elif [ "$device" = "cancro_aosp" ]; then
		name="Mi3W&4_AOSP"
	elif [ "$device" = "virgo" ]; then
		name="MiNoteLTE"
	elif [ "$device" = "leo" ]; then
		name="MiNotePro"
		ARM_64=1
	elif [ "$device" = "libra" ]; then
		name="Mi4C"
		ARM_64=1
	else
		name="NoDefine"
	fi
}

function init(){
	echo ">>> 正在初始化环境 ...    "
	name
	cd $source_dir
	source build/envsetup.sh >/dev/null
	mkdir -p $out_dir/$version/$name
	rm -rf flyme/release/arm/SYSTEM/app/NfcNci
	echo "<<< 环境初始化完成！     "
}

function arm64(){
	if [ "$ARM_64" = "1" ]; then
		echo ">>> 正在初始化64bit环境 ...    "
		echo "<<< 64bit环境初始化完成！     "
	fi
}

function third(){
	mkdir -p devices/$device/overlay/system/priv-app devices/$device/overlay/data/app devices/$device/overlay/system/supersu
	rm -rf devices/$device/overlay/system/lib64
	rm -rf devices/$device/overlay/data/app/*
	rm -rf devices/$device/overlay/system/priv-app/*
	cp -rf third-app/app/* devices/$device/overlay/data/app
	cp -rf third-app/priv-app/* devices/$device/overlay/system/priv-app/
	cp -rf third-app/supersu/* devices/$device/overlay/system/supersu
	echo "<<< 添加推广完成！   "
	arm64
}

function clean(){
	cd devices/$device
	make clean
	rm -rf history_package last_target
	echo "<<< 缓存文件清理完成！   "
}

function backup(){
	git add -A
	git commit -m "flyme upgrade"
	flyme upgrade
}

function fullota(){
	echo ">>>  开始$J线程制作完整刷机包  ...     "
	sed -i -e "s/ro\.ota\.version=.*/ro\.ota\.version=$build_date/g" Makefile
	time make fullota $THREAD
	if [ "$?" == "0" ]; then
		echo ">>>  完整刷机包制作完成！ "
	else
		echo "[Flyme CUST] OTA: 刷机包生成失败，请检查编译日志！ "
	fi
	if [ $device = "cancro" ]; then
		zip -d out/target_fil*.zip OTA/updater-script
	fi
	mv out/flyme_*.zip $out_dir/$version/$name/full-$device-$version.zip
}

function ota(){
	cd $source_dir/OTA
	mv $device-target-files.zip $device-last-target-files.zip
	mv ../devices/$device/out/target_fil*.zip $device-target-files.zip
	../build/tools/releasetools/ota_from_target_files -k ../build/security/testkey -i $device-last-target-files.zip $device-target-files.zip $out_dir/$version/$name/ota-$device-$version.zip
}

function final(){
	mkdir -p $push_dir/$device/ota/$version
	cp $out_dir/$version/$name/ota-$device-$version.zip $push_dir/$device/ota/$version/ota.zip

}

# Function Start
init
third
clean
backup
fullota
ota
final
# Function End

cd $source_dir
# Script End

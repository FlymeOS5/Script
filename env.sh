#!/bin/bash

#
#Copyright 2016 , Nian
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#

#Set Variable

echo "开始配置系统环境......"
echo "(1/6)安装必要依赖包......"
#Install Package Which Google recommend
sudo apt-get update
sudo apt-get install -y git-core gnupg gcc-multilib g++-multilib \
flex bison gperf libsdl1.2-dev libesd0-dev libwxgtk2.8-dev \
squashfs-tools build-essential zip curl libncurses5-dev \
zlib1g-dev openjdk-6-jre openjdk-6-jdk pngcrush schedtool \
libxml2 libxml2-utils xsltproc lzop libc6-dev schedtool \
lib32z1-dev lib32ncurses5-dev lib32readline-gplv2-dev openjdk-7-jdk \
zip unzip proxychains

echo "(2/6)安装Repo 谢谢Mokee......"
if [ ! -d ~/bin ]; then
  mkdir -p ~/bin
fi
curl http://download.mokeedev.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

echo "(3/6)安装设备驱动......"
wget http://www.broodplank.net/51-android.rules
sudo mv -f 51-android.rules /etc/udev/rules.d/51-android.rules
sudo chmod 644 /etc/udev/rules.d/51-android.rules

echo "(4/6)安装谷歌SDK......"
wget http://dl.google.com/android/adt/adt-bundle-linux-x86_64-20140702.zip
mkdir ~/adt-bundle
mv adt-bundle-linux-x86_64-20140702.zip ~/adt-bundle/adt_x64.zip
cd ~/adt-bundle
unzip adt_x64.zip
mv -f adt-bundle-linux-x86_64-20140702/* .
echo -e '\n# Android tools\nexport PATH=${PATH}:~/adt-bundle/sdk/tools\nexport PATH=${PATH}:~/adt-bundle/sdk/platform-tools\nexport PATH=${PATH}:~/bin' >> ~/.bashrc
echo -e '\nPATH="$HOME/adt-bundle/sdk/tools:$HOME/adt-bundle/sdk/platform-tools:$PATH"' >> ~/.profile

echo "(5/6)应用配置文件......"
source ~/.bashrc
source ~/.profile

echo "(6/6)清除系统垃圾......"
rm -Rf ~/adt-bundle/adt-bundle-linux-x86_64-20140702
rm -f ~/adt-bundle/adt_x64.zip

cd 
echo "完成系统环境配置......"

#Now Start to Sync Flyme Source
echo "开始工作目录搭建......"
mkdir flyme
cd flyme
repo init -u https://github.com/FlymeOS5/manifest.git -b lollipop-5.1
repo sync -c -j4

echo "源码同步完成......"

source build/envsetup.sh

echo "请输入设备名，完成后请输入回车键"
echo "推荐为设备代号(例如米3为cancro,i9500为i9500)"
read -p "设备名:" name

#Now Start to Build It

mkdir -p devices/$name
cd devices/$name
echo "请仔细阅读以下文本!"
echo "本工具支持Recovery，开机模式、无机适配三种方式!"
echo "1.Recovery模式下插入手机即可，全自动模式!"
echo "2.正常模式下方案同Recovery模式，需要自己将ROM包的boot.img以及recovery.fstab放入项目目录下！"
echo "3.无机适配情况下请将ROM包从CM官网下载并更名为ROM.zip，务必确保刷机包内为dat格式!"
echo "若项目目录下存在ROM.zip则优先进行无机适配!"
read
flyme config
echo "请检查Makefile文件是否需要修改"
read
flyme newproject
flyme patchall
cp -rf ../base_cm/SystemUI .
cp -rf ../base_cm/TeleService .
cp -rf ../base_cm/custom_jar.sh .

sed -i -e "s/persist\.sys\.usb\.config=.*/persist\.sys\.usb\.config=mtp\,adb/g" boot.img.out/RAMDISK/default.prop
sed -i 's/export\ BOOTCLASSPATH.*/&:\/system\/framework\/flyme-framework\.jar:\/system\/framework\/flyme-telephony-common\.jar:\/system\/framework\/meizu2_jcifs\.jar/g' boot.img.out/RAMDISK/init.environ.rc
echo "Reject提示："
echo "通常情况下为2个rej，boot.img.out中已经由系统自动解决"
read

cd ../..
. auto.sh $name

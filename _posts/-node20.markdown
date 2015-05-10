---
layout: post
title:  "Faire fonctionner une webcam iSight d&#039;un Macbook pro sur ubuntu Hardy"
---
Télécharger les sources isight-firmware-tools

     $ cd /tmp
     $ wget http://launchpad.net/isight-firmware-tools/main/1.2/+download/isight-fir...

Compiler isight-firmware-tools

     $ tar zxvf isight-firmware-tools-1.2.tar.gz
     $ cd isight-firmware-tools-1.2
     $ ./configure  --enable-udev --disable-hal && make

Ubuntu utilisant udev, il faut l'activer à la compilation.

Installer isight-firmware-tools

     $ sudo apt-get install checkinstall
     $ sudo checkinstall

checkinstall va servir un packet debian pour notre version de isight. Il
est demander d'inscrire les informations relatives à l'installation

On peut ensuite relancer udev :

     $ sudo invoke-rc.d udev restart

Installer le firmware d'Apple

La partition du mac est disponible /media/mac

     $ cp $(find /media/mac/ -name AppleUSBVideoSupport) /lib/firmware/
     $ sudo ift-extract -a /lib/firmware/AppleUSBVideoSupport

Compiler et installer le module uvcvideo

     $ cd /tmp
     $ sudo modprobe -r uvcvideo
     $ sudo mv /lib/modules/$(uname -r)/ubuntu/media/usbvideo/uvcvideo.ko /lib/modules/$(uname -r)/ubuntu/media/usbvideo/uvcvideo.ko.orig
     $ sudo apt-get install libusb-0.1-4 libusb-dev linux-headers-$(uname -r) subversion
     $ svn co --revision 205 svn://svn.berlios.de/linux-uvc/linux-uvc/trunk uvcvideo-r205
     $ cd uvcvideo-r205
     $ make
     $ sudo make install
     $ sudo depmod -ae
     $ sudo modprobe uvcvideo

Faire créer par udev le périphérique /dev/video0

Repérer le bus et le device de la webcam

     $ lsusb
    Bus 005 Device 007: ID 05ac:8501 Apple Computer, Inc. Built-in iSight [Micron]

     $ sudo /usr/local/lib/udev/ift-load -f /lib/firmware/isight.fw -b 005  -d 007

Tester

En lançant l'application *cheese*, la webcam devrait fonctionner :

![](http://tutos.tangui.eu.org/files/Screenshot-Cheese.png)

Source

Merci à benanzo et pveith des forums ubuntu :
 - <http://ubuntuforums.org/showpost.php?p=4777298&postcount=1>\
 -
[http://ge.ubuntuforums.com/showpost.php?s=8af1c756fe0c4667944dd1a02c1843...](http://ge.ubuntuforums.com/showpost.php?s=8af1c756fe0c4667944dd1a02c18434a&p=4791284&postcount=30 "http://ge.ubuntuforums.com/showpost.php?s=8af1c756fe0c4667944dd1a02c18434a&p=4791284&postcount=30")


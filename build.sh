#!/bin/bash

# make sure we have dependencies 
hash genisoimage 2>/dev/null || { echo >&2 "ERROR: genisoimage not found.  Aborting."; exit 1; }
hash vagrant 2>/dev/null || { echo >&2 "ERROR: vagrant not found. Make sure its in your PATH. Aborting."; exit 1; }
hash curl 2>/dev/null || { echo >&2 "ERROR: curl not found. Install it by typing 'sudo apt-get install transmission-cli'. Aborting."; exit 1; }
lsmod | grep vboxdrv 1>&2 >/dev/null
if [ $? == 1 ]; then 
  echo >&2 "ERROR: kernel module not loaded (vboxdrv). Aborting."
  exit 1
fi

set -o nounset
set -o errexit
#set -o xtrace

# Configurations
BOX="debian-squeeze-64"
BASE_NAME="debian-6.0.7-amd64-netinst.iso"
ISO_URL="http://caesar.acc.umu.se/debian-cd/6.0.7/amd64/iso-cd/$BASE_NAME"
ISO_MD5=$(curl -s "${ISO_URL}/MD5SUMS" | grep "${BASE_NAME}" | awk '{ print $1 }')

# location, location, location
FOLDER_BASE=`pwd`
FOLDER_ISO="${FOLDER_BASE}/iso"
FOLDER_BUILD="${FOLDER_BASE}/build"
FOLDER_VBOX="${FOLDER_BUILD}/vbox"
FOLDER_ISO_CUSTOM="${FOLDER_BUILD}/iso/custom"
FOLDER_ISO_INITRD="${FOLDER_BUILD}/iso/initrd"

# start with a clean slate
if [ -d "${FOLDER_BUILD}" ]; then
  echo "Cleaning build directory ..."
  chmod -R u+w "${FOLDER_BUILD}"
  rm -rf "${FOLDER_BUILD}"
  mkdir -p "${FOLDER_BUILD}"
fi

# Setting things back up again
mkdir -p "${FOLDER_ISO}"
mkdir -p "${FOLDER_BUILD}"
mkdir -p "${FOLDER_VBOX}"
mkdir -p "${FOLDER_ISO_CUSTOM}"
mkdir -p "${FOLDER_ISO_INITRD}"
mkdir -p "${FOLDER_BUILD}/initrd"

ISO_FILENAME="${FOLDER_ISO}/${BASE_NAME}"
INITRD_FILENAME="${FOLDER_ISO}/initrd.gz"
ISO_GUESTADDITIONS="/usr/share/virtualbox/VBoxGuestAdditions.iso"

# check if guest additions is in it's regular place (apparently not in 12.04 - I had to install it)
if [ ! -f $ISO_GUESTADDITIONS ]; then
  echo "ERROR: VirtualBoxGuestAdditions.iso file can't be found. 'sudo apt-get install virtualbox-guest-additions-iso'. Aborting.";
  exit 1
fi

# download the installation disk if you haven't already or it is corrupted somehow
if [ ! -e "${ISO_FILENAME}" ]; then
  echo "Downloading `basename ${ISO_URL}` ..."
  curl --progress-bar -o "${FOLDER_ISO}/${BASE_NAME}" "${ISO_URL}"

  # make sure download is right...
  ISO_HASH=`md5sum "${ISO_FILENAME}" | cut -d" " -f 1`
  echo $ISO_HASH
  if [ "${ISO_MD5}" != "${ISO_HASH}" ]; then
    echo "ERROR: MD5 does not match. Got ${ISO_HASH} instead of ${ISO_MD5}. Aborting."
    exit 1
  fi
fi

# customize it
echo "Creating Custom ISO"
if [ ! -e "${FOLDER_ISO}/custom.iso" ]; then

  # Extract the ISO
  echo "Extracting ISO image ..."
  rm -rf "${FOLDER_ISO_CUSTOM}"
  mkdir "${FOLDER_ISO_CUSTOM}"
  bsdtar -C "${FOLDER_ISO_CUSTOM}" -xf "${FOLDER_ISO}/${BASE_NAME}"


  echo "Rebuilding Initrd ..."
  ARCH=$(ls -1 -d "${FOLDER_ISO_CUSTOM}/install."* | sed 's/^.*\///')
  chmod u+w "${FOLDER_ISO_CUSTOM}/${ARCH}"
  cp "${FOLDER_ISO_CUSTOM}/${ARCH}/initrd.gz" "${FOLDER_ISO_CUSTOM}/${ARCH}/initrd.gz.old"
  cp -a "${FOLDER_ISO_CUSTOM}/${ARCH}/"* "${FOLDER_ISO_CUSTOM}/install"

  pushd "${FOLDER_BUILD}/initrd"
    gunzip -c "${FOLDER_ISO_CUSTOM}/${ARCH}/initrd.gz" | cpio -id
    cp "${FOLDER_BASE}/src/preseed.cfg" "${FOLDER_BUILD}/initrd/preseed.cfg"
    find . | cpio --create --format='newc' | gzip > "${FOLDER_ISO_CUSTOM}/install/initrd.gz"
  popd

  chmod u-w "${FOLDER_ISO_CUSTOM}/${ARCH}" "${FOLDER_ISO_CUSTOM}/${ARCH}/initrd.gz.old"

  echo "Copying bootstrap ..."
  cp "${FOLDER_BASE}/src/poststrap.sh" "${FOLDER_ISO_CUSTOM}"
  cp "${FOLDER_BASE}/src/bootstrap.sh" "${FOLDER_ISO_CUSTOM}"
  cp "${FOLDER_BASE}/src/isolinux.cfg" "${FOLDER_ISO_CUSTOM}/isolinux/"

  echo "Setting permissions on bootstrap scripts ..."
  chmod 755 "${FOLDER_ISO_CUSTOM}/poststrap.sh"
  chmod 755 "${FOLDER_ISO_CUSTOM}/bootstrap.sh"
 
  echo "Running genisoimage ..."
  genisoimage -r -V "Custom Debian Install CD" \
    -cache-inodes -quiet \
    -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -o "${FOLDER_ISO}/custom.iso" "${FOLDER_ISO_CUSTOM}"

fi

echo "Creating VM Box..."
# create virtual machine
if ! VBoxManage showvminfo "${BOX}" >/dev/null 2>/dev/null; then
  VBoxManage createvm \
    --name "${BOX}" \
    --ostype Debian_64 \
    --register \
    --basefolder "${FOLDER_VBOX}"

  VBoxManage modifyvm "${BOX}" \
    --memory 360 \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --vram 12 \
    --pae off \
    --rtcuseutc on

  VBoxManage storagectl "${BOX}" \
    --name "IDE Controller" \
    --add ide \
    --controller PIIX4 \
    --hostiocache on

  VBoxManage storageattach "${BOX}" \
    --storagectl "IDE Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium "${FOLDER_ISO}/custom.iso"

  VBoxManage storagectl "${BOX}" \
    --name "SATA Controller" \
    --add sata \
    --controller IntelAhci \
    --sataportcount 1 \
    --hostiocache off

  VBoxManage createhd \
    --filename "${FOLDER_VBOX}/${BOX}/${BOX}.vdi" \
    --size 40960

  VBoxManage storageattach "${BOX}" \
    --storagectl "SATA Controller" \
    --port 0 \
    --device 0 \
    --type hdd \
    --medium "${FOLDER_VBOX}/${BOX}/${BOX}.vdi"

    VBoxHeadless -startvm "${BOX}"

  echo -n "Waiting for installer to finish "
  while VBoxManage list runningvms | grep "${BOX}" >/dev/null; do
    sleep 20
    echo -n "."
  done
  echo ""

  # Attach guest additions iso
  VBoxManage storageattach "${BOX}" \
    --storagectl "IDE Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium "${ISO_GUESTADDITIONS}"

    VBoxHeadless -startvm "${BOX}"

  echo -n "Waiting for machine to shut off "
  while VBoxManage list runningvms | grep "${BOX}" >/dev/null; do
    sleep 20
    echo -n "."
  done
  echo ""

  # Detach guest additions iso
  echo "Detach guest additions ..."
  VBoxManage storageattach "${BOX}" \
    --storagectl "IDE Controller" \
    --port 1 \
    --device 0 \
    --type dvddrive \
    --medium emptydrive
fi

echo "Building Vagrant Box ..."
vagrant package --base "${BOX}"

# references:
# http://blog.ericwhite.ca/articles/2009/11/unattended-debian-lenny-install/
# http://cdimage.ubuntu.com/releases/precise/beta-2/
# http://www.imdb.com/name/nm1483369/
# http://vagrantup.com/docs/base_boxes.html

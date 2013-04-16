# Vagrant Base Box Builder (for Debian Squeeze)

This is a small script to automatically build a vagrant base box form the latest Stable Debian release.  The result is a lightweight debian installation containing the latest security updates which can be used as a base for your projects.  It produces a clean install apart from puppet (from debian repo) and chef solo (from the ops code repository - apt.opscode.com).

When run it will do the following things for you:

1. Download the latest debian distribution from http://cdimage.debian.org/
2. Repack the ISO to configure an unattended install.
3. Create a VirtualBox VM and install debian.
4. Create a vagrant base box (output to debian.box).

## Dependancies

 - vagrant
 - genisoimage
 - curl

## Usage

    $ ./build.sh

Run this from a debian server (might need root permissions to run mknod)

### James' notes

I decided I wanted to create my own vagrant base box from the latest release to understand how a vagrant box is configured and see if it is possible to use them to build production ready VM's.  


### History:
 - Carl created a script to build Ubuntu on his Mac
 - Ben added some verification
 - Kev ported it to run on Ubuntu
 - The install scripts were taken from twilliam's fork as they better suit debian


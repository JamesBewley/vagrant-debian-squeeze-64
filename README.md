# Vagrant Base Box Builder (for Debian Squeeze)

This is a small script to automatically build a vagrant base box form the latest Stable Debian release.  The result is a lightweight debian installation containing the latest security updates which can be used as a base for your projects.

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

This should do everything you need. If you don't have you must 
have `transmission-cli` installed `sudo apt-get install transmission-cli`
if not. Likewise, `file-roller` (which should be installed by default with
Ubuntu-Desktop, otherwise `sudo apt-get install file-roller` then:

### James' notes

Decided I want to create my own vagrant base box from the latest release.

Let's automatically build the latest stable debian server, I said.

Oh look, someone's done it for Ubuntu, I said.

Let's port that to debian, I said.

### Kev's notes

"Let's do it all on my **Ubuntu PC**, I said."

Standing on the shoulder's of giants (thanks Carl & Ben) - I have 
modified this `bash` script to work on Ubuntu 12.04 (Precise Pangolin). 
I also modified to download via torrent instead of slow HTTP.

### Ben's notes

Forked Carl's repo, and it sort of worked out of the box. Tweaked 
office 12.04 release: 

 - Downloading 12.04 final release. (Today as of this writing)
 - Checking MD5 to make sure it is the right version
 - Added a few more checks for external dependencies, mkisofs
 - Removed wget, and used curl to reduce dependencies
 - Added more output to see what is going on
 - Still designed to work on Mac OS X :)
    ... though it should work for Linux systems too (maybe w/ a bit of porting)

### Carl's original README

Decided I wanted to learn how to make a vagrant base box.

Let's target Precise Pangolin since it should be releasing soon, I said.

Let's automate everything, I said.

Let's do it all on my macbook, I said.

Woo.

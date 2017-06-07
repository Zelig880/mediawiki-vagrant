#!/usr/bin/env bash
# Build a fresh Mediawiki-Vagrant installer image
#
# Meant to be executed inside the Vagrant virtual machine
#
# Requires:
#   - aptitude
#   - genisoimage

set -euf -o pipefail

MWV=/vagrant
CONTENTS=${MWV}/support/packager/output/contents
BUILD_INFO=${CONTENTS}/BUILD_INFO
APT_OPTS="-o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold -y"

{
    set -x
    export COMPOSER_CACHE_DIR="${MWV}/cache/composer"
    export SHELL=/bin/bash

    # Get latest MediaWiki-Vagrant
    cd ${MWV}
    git fetch
    git reset --hard origin/master

    # Get latest MediaWiki-core
    /usr/local/bin/run-git-update
    cd ${MWV}/mediawiki
    git reset --hard origin/master

    # Freshen git cache
    sudo /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get update
    sudo /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS dist-upgrade
    # Get rid of obsolete apt packages
    sudo /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTS autoclean

    # Hack some things into the build
    mkdir -p ${CONTENTS}

    # Add a BUILD_INFO file so we can tell what was included in the image
    echo "Build date: $(date +%Y-%m-%dT%H:%MZ)" >${BUILD_INFO}
    echo "MediaWiki-Vagrant: $(cd ${MWV}; git rev-parse HEAD)" >>${BUILD_INFO}
    echo "MediaWiki: $(cd ${MWV}/mediawiki; git rev-parse HEAD)" >>${BUILD_INFO}

    # Generate installer output (directory and iso)
    cd ${MWV}/support/packager
    ruby package.rb

    # Compute and store a checksum for the image
    cd ${MWV}/support/packager/output
    sha1sum mediawiki-vagrant-installer.iso > mediawiki-vagrant-installer.iso.SHA1.txt

    echo "Done!"
} 2>&1

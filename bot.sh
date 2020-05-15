#!/bin/bash
#
# Pull in linux-stable updates to a kernel tree
#
# Copyright (C) 2020 Kotya Agapkin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

# Colors
BOLD="\033[1m"
GRN="\033[01;32m"
RED="\033[01;31m"
RST="\033[0m"
YLW="\033[01;33m"

function echo() {
    command echo -e "$@"
}

function header() {
    if [[ -n ${2} ]]; then
        COLOR=${2}
    else
        COLOR=${RED}
    fi
    echo "${COLOR}"
    # shellcheck disable=SC2034
    echo "====$(for i in $(seq ${#1}); do echo "=\c"; done)===="
    echo "==  ${1}  =="
    # shellcheck disable=SC2034
    echo "====$(for i in $(seq ${#1}); do echo "=\c"; done)===="
    echo "${RST}"
}

function error() {
    echo
    echo "${RED}${1}${RST}"
    [[ ${2} = "-h" ]] && ${0} -h
    exit 1
}

function success() {
    echo
    echo "${GRN}${1}${RST}"
    [[ -z ${2} ]] && echo
}

function warn() {
    echo
    echo "${YLW}${1}${RST}"
    [[ -z ${2} ]] && echo
}

function parse_parameters() {
    while [[ $# -ge 1 ]]; do
        case ${1} in

            # Help menu
            "-h"|"--help")
                echo
                echo "${BOLD}Command:${RST} . bot/bot.sh <options>"
                echo
                echo "${BOLD}Script description:${RST} Build Android roms"
                echo
                echo "${BOLD}Required parameters:${RST}"
                echo "    -c | --clean"
                echo "        Clears the assembly directory"
                echo
                echo "${BOLD}Optional parameters:${RST}"
                echo "    -a | --abichecks"
                echo "        Skip ABI checks"
                echo
                echo "    -e | --eng"
                echo "    -u | --user"
                echo "        Build type. Default - userdebug."
                sleep 999d ;;

            # Clean build
            "-c"|"--clean")
                CLEAN_BUILD=true ;;

            # Build type
            "-e"|"--eng")
                SCRIPT_BUILD_TYPE=eng ;;

            # Build type
            "-u"|"--user")
                SCRIPT_BUILD_TYPE=user ;;

            # Build type - user
            "-a"|"--abichecks")
                SKIP_ABI_CHECKS=true ;;

            *)
                error "Invalid parameter!" ;;
        esac

        shift
    done
}

parse_parameters "$@"

TIME_START=$(date +"%s")

# Source bot.conf
if [ -f bot/bot.conf ]; then
    source bot/bot.conf
    echo ""
else
    rm -rf bot
    git clone git@github.com:KotyaTheCat/BuildBot.git bot
    source bot/bot.conf
    echo ""
fi

cd 
cd $ROM_PATH

# Source envsetup
if [ -f build/envsetup.sh ]; then
    source build/envsetup.sh
    export source_envsetup_after_sync=false
    echo ""
else
    export source_envsetup_after_sync=true
    echo ""
fi

# Out 
export outdir="out/target/product/$DEVICE_CODENAME"

echo
echo
header "Starting build for $ROM"
echo

function repo_sync_1() {
    echo
    success "        Sync started for "$manifest_url""
    echo
    bot/telegram -M "Sync Started for [$ROM]($manifest_url)"
    SYNC_START=$(date +"%s")
    repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
    if [ "$source_envsetup_until_sync" = "true" ]; then
        source build/envsetup.sh
        echo ""
    else
        echo ""
    fi
    
    # Sync device
    rm -rf $src_device
    git clone $git_src_device $src_device
    echo ""
    
    # Sync vendor
    rm -rf $src_vendor
    git clone $git_src_vendor $src_vendor
    echo ""
    
    # Sync Kernel
    if [ -e $src_kernel ]; then
        rm -rf $src_kernel
        git clone $git_src_kernel $src_kernel
        echo ""
     else
        git clone $git_src_kernel $src_kernel
        echo ""
     fi
}

repo_sync_1

# All nonsense (REMOVE IT, ONLY FOR KOTYATHECAT)
    rm -rf Temp
    git clone git@github.com:KotyaTheCat/Temp.git
    rm -rf packages/apps/Updates/src/org/evolution/ota/misc/Constants.java
    cp Temp/Constants.java packages/apps/Updates/src/org/evolution/ota/misc/Constants.java
    echo
    rm -rf hardware/qcom/sm8150/display && git clone https://github.com/HentaiOS/platform_hardware_qcom_sm8150_display.git hardware/qcom/sm8150/display
    rm -rf hardware/qcom-caf/sm8150/display && git clone https://github.com/KotyaTheCat/hardware_qcom-caf_sm8150_display.git hardware/qcom-caf/sm8150/display

SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))

if [ -e vendor/$rom_vendor_name ]; then
    success "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    ${normal}
    bot/telegram -M "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds

Build Started: [$ROM]($manifest_url)"

# Clean
if [ "$CLEAN_BUILD" = "true" ]; then
    make clean
    CLEAN_BUILD=false
else
    CLEAN_BUILD=false
fi

# Done
if [ -e out/done_builds ]; then
        echo ""
else
  if [ -e out/ ]; then
     mkdir out/done_builds
  else
     mkdir out
     mkdir out/done_builds
  fi
fi

# Starting build
    ccache -M 50G
    export USE_CCACHE=1
    export PATH=~/bin:$PATH
    success " CCache is enabled for build"
    success "${bldgrn}  Starting build..."
    ${normal}
    BUILD_START=$(date +"%s")
    . build/envsetup.sh
    lunch $lunch_command
    mka bacon -j$(nproc --all)

# End
    BUILD_END=$(date +"%s")
    BUILD_DIFF=$((BUILD_END - BUILD_START))

    export finalzip_path=$(ls "$outdir"/*20*.zip | tail -n -1)
    export zip_name=$(echo "$finalzip_path" | sed "s|"$outdir"/||")
    export tag=$( echo "$zip_name" | sed 's|.zip||')
    export changelog=$(ls -tr "$outdir"/*$DEVICE_CODENAME*.zip.txt | tail -n -1)
    if [ -e "$finalzip_path" ]; then
        success "     Build completed successfully in ${txtrst}${grn}$((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

        echo "Uploading"

        cd
        echo "cd && ./dropbox_uploader.sh upload $ROM_PATH/out/done_builds/$zip_name $zip_name && cd $ROM_PATH" 
        ./dropbox_uploader.sh upload $ROM_PATH/$finalzip_path $zip_name
        cd $ROM_PATH

        success " /////// Done ///////"

        bot/telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        bot/telegram -f "$changelog"
        bot/telegram -f $finalzip_path.json
        bot/telegram -f $finalzip_path.md5sum
        mv $finalzip_path out/done_builds/$zip_name
        TIME_END=$(date +"%s")
        TIME_DIFF=$((TIME_END - TIME_START))
    else
        echo ""
        success " Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        echo -e "$((TIME_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
        echo ""
        ${normal}
        bot/telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds
$((TIME_DIFF / 60)) minute(s) and $((TIME_DIFF % 60)) seconds"
    fi
else
    echo
    error "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    echo -e "$((TIME_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    echo
    ${normal}
    bot/telegram -N -M "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds
TIME: $((TIME_DIFF / 60)) minute(s) and $((TIME_DIFF % 60)) seconds"
fi

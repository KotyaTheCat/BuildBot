#!/bin/bash

res1=$(date +%s.%N)

if [ -f bot/bot.conf ]; then
    source bot/bot.conf
    echo ""
else
    git clone git@github.com:KotyaTheCat/bot.git
    source bot/bot.conf
    echo ""
fi

cd 
cd $ROM_PATH

if [ -f build/envsetup.sh ]; then
    source build/envsetup.sh
    export source_envsetup_after_sync=false
    echo ""
else
    export source_envsetup_after_sync=true
    echo ""
fi

red='tput setaf 1'
green='tput setaf 2'
yellow='tput setaf 3'
blue='tput setaf 4'
violet='tput setaf 5'
cyan='tput setaf 6'
white='tput setaf 7'
txtbld=$(tput bold)
bldred=${txtbld}$(tput setaf 1)
bldgrn=${txtbld}$(tput setaf 2)
bldyel=${txtbld}$(tput setaf 3)
bldblu=${txtbld}$(tput setaf 4)
bldcya=${txtbld}$(tput setaf 6)
normal='tput sgr0'

tput bold
tput setaf 1
echo ""
echo -e "        ${bldyel} Starting build for $ROM" 
echo ""
${normal}

# Email for git
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USER"

export SKIP_ABI_CHECKS=true
export outdir="out/target/product/violet" # violet = codename my device. Change this

cd
cd $ROM_PATH

if [ -e out/done_builds ]; then
    echo ""
else
  if [ -e out/ ]; then
    mkdir out/done_builds
    echo ""
  else
    mkdir out
    mkdir out/done_builds
    echo ""
  fi
fi

# Sync
echo "${bldyel} Sync started for "$manifest_url""
${normal}
bot/telegram -M "Sync Started for [$ROM]($manifest_url)"
SYNC_START=$(date +"%s")
rm -rf vendor/$rom_vendor_name
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
if [ "$source_envsetup_until_sync" = "true" ]; then
    source build/envsetup.sh
    echo ""
else
    echo ""
fi
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
echo ""

# Sync device
rm -rf device/xiaomi/violet
git clone $git_src_device $src_device
echo ""

# Sync vendor
rm -rf vendor/xiaomi/violet
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

# Additional repositories

rm -rf Temp
git clone git@github.com:KotyaTheCat/Temp.git
rm -rf packages/apps/Updates/src/org/evolution/ota/misc/Constants.java
cp Temp/Constants.java packages/apps/Updates/src/org/evolution/ota/misc/Constants.java

# Custom HALs

rm -rf hardware/qcom-caf/sm8150/display && git clone https://github.com/KotyaTheCat/hardware_qcom-caf_sm8150_display.git hardware/qcom-caf/sm8150/display && rm -rf hardware/qcom-caf/sm8150/media && git clone git@github.com:KotyaTheCat/hardware_qcom-caf_sm8150_media.git hardware/qcom-caf/sm8150/media && rm -rf hardware/qcom-caf/sm8150/audio && git clone git@github.com:KotyaTheCat/hardware_qcom-caf_sm8150_audio.git hardware/qcom-caf/sm8150/audio

echo ""
SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))

if [ -e vendor/$rom_vendor_name ]; then
    echo "${bldgrn} Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    ${normal}
    bot/telegram -M "Sync completed successfully in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds

Build Started: [$ROM]($manifest_url)"

# Start Build

    ccache -M 50G
    export USE_CCACHE=1
    export PATH=~/bin:$PATH
    echo -e "${bldyel} CCache is enabled for build"
    echo -e "${bldgrn}  Starting build..."
    ${normal}
    BUILD_START=$(date +"%s")
    . build/envsetup.sh
    lunch "$rom_vendor_name"_violet-userdebug # violet = codename my device. Change this.
    mka bacon
    BUILD_END=$(date +"%s")
    BUILD_DIFF=$((BUILD_END - BUILD_START))

    export finalzip_path=$(ls "$outdir"/*20*.zip | tail -n -1)
    export zip_name=$(echo "$finalzip_path" | sed "s|"$outdir"/||")
    export tag=$( echo "$zip_name" | sed 's|.zip||')
    export changelog=$(ls -tr "$outdir"/*violet*.zip.txt | tail -n -1)  # violet = codename my device. Change this
    if [ -e "$finalzip_path" ]; then
        res2=$(date +%s.%N)
        echo "${bldgrn}Build completed successfully in ${txtrst}${grn}$((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

        echo "Uploading"
        ${normal}

        cd
        ./dropbox_uploader.sh upload $ROM_PATH/$finalzip_path $zip_name
        echo "cd && ./dropbox_uploader.sh upload $ROM_PATH/out/done_builds/$zip_name $zip_name && cd $ROM_PATH" 
        cd $ROM_PATH

        echo "${bldgrn} /////// Done ///////"
        ${normal}

        bot/telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        bot/telegram -f "$changelog"
        bot/telegram -f $finalzip_path.json
        bot/telegram -f $finalzip_path.md5sum
        mv $finalzip_path out/done_builds/$zip_name
    else
        echo ""
        echo "${bldred} Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        echo ""
        ${normal}
        bot/telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    fi
else
    echo ""
    echo "${bldred} Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
    echo ""
    ${normal}
    bot/telegram -N -M "Sync failed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds"
fi

cyan='tput setaf 6'
yellow='tput setaf 3'
red='tput setaf 1'
reset='tput sgr0'

assert(){
    if [ "$?" -ne "0" ]; then
        echo -e "\n$($red)// Sub-Process $($yellow)${FUNCNAME[1]}$($red) failed. Bailing out!$($reset)"
        exit
    fi
}

zip_cleanup(){
    echo -e "\n$($cyan)// Cleaning up $($yellow)$1$($reset)\n"
    zip -d $1 firmware-update/vbmeta.img firmware-update/dtbo.img boot.img compatibility.zip system.new.dat.br system.patch.dat system.transfer.list
    assert
}

unzip_ota(){
    echo -e "\n$($cyan)// Unzipping $($yellow)$1$($reset)\n"
    rm -rf .workspace
    mkdir .workspace
    unzip $1 META-INF/com/google/android/updater-script vendor.new.dat.br vendor.transfer.list vendor.patch.dat -d .workspace
    assert
    cd .workspace
}

sed_updater(){
    echo -e "\n$($cyan)// Cleaning up $($yellow) updater-script$($reset)\n"
    cp META-INF/com/google/android/updater-script updater-script-og
    sed -i -e '/system/d' -e '/boot.img/d' -e '/vbmeta.img/d' -e '/dtbo.img/d' META-INF/com/google/android/updater-script
    assert
    git diff --no-index updater-script-og META-INF/com/google/android/updater-script > diff
}

extract_image(){
    echo -e "\n$($cyan)// Extracting $($yellow)vendor.img$($reset)\n"
    brotli -d vendor.new.dat.br -o vendor.new.dat
    sdat2img vendor.transfer.list vendor.new.dat vendor.img
    assert
}

mount_vendor(){
    echo -e "\n$($cyan)// Mounting $($yellow)vendor.img$($reset)\n"
    mkdir vendor
    sudo mount vendor.img vendor
    assert
}

replace_fstab(){
    echo -e "\n$($cyan)// Replacing $($yellow)fstab.qcom$($reset)\n"
    sudo cp ../$1 vendor/etc/fstab.qcom
    assert
}

umount_vendor(){
    echo -e "\n$($cyan)// Unmounting $($yellow)vendor.img$($reset)\n"
    sudo umount vendor.img
    assert
}

sparse_vendor(){
    echo -e "\n$($cyan)// Making $($yellow)sparsed vendor.img$($reset)\n"
    img2simg vendor.img vendor_sparse.img
    assert
}

convert_dat(){
    echo -e "\n$($cyan)// Coverting $($yellow)vendor.img to $($yellow)vendor.new.dat$($reset)\n"
    img2sdat -o vendor_patched -v 4 vendor_sparse.img
    assert
}

rename_vendor(){
    mv vendor_patched/system.new.dat vendor_patched/vendor.new.dat
    mv vendor_patched/system.patch.dat vendor_patched/vendor.patch.dat
    mv vendor_patched/system.transfer.list vendor_patched/vendor.transfer.list
}

bro_compress(){
    echo -e "\n$($cyan)// Compressing $($yellow)vendor.new.dat$($reset)\n"
    brotli -7 vendor_patched/vendor.new.dat -o vendor_patched/vendor.new.dat.br -v
    assert
    rm vendor_patched/vendor.new.dat
}

zip_update(){
    echo -e "\n$($cyan)// Updating $($yellow)$1$($cyan) with patched files $($reset)\n"
    mkdir rezip
    cp -r vendor_patched/* META-INF rezip
    cd rezip
    zip -r ../../$1  META-INF vendor.new.dat.br vendor.patch.dat vendor.transfer.list

}

if [ -z "$1" ]; then
    echo "usage: $0 full_ota.zip"
    exit
fi

zip_cleanup $1
unzip_ota $1
sed_updater
extract_image
mount_vendor
replace_fstab replace/fstab.qcom
umount_vendor
sparse_vendor
convert_dat
rename_vendor
bro_compress
zip_update $1

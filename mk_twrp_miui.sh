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
    zip -d $1 compatibility.zip
    assert
}

unzip_ota(){
    echo -e "\n$($cyan)// Unzipping $($yellow)$1$($reset)\n"
    rm -rf .workspace
    mkdir .workspace
    unzip $1 system.new.dat.br system.patch.dat system.transfer.list vendor.new.dat.br vendor.transfer.list vendor.patch.dat -d .workspace
    assert
    cd .workspace
}

extract_image(){
    echo -e "\n$($cyan)// Extracting $($yellow)$1.img$($reset)\n"
    brotli -d $1.new.dat.br -o $1.new.dat
    sdat2img $1.transfer.list $1.new.dat $1.img
    assert
}

mount_image(){
    echo -e "\n$($cyan)// Mounting $($yellow)$1.img$($reset)\n"
    mkdir $1
    sudo mount $1.img $1
    assert
}

rm_frecovery(){
    echo -e "\n$($cyan)// Removing $($yellow)install-recovery.sh$($reset)\n"
    sudo rm system/system/bin/install-recovery.sh
    assert
}

replace_fstab(){
    echo -e "\n$($cyan)// Replacing $($yellow)fstab.qcom$($reset)\n"
    sudo cp ../$1 vendor/etc/fstab.qcom
    assert
}

umount_image(){
    echo -e "\n$($cyan)// Unmounting $($yellow)$1.img$($reset)\n"
    sudo umount $1.img
    assert
}

sparse_image(){
    echo -e "\n$($cyan)// Making $($yellow)sparsed $1.img$($reset)\n"
    img2simg $1.img $1_sparse.img
    assert
}

convert_dat(){
    echo -e "\n$($cyan)// Coverting $($yellow)$1.img to $($yellow)$1.new.dat$($reset)\n"
    img2sdat -o $1_patched -v 4 $1_sparse.img
    assert
}

rename_vendor(){
    mv vendor_patched/system.new.dat vendor_patched/vendor.new.dat
    mv vendor_patched/system.patch.dat vendor_patched/vendor.patch.dat
    mv vendor_patched/system.transfer.list vendor_patched/vendor.transfer.list
}

bro_compress(){
    echo -e "\n$($cyan)// Compressing $($yellow)$1.new.dat$($reset)\n"
    brotli -7 $1_patched/$1.new.dat -o $1_patched/$1.new.dat.br -v
    assert
    rm $1_patched/$1.new.dat
}

zip_update(){
    echo -e "\n$($cyan)// Updating $($yellow)$1$($cyan) with patched files $($reset)\n"
    mkdir rezip
    cp -r vendor_patched/* system_patched/* rezip
    cd rezip
    zip -r ../../$1  *

}

if [ -z "$1" ]; then
    echo "usage: $0 full_ota.zip"
    exit
fi

zip_cleanup $1
unzip_ota $1

extract_image system
mount_image system 
rm_frecovery
umount_image system
sparse_image system
convert_dat system
bro_compress system

extract_image vendor
mount_image vendor 
replace_fstab replace/fstab.qcom
umount_image vendor
sparse_image vendor
convert_dat vendor
rename_vendor
bro_compress vendor

zip_update $1
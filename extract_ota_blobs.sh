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

cleanup(){
    echo -e "\n$($cyan)// Cleaning up $($yellow)$1$($reset)\n"
    rm -rvf $1
}

unzip_ota(){
    echo -e "\n$($cyan)// Unzipping $($yellow)$1$($reset)\n"
    mkdir .workspace
    unzip $1 $2 -d .workspace
    assert
}

extract_image(){
    cd .workspace
    echo -e "\n$($cyan)// Extracting $($yellow)$1.img$($reset)\n"
    brotli -d $1.new.dat.br -o $1.new.dat
    sdat2img $1.transfer.list $1.new.dat $1.img
    assert
    cd ..
}

mount_image(){
    cd .workspace
    echo -e "\n$($cyan)// Mounting $($yellow)$1.img$($reset)\n"
    mkdir $1
    sudo mount $1.img $1
    assert
    cd ..
}

umount_image(){
    cd .workspace
    echo -e "\n$($cyan)// Unmounting $($yellow)$1.img$($reset)\n"
    sudo umount $1.img
    assert
    cd ..
}

cp_blobs(){
    cd .workspace
    cp_to=$1
    rm -rvf $cp_to
    mkdir -p $cp_to/{system.img,vendor.img}
    sudo cp -rv system/* $cp_to/system.img
    assert
    sudo cp -rv vendor/* $cp_to/vendor.img
    assert
    sudo chown -R $USER: $cp_to
    assert
    cd ..
}

if [[ ${1: -4} != ".zip" ]]; then
    echo "usage: $0 full_ota.zip"
    exit
fi

file_name=$1

cleanup .workspace
unzip_ota $file_name "system.new.dat.br system.patch.dat system.transfer.list vendor.new.dat.br vendor.transfer.list vendor.patch.dat"
extract_image system
mount_image system
extract_image vendor
mount_image vendor
cp_blobs ~/_Files/blobs/$(basename $file_name .zip)
umount_image system
umount_image vendor
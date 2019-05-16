assert(){
if [ "$?" -ne "0" ]; then
    echo -e "\nsub-process ${FUNCNAME[1]} failed. Bailing out!"
    exit
fi
}

unzip_ota(){
rm -rf .workspace
mkdir .workspace
unzip $1 vendor.new.dat.br vendor.transfer.list vendor.patch.dat -d .workspace
assert
}

if [ -z "$1" ]; then
    echo "usage: $0 full_ota.zip"
    exit
fi

unzip_ota $1
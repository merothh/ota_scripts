unzip_ota(){
rm -rf .workspace
mkdir .workspace
unzip $1 vendor.new.dat.br vendor.transfer.list vendor.patch.dat -d .workspace
}

if [ -z "$1" ]; then
    echo "usage: $0 full_ota.zip"
    exit
fi

unzip_ota $1
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

unzip_ota(){
echo -e "\n$($cyan)// Unzipping $($yellow)$1$($reset)\n"
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
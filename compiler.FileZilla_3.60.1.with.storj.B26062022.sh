#!/bin/bash
#Compiler FileZilla_3.60.1 with storj by KAPITALSIN 2022 B26062022
#sudo apt-get git subversion 
#https://tecadmin.net/install-go-on-ubuntu/
#sudo add-apt-repository ppa:ubuntu-toolchain-r/test
#
# B26062022
# Improved gcc check/installing 
#
# B04062022
# Updated Filezilla to version 3.60.1
#
# B18052022
# Updated Filezilla to version 3.60.0
#
# B18052022
# Updated Filezilla to version 3.59.0
# Updated libfilezilla to version 0.37.2

# B13022022
# Updated Filezilla to version 3.58.0
# Updated libfilezilla to version 0.36.0
#
#
# B27112021
# Updated Filezilla to version 3.57.0
# Updated libfilezilla to version 0.35.0
#
## B27112021
# Updated Filezilla to version 3.57.0 
# Updated libfilezilla to version 0.34.2
# Downgraded libidn2-2.3.2 to libidn-1.38
# Added the parameters --disable-autoupdatecheck and --disable-manualupdatecheck to filezilla configure
#
#
# B16102021
# Updated Filezilla to version 3.56.1 
# Updated libfilezilla to version 0.34
# Updated sqlite to 3.36.0
#
# B06092021
# Updated GMP to gmp-6.2.1; nettle to nettle-3.7.3; libidn2 to libidn2-2.3.2
# Now the installer creates the compiled Filezilla folder with the binaries and the libs, ready to run
# Informs the version of the GLIBC that has been used for the compilation
# Added missing libuplink for fzstorj
# The script stripes the binaries saving more than 240 MB
# Informs of the free space that is required for the compilation
#
clear
glibc="$(ldd --version | awk '/ldd/{print $NF}')"

gcc_ins (){
echo "INSTALLING NEW GCC"
sudo apt-get install software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-9 g++-9 -y
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
sudo update-alternatives --auto gcc 
}

if which gcc >/dev/null; then
currentver="$(gcc -dumpversion)"
requiredver="9"
else
gcc_ins
exit
fi

 if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
        echo "GCC valid found"
 else
        echo "GCC version "$currentver" found, version ${requiredver} or greater is required to compile the game, now we are going to install the required GCC"
gcc_ins
fi

notify-send "INSTALLING DEPENDENCIES" 
echo "INSTALLING DEPENDENCIES"
sudo apt install libjson-c-dev libuv1-dev libmicrohttpd-dev libgtk2.0-dev libcurl4-gnutls-dev libdbus-1-dev wx-common libtool git -y

echo "EL PROCESO DE COMPILADO REQUIERE TENER UN TOTAL DE UNOS 4 GB DE ESPACIO LIBRE"
read -p "PULSA [ENTER] PARA COMENZAR LA COMPILACION O [CTRL+C] PARA PARAR EL SCRIPT"
trap "exit" SIGHUP SIGINT SIGTERM

time_start=`date +%s`
#Create staging directory
STAGING=$HOME/staging/filezilla
mkdir -p $STAGING


#Sources
SRC=$STAGING/src
mkdir -p $SRC

#Build artifacts
OUT=$STAGING/build
mkdir -p $OUT

export LD_LIBRARY_PATH=$STAGING/build/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=$STAGING/build/lib/pkgconfig:$PKG_CONFIG_PATH
export LDFLAGS='-L/$STAGING/build/lib/include'
#export LDFLAGS=:$LDFLAGS
PATH=$STAGING/src/wx3:$PATH


notify-send "INSTALLING GO LANGUAGE"
pushd $SRC
wget -N https://github.com/johna23-lab/filezilla/raw/main/go1.16.4.linux-amd64.7z
7z x go1.16.4.linux-amd64.7z
popd


notify-send "Building a static version of gmp"
wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz -qO-|tar -C $SRC -xJ
pushd $SRC/gmp*/
./configure --build=x86_64 --prefix=$OUT --enable-static --disable-shared --enable-fat
make -j3 install
popd

notify-send "Building a static version of nettle"
wget https://ftp.gnu.org/gnu/nettle/nettle-3.7.3.tar.gz -qO-|tar -C $SRC -xz
pushd $SRC/nettle*/
./configure --build=x86_64 --prefix=$OUT --enable-static --disable-shared --enable-fat --enable-mini-gmp
make -j3 install
popd


notify-send "Building a static version of GNutls"
wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.0.tar.xz -qO- | tar -C $SRC -xJ
pushd $SRC/gnutls-3.*/
./configure --prefix="$OUT" --enable-static --disable-shared --build=x86_64 --with-included-libtasn1 --disable-doc --disable-guile --enable-local-libopts --disable-nls --with-included-unistring --disable-tests --with-default-trust-store-pkcs11="pkcs11:"
make -j3 install
popd

notify-send "Building a static version of SQLite"
wget https://sqlite.org/2021/sqlite-autoconf-3360000.tar.gz -qO-|tar -C $SRC -xz
pushd $SRC/sql*/
./configure --build=x86_64 --prefix=$OUT --enable-static --disable-shared
make -j3 install
popd

notify-send "Building a static version of wxWidgets"
#git clone --branch WX_3_0_BRANCH --single-branch https://github.com/wxWidgets/wxWidgets.git $SRC/wx3
pushd $SRC
wget -N https://github.com/johna23-lab/filezilla/raw/main/wx3.7z
7z x $SRC/wx3.7z
popd
pushd $SRC/wx3
./configure --prefix=$(pwd) --enable-monolithic  --disable-shared --enable-static --enable-unicode --with-libpng=builtin   --with-libjpeg=builtin  --with-libtiff=builtin  --with-zlib=builtin --with-expat=builtin
make -j3
popd


notify-send "Building a static version of libfilezilla"
#svn co https://svn.filezilla-project.org/svn/libfilezilla/trunk $SRC/libfilezilla
wget https://download.filezilla-project.org/libfilezilla/libfilezilla-0.37.2.tar.bz2 -qO-|tar -C $SRC -xj
pushd $SRC/libfilezilla*/
./configure --prefix=$OUT --enable-static --disable-shared
make -j3 install
popd

notify-send "Building a static version of libidn"
wget -N https://ftp.gnu.org/gnu/libidn/libidn-1.38.tar.gz -qO-|tar -C $SRC -xz
pushd $SRC/libidn*/
./configure --prefix="$OUT" --enable-static --disable-shared
make -j3 install
popd


notify-send "Building libjstor"
git clone https://github.com/storj/libstorj.git $SRC/storj
pushd $SRC/storj*/
./autogen.sh
./configure --prefix="$OUT" --disable-shared --enable-static
make -j3 install
popd


notify-send "Building UPLINK LIBRARY"
git clone https://github.com/storj/uplink-c.git $SRC/uplink
pushd $SRC/uplink
export GOROOT=$SRC/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH 
make install DESTDIR=$OUT
popd

notify-send "Building Filezilla"
wget https://download.filezilla-project.org/client/FileZilla_3.60.1_src.tar.bz2 -qO-|tar -C $SRC -xj
pushd $SRC/filezilla*/
./configure --prefix="$OUT" --enable-static --disable-shared --with-pugixml=builtin --enable-storj --disable-manualupdatecheck --disable-autoupdatecheck
make -j3 install
popd

pushd $OUT
mkdir -p FileZilla_3.60.1.storj.x86_64/bin

cp $OUT/lib/libuplink.so FileZilla_3.60.1.storj.x86_64/bin
strip bin/*
cp bin/filezilla FileZilla_3.60.1.storj.x86_64/bin
cp bin/fz* FileZilla_3.60.1.storj.x86_64/bin
cp bin/certtool FileZilla_3.60.1.storj.x86_64/bin
cp -r share FileZilla_3.60.1.storj.x86_64

echo '#!/bin/sh' > $OUT/FileZilla_3.60.1.storj.x86_64/filezilla.sh
echo 'BIN=bin/./filezilla' >> $OUT/FileZilla_3.60.1.storj.x86_64/filezilla.sh
echo 'export LD_LIBRARY_PATH=lib/x86_64-linux-gnu:/lib64:usr/lib/x86_64-linux-gnu/' >> $OUT/FileZilla_3.60.1.storj.x86_64/filezilla.sh
echo 'exec $BIN $@' >> $OUT/FileZilla_3.60.1.storj.x86_64/filezilla.sh
chmod a+x $OUT/FileZilla_3.60.1.storj.x86_64/filezilla.sh

for library in $(ldd "bin/certtool" "bin/filezilla" "bin/fzputtygen"  "bin/fzsftp" | cut -d '>' -f 2 | awk '{print $1}')
do
	[ -f "${library}" ] && cp --verbose --parents "${library}" "$OUT/FileZilla_3.60.1.storj.x86_64"
done

cp $OUT/lib/libuplink.so FileZilla_3.60.1.storj.x86_64/lib/x86_64-linux-gnu/

mv $OUT/FileZilla_3.60.1.storj.x86_64 ../FileZilla_3.60.1.storj.x86_64_GLIBC_"$glibc"
popd
echo "FILEZILLA COMPILED AT $STAGING/FileZilla_3.60.1.storj.x86_64_GLIBC_"$glibc""

time_end=`date +%s`
time_exec=`expr $(( $time_end - $time_start ))`
echo "EL PROCESO DE COMPILADO HA TARDADO UN TOTAL DE $(($time_exec / 60)) minutos y $(($time_exec % 60)) segundos."

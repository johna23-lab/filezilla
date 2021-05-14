#Compiler FileZilla_3.54.1 with jstor by KAPITALSIN 2021
#sudo apt-get git subversion 
#https://tecadmin.net/install-go-on-ubuntu/
sudo apt install libjson-c-dev libuv1-dev libmicrohttpd-dev

read -n1 -p "PULSA [ENTER] PARA CONTINUAR O [CTRL+C] PARA PARAR EL SCRIPT"

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
wget https://github.com/johna23-lab/filezilla/raw/main/go1.16.4.linux-amd64.7z
7z x go1.16.4.linux-amd64.7z
popd



notify-send "Building a static version of gmp"
wget https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz -qO-|tar -C $SRC -xJ
pushd $SRC/gmp*/
./configure --build=x86_64 --prefix=$OUT --enable-static --disable-shared --enable-fat
make -j3 install
popd

notify-send "Building a static version of nettle"
wget https://ftp.gnu.org/gnu/nettle/nettle-3.6.tar.gz -qO-|tar -C $SRC -xz
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
wget https://sqlite.org/2018/sqlite-autoconf-3250300.tar.gz -qO-|tar -C $SRC -xz
pushd $SRC/sql*/
./configure --build=x86_64 --prefix=$OUT --enable-static --disable-shared
make -j3 install
popd

notify-send "Building a static version of wxWidgets"
#git clone --branch WX_3_0_BRANCH --single-branch https://github.com/wxWidgets/wxWidgets.git $SRC/wx3
pushd $SRC
wget https://github.com/johna23-lab/filezilla/raw/main/wx3.7z
7z x $SRC/wx3.7z
popd
pushd $SRC/wx3
./configure --prefix=$(pwd) --enable-monolithic  --disable-shared --enable-static --enable-unicode --with-libpng=builtin   --with-libjpeg=builtin  --with-libtiff=builtin  --with-zlib=builtin --with-expat=builtin
make -j3
popd


notify-send "Building a static version of libfilezilla"
#svn co https://svn.filezilla-project.org/svn/libfilezilla/trunk $SRC/libfilezilla
wget https://download.filezilla-project.org/libfilezilla/libfilezilla-0.28.0.tar.bz2 -qO-|tar -C $SRC -xj
pushd $SRC/libfilezilla*/
./configure --prefix=$OUT --enable-static --disable-shared
make -j3 install
popd

notify-send "Building a static version of libidn"
wget ftp://ftp.gnu.org/gnu/libidn/libidn2-2.3.0.tar.gz -qO-|tar -C $SRC -xz
pushd $SRC/libidn*/
./configure --prefix="$OUT" --enable-static --disable-shared
make -j3 install
popd


notify-send "Building libjstor"
git clone https://github.com/storj/libstorj.git $SRC/jstor
pushd $SRC/jstor*/
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
wget https://github.com/johna23-lab/filezilla/raw/main/FileZilla_3.54.1_src.txz -qO-|tar -C $SRC -xJ
pushd $SRC/filezilla*/
./configure --prefix="$OUT" --enable-static --disable-shared --with-pugixml=builtin --enable-storj 
make -j3 install
popd
time_end=`date +%s`
time_exec=`expr $(( $time_end - $time_start ))`
echo "EL PROCESO DE COMPILADO HA TARDADO UN TOTAL DE $(($time_exec / 60)) minutos y $(($time_exec % 60)) segundos."

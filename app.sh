### UNRAR ###
_build_unrar() {
local VERSION="5.3.4"
local FOLDER="unrar"
local FILE="unrarsrc-${VERSION}.tar.gz"
local URL="http://www.rarlab.com/rar/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
mv makefile Makefile
make CXX="${CXX}" CXXFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS} -pthread"
#make CXX="${CXX}" CXXFLAGS="${CFLAGS} -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS}"
#make CXX="${CXX}" CXXFLAGS="${CFLAGS} -I/home/drobo/xtools/toolchain/5n/arm-marvell-linux-gnueabi/libc/thumb2/usr/include/ -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS} -pthread"
#make CXX="${CXX}" CXXFLAGS="${CFLAGS} -I/home/drobo/xtools/toolchain/5n/arm-marvell-linux-gnueabi/libc/usr/include/ -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS} -pthread"
#make CXX="${CXX}" CXXFLAGS="${CFLAGS} -I/home/drobo/xtools/toolchain/arm-drobo_x86_64-linux-gnueabihf/arm-drobo_x86_64-linux-gnueabihf/include -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS} -pthread"
#make CXX="${CXX}" CXXFLAGS="${CFLAGS} -I/home/drobo/xtools/toolchain/arm-drobo_x86_64-linux-gnueabi/arm-drobo_x86_64-linux-gnueabi/usr/include/ -I/home/drobo/xtools/toolchain/arm-drobo_x86_64-linux-gnueabi/arm-drobo_x86_64-linux-gnueabi/include/ -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE" STRIP="${STRIP}" LDFLAGS="${LDFLAGS} -pthread"
make install DESTDIR="${DEST}"
mkdir -p "${DEST}/libexec"
mv "${DEST}/bin/unrar" "${DEST}/libexec/"
popd
}

### P7ZIP ###
_build_p7zip() {
local VERSION="9.38.1"
local FOLDER="p7zip_${VERSION}"
local FILE="${FOLDER}_src_all.tar.bz2"
local URL="http://sourceforge.net/projects/p7zip/files/p7zip/${VERSION}/${FILE}"

_download_bz2 "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
cp makefile.linux_cross_arm makefile.linux
make all3 CC="${CC} \$(ALLFLAGS)" CXX="${CXX} \$(ALLFLAGS)" OPTFLAGS="${CFLAGS}"
make install DEST_HOME="${DEPS}" DEST_BIN="${DEST}/libexec" DEST_SHARE="${DEST}/lib/p7zip"
popd
}

### ZLIB ###
_build_zlib() {
local VERSION="1.3.1"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib" --shared
make
make install
rm -v "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
#local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/old/1.0.2/${FILE}"
local URL="https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_2d/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### WGET ###
_build_wget() {
local VERSION="1.16.3"
local FOLDER="wget-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnu.org/gnu/wget/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEPS}" \
  --sysconfdir="${DEST}/etc" --bindir="${DEST}/libexec" \
  --with-ssl=openssl --with-openssl=yes --with-libssl-prefix="${DEST}" \
  --disable-pcre
make
make install
echo "ca_certificate = ${DEST}/etc/ssl/certs/ca-certificates.crt" >> "${DEST}/etc/wgetrc"
mv -f "${DEST}/etc/wgetrc" "${DEST}/etc/wgetrc.default"
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="5.9"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd target/"${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --datadir="${DEST}/share" --with-shared --enable-rpath --with-termlib=tinfo
make
make install
rm -v "${DEST}/lib"/*.a
popd
}

### LIBXML2 ###
_build_libxml2() {
local VERSION="2.9.2"
local FOLDER="libxml2-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="ftp://xmlsoft.org/libxml2/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_LIBDIR="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --disable-static \
  --without-python LIBS="-lz"
make
make install
popd
}

### NZBGET ###
_build_nzbget() {
local VERSION="24.5"
local FOLDER="nzbget-${VERSION}"
local FILE="${FOLDER}-src.tar.gz"
#local URL="https://github.com/nzbgetcom/nzbget/releases/download/v${VERSION}/${FILE}"
local URL="https://github.com/nzbgetcom/nzbget/archive/refs/tags/v24.5.tar.gz"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
mkdir build
pushd "build"
export CC="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-gcc"
export CXX="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-g++"
#export CXX="/home/drobo/xtools/toolchain/arm-drobo_x86_64-linux-gnueabihf/bin/arm-drobo_x86_64-linux-gnueabihf-g++"
export AR="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-ar"
export AS="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-as"
export RANLIB="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-ranlib"
export STRIP="/home/drobo/xtools/toolchain/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin/arm-none-eabi-strip"
cmake .. -DCMAKE_INSTALL_PREFIX="${DEST}"
#./configure --host="${HOST}" --prefix="${DEST}" \
#  --with-zlib-includes="${DEPS}/include" --with-zlib-libraries="${DEST}/lib" \
#  --with-tlslib=OpenSSL --with-openssl-includes="${DEPS}/include" --with-openssl-libraries="${DEST}/lib" \
#  --with-libcurses-includes="${DEPS}/include" --with-libcurses-libraries="${DEST}/lib" \
#  --with-libxml2-includes="${DEPS}/include/libxml2" --with-libxml2-libraries="${DEST}/lib"

#make
#make install
cmake --build .
cmake --install
#popd
mv -v "${DEST}/share/nzbget/webui" "${DEST}/app"
mv -v "${DEST}/share/nzbget/nzbget.conf" "${DEST}/etc/nzbget.conf.default"
sed -e "s|^MainDir=.*|MainDir=/mnt/DroboFS/Shares/Public/Downloads|g" \
    -e "s|^DestDir=.*|DestDir=\${MainDir}/complete|g" \
    -e "s|^InterDir=.*|InterDir=\${MainDir}/incomplete|g" \
    -e "s|^NzbDir=.*|NzbDir=\${MainDir}/watch|g" \
    -e "s|^LockFile=.*|LockFile=/tmp/DroboApps/nzbget/pid.txt|g" \
    -e "s|^LogFile=.*|LogFile=/tmp/DroboApps/nzbget/nzbget.log|g" \
    -e "s|^ConfigTemplate=.*|ConfigTemplate=/mnt/DroboFS/Shares/DroboApps/nzbget/etc/nzbget.conf.default|g" \
    -e "s|^WebDir=.*|WebDir=/mnt/DroboFS/Shares/DroboApps/nzbget/app|g" \
    -e "s|^UMask=.*|UMask=0002|g" \
    -e "s|^UnrarCmd=.*|UnrarCmd=/mnt/DroboFS/Shares/DroboApps/nzbget/libexec/unrar|g" \
    -e "s|^SevenZipCmd=.*|SevenZipCmd=/mnt/DroboFS/Shares/DroboApps/nzbget/libexec/7z|g" \
    -i "${DEST}/etc/nzbget.conf.default"
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
ln -vfs certs/ca-certificates.crt "${DEST}/etc/ssl/cert.pem"
}

_build() {
  _build_unrar
  _build_p7zip
  _build_zlib
  _build_openssl
  _build_ncurses
  _build_libxml2
  _build_nzbget
  _build_wget
  _build_certificates
  _package
}

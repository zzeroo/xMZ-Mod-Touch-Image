# cross-env.sh
# idee stolen from here: http://www.lanedo.com/cross-compiling-directfb-for-an-embedded-device/
# modified by zzeroo <co@zzeroo.com>
#
TOOLCHAIN=/usr

# Setup Binaries, these are installed via debian's apt
# TODO: apt-get install gcc:armhf find right command
export PATH=$TOOLCHAIN/bin:$PATH
export CC=arm-linux-gnueabihf-gcc
export CXX=arm-linux-gnueabihf-g++
export AR=arm-linux-gnueabihf-ar
export RANLIB=arm-linux-gnueabihf-ranlib
export LD=arm-linux-gnueabihf-ld

# This is where the libraties of the target plattform live, this is the sysroot
# of all our images, too.
export SYSROOT=/var/lib/container/sid_armhf-crosscompile-environment

# export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig"
export PKG_CONFIG_PATH="$SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig"
export ACLOCAL_FLAGS="-I$SYSROOT/usr/share/aclocal"
export CPPFLAGS="-I$SYSROOT/usr/include/arm-linux-gnueabihf"
export LDFLAGS="-L$SYSROOT/usr/lib/arm-linux-gnueabihf"
export LD_LIBRARY_PATH="$SYSROOT/usr/lib/arm-linux-gnueabihf"

export LIBXML_CFLAGS="-I$SYSROOT/usr/include/libxml2"
export LIBXML_LIBS="-L$SYSROOT/usr/lib/arm-linux-gnueabihf -lxml2"

# set the terminal title and prompt so we always see where we are
echo -en "\033]0;$CROSS_PREFIX - cross ARM env\a"
echo $PS1 |grep cross >/dev/null || export PS1="[cross ARM] $PS1"

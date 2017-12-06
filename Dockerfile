FROM centos:7

# install FFmpeg according to the official documentation on how to install
# FFmpeg on CentOS: https://trac.ffmpeg.org/wiki/CompilationGuide/Centos

# Get the Dependencies
RUN yum install -y autoconf automake bzip2 cmake freetype-devel gcc gcc-c++ git libtool make mercurial pkgconfig zlib-devel

RUN mkdir /tmp/ffmpeg_sources

# NASM
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://www.nasm.us/pub/nasm/releasebuilds/2.13.01/nasm-2.13.01.tar.bz2 && \
    tar xjvf nasm-2.13.01.tar.bz2 && \
    cd nasm-2.13.01 && \
    ./autogen.sh && \
    ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" && \
    make && \
    make install

# Yasm
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz && \
    tar xzvf yasm-1.3.0.tar.gz && \
    cd yasm-1.3.0 && \
    ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" && \
    make && \
    make install

# libx264
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 http://git.videolan.org/git/x264 && \
    cd x264 && \
    PATH="$PATH:/tmp/bin" PKG_CONFIG_PATH="/tmp/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" --enable-static && \
    PATH="$PATH:/tmp/bin" make && \
    make install

# libx265
RUN cd /tmp/ffmpeg_sources && \
    hg clone https://bitbucket.org/multicoreware/x265 && \
    cd /tmp/ffmpeg_sources/x265/build/linux && \
    cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="/tmp/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source && \
    make && \
    make install

# libfdk_aac
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --prefix="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libmp3lame
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz && \
    tar xzvf lame-3.100.tar.gz && \
    cd lame-3.100 && \
    ./configure --prefix="/tmp/ffmpeg_build" --bindir="/tmp/bin" --disable-shared --enable-nasm && \
    make && \
    make install

# libopus
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L https://archive.mozilla.org/pub/opus/opus-1.2.tar.gz && \
    tar xzvf opus-1.2.tar.gz && \
    cd opus-1.2 && \
    PKG_CONFIG_PATH="/tmp/ffmpeg_build/lib/pkgconfig" ./configure --prefix="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libogg
RUN cd /tmp/ffmpeg_sources && \
    curl -L -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz && \
    tar xzvf libogg-1.3.2.tar.gz && \
    cd libogg-1.3.2 && \
    ./configure --prefix="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libvorbis
RUN cd /tmp/ffmpeg_sources && \
    curl -O -L http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.5.tar.gz && \
    tar xzvf libvorbis-1.3.5.tar.gz && \
    cd libvorbis-1.3.5 && \
    ./configure --prefix="/tmp/ffmpeg_build" --with-ogg="/tmp/ffmpeg_build" --disable-shared && \
    make && \
    make install

# libvpx
RUN cd /tmp/ffmpeg_sources && \
    git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && \
    cd libvpx && \
    ./configure --prefix="/tmp/ffmpeg_build" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm && \
    PATH="$PATH:/tmp/bin" make && \
    make install

# FFmpeg
RUN cd /tmp/ffmpeg_sources && \
    curl -O http://ffmpeg.org/releases/ffmpeg-3.4.tar.bz2 && \
    tar xjvf ffmpeg-3.4.tar.bz2 && \
    cd ffmpeg-3.4 && \
    PATH="$PATH:/tmp/bin" PKG_CONFIG_PATH="/tmp/ffmpeg_build/lib/pkgconfig" ./configure \
        --pkg-config-flags="--static" \
        --extra-cflags="-I/tmp/ffmpeg_build/include" \
        --extra-ldflags="-L/tmp/ffmpeg_build/lib -ldl" \
        --extra-libs=-lpthread \
        --enable-gpl --enable-libfdk_aac --enable-libfreetype --enable-libmp3lame --enable-libopus --enable-libvorbis \
        --enable-libvpx --enable-libx264 --enable-libx265 --enable-nonfree && \
    PATH="$PATH:/tmp/bin" make && \
    make install && \
    hash -r

# cleanup
RUN rm -r /tmp/ffmpeg_sources && \
    rm -r /tmp/bin

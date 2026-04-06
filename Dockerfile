FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Tooling needed for builds + downloads + xz extraction + vasm build.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    make \
    bash \
    zip \
    xz-utils \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# ---- Install MiNT ELF toolchain by extracting tarballs directly to / ----
# (As per your instructions)
WORKDIR /tmp/mint

RUN set -eux; \
  wget -O binutils.tar.xz "https://tho-otto.de/download/mint/binutils-2.45-mintelf-20250812-bin-linux64.tar.xz"; \
  wget -O gcc.tar.xz      "https://tho-otto.de/download/mint/gcc-15.2.0-mintelf-20250810-bin-linux64.tar.xz"; \
  wget -O mintlib.tar.xz  "https://tho-otto.de/download/mint/mintlib-0.60.1-mintelf-20240718-dev.tar.xz"; \
  wget -O fdlibm.tar.xz   "https://tho-otto.de/download/mint/fdlibm-20240425-mintelf-dev.tar.xz"; \
  wget -O gemlib.tar.xz   "https://tho-otto.de/download/mint/gemlib-0.44.0-mintelf-20240425-dev.tar.xz"; \
  tar -C / -xJf binutils.tar.xz; \
  tar -C / -xJf gcc.tar.xz; \
  tar -C / -xJf mintlib.tar.xz; \
  tar -C / -xJf fdlibm.tar.xz; \
  tar -C / -xJf gemlib.tar.xz; \
  rm -f *.tar.xz

# Make sure /usr/local/bin is on PATH (it is usually, but keep explicit)
ENV PATH="/usr/local/bin:/usr/bin:/bin:/opt/fpc/lib/fpc/3.3.1:${PATH}"

# ---- Build and install VASM (vasmm68k_mot) ----
WORKDIR /tmp/vasm
RUN set -eux; \
  wget -O vasm.tar.gz "http://sun.hasenbraten.de/vasm/release/vasm.tar.gz"; \
  tar -xzf vasm.tar.gz; \
  # archive unpacks into "vasm/" directory
  cd vasm; \
  make CPU=m68k SYNTAX=mot; \
  make CPU=m68k SYNTAX=std; \
  install -m 0755 vasmm68k_mot /usr/local/bin/vasmm68k_mot; \
  install -m 0755 vasmm68k_std /usr/local/bin/vasmm68k_std; \
  ln -s /usr/local/bin/vasmm68k_std /usr/local/bin/m68k-atari-vasmm68k_std; \
  cd /; \
  rm -rf /tmp/vasm;

# ---- Build and install VLINK ----
WORKDIR /tmp/vlink
RUN set -eux; \
  wget -O vlink.tar.gz "http://sun.hasenbraten.de/vlink/release/vlink.tar.gz"; \
  tar -xzf vlink.tar.gz; \
  # archive unpacks into "vlink/" directory
  cd vlink; \
  make; \
  install -m 0755 vlink /usr/local/bin/vlink; \
  cd /; \
  rm -rf /tmp/vlink

# ---- Prepare workspace layout expected by project Makefile ----
# project Makefile uses:
#   CMINI_DIR = ../libcmini
#   GODLIB_DIR = ../godlib
WORKDIR /work
RUN set -eux; \
  git clone --depth 1 https://github.com/ktz-st/libcmini.elf libcmini; \
  git clone --depth 1 https://github.com/ktz-st/godlib.elf godlib

# ---- Build and install FreePascal ----
WORKDIR /tmp/fpc
RUN set -eux; \
  wget -O fpc-laz_3.2.2-210709_amd64.deb "https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%204.6/fpc-laz_3.2.2-210709_amd64.deb/download"; \
  dpkg -i fpc-laz_3.2.2-210709_amd64.deb; \
  rm -f fpc-laz_3.2.2-210709_amd64.deb; \
  git clone https://github.com/fpc/FPCSource; \
  cd FPCSource; \
  # Build the compiler (this will take a while)
  make clean crossall crossinstall OS_TARGET=atari CPU_TARGET=m68k CROSSOPT="-Avasm -Cp68000" INSTALL_PREFIX="/opt/fpc"; \
  # Cleanup source and archive
  cd /; \
  rm -rf /tmp/fpc/FPCSource
COPY fpc.cfg /opt/fpc/etc/fpc.cfg

# ---- Verify installations ----
  RUN set -eux; \
  m68k-atari-mintelf-gcc --version; \
  vasmm68k_mot -v || true; \
  vasm68k_std -v || true; \
  vlink -v || true; \
  fpc -iV; \
  ppcross68k -iV || true
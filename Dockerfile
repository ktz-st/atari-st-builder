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
ENV PATH="/usr/local/bin:/usr/bin:/bin:${PATH}"

# ---- Build and install VASM (vasmm68k_mot) ----
WORKDIR /tmp/vasm
RUN set -eux; \
  wget -O vasm.tar.gz "http://sun.hasenbraten.de/vasm/daily/vasm.tar.gz"; \
  tar -xzf vasm.tar.gz; \
  # archive unpacks into "vasm/" directory
  cd vasm; \
  make CPU=m68k SYNTAX=mot; \
  install -m 0755 vasmm68k_mot /usr/local/bin/vasmm68k_mot; \
  cd /; \
  rm -rf /tmp/vasm

# ---- Prepare workspace layout expected by project Makefile ----
# project Makefile uses:
#   CMINI_DIR = ../libcmini
#   GODLIB_DIR = ../godlib
WORKDIR /work
RUN set -eux; \
  git clone --depth 1 https://github.com/ktz-st/libcmini.elf libcmini; \
  git clone --depth 1 https://github.com/ktz-st/godlib.elf godlib

# Sanity checks (optional but helpful)
RUN set -eux; \
  m68k-atari-mintelf-gcc --version; \
  vasmm68k_mot -v || true
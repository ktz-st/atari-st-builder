# atari-st-builder

Docker image for building Atari ST (m68k-atari-mintelf) projects in CI.

Includes:
- MiNT ELF toolchain (binutils + gcc + dev libs) extracted to `/` from tho-otto.de tarballs
- `vasmm68k_mot` built from the daily VASM tarball
- `ktz-st/libcmini.elf` cloned to `/work/libcmini`
- `ktz-st/godlib.elf` cloned to `/work/godlib`

Default working directory:
- `/work/project`

This layout matches projects whose Makefile references:
- `../libcmini`
- `../godlib`

## Publish the image to GHCR

Actions → **Publish GHCR image** → Run workflow  
Pick a tag (e.g. `v1`), and it will publish:
- `ghcr.io/<owner>/atari-st-builder:<tag>`
- `ghcr.io/<owner>/atari-st-builder:latest`

## Use in another repo (GitHub Actions)

Example:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/<owner>/atari-st-builder:latest
    steps:
      - uses: actions/checkout@v4
        with:
          path: project
      - run: |
          cd project
          make clean && make
```
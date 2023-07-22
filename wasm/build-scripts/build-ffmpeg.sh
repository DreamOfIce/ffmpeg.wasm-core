#!/bin/bash

set -eo pipefail
source $(dirname $0)/var.sh

if [[ "$FFMPEG_ST" != "yes" ]]; then
  mkdir -p packages/core-mt/dist
  EXPORTED_FUNCTIONS="[_main, _free, _malloc, lengthBytesUTF8, stringToUTF8, UTF8ToString]"
  EXTRA_FLAGS=(
    -pthread                                      # enable pthreads support
#    -s PROXY_TO_PTHREAD=1                         # detach main() from browser/UI main thread
    -o packages/core-mt/dist/ffmpeg-core.js
		-s INITIAL_MEMORY=1073741824                  # 1GB
  )
else
  mkdir -p packages/core-st/dist
  EXPORTED_FUNCTIONS="[_main, _free, _malloc, lengthBytesUTF8, stringToUTF8, UTF8ToString]"
  EXTRA_FLAGS=(
    -o packages/core-st/dist/ffmpeg-core.js
		-s INITIAL_MEMORY=33554432                    # 32MB
		-s MAXIMUM_MEMORY=1073741824                  # 1GB
		-s ALLOW_MEMORY_GROWTH=1
  )
fi
FLAGS=(
  -I. -I./fftools -I$BUILD_DIR/include
  -Llibavcodec -Llibavdevice -Llibavfilter -Llibavformat -Llibavresample -Llibavutil -Lharfbuzz -Llibass -Lfribidi -Llibpostproc -Llibswscale -Llibswresample -L$BUILD_DIR/lib
  -Wno-deprecated-declarations -Wno-pointer-sign -Wno-implicit-int-float-conversion -Wno-switch -Wno-parentheses -Qunused-arguments
  -lavdevice -lavfilter -lavformat -lavcodec -lswresample -lswscale -lavutil -lpostproc -lm -lharfbuzz -lfribidi -lass -lx264 -lx265 -lvpx -lwavpack -lmp3lame -lfdk-aac -lvorbis -lvorbisenc -lvorbisfile -logg -ltheora -ltheoraenc -ltheoradec -lz -lfreetype -lopus -lwebp
  fftools/ffmpeg_opt.c fftools/ffmpeg_filter.c fftools/ffmpeg_hw.c fftools/cmdutils.c fftools/ffmpeg.c wasm/src/entry.cpp
  --bind
  -s USE_SDL=2                                                 # use SDL2
  -s INVOKE_RUN=1                                              # run the main() in the beginning
  -s EXIT_RUNTIME=1                                            # exit runtime after execution
  -s MODULARIZE=1                                              # use modularized version to be more flexible
  -s EXPORT_NAME="createFFmpegCore"                            # assign export name for browser
  -s ALLOW_TABLE_GROWTH                                        # allow new functions to be added to the table
  -s EXPORTED_FUNCTIONS="$EXPORTED_FUNCTIONS"                  # export main and proxy_main funcs
  -s EXPORTED_RUNTIME_METHODS="[FS, addFunction, cwrap, ccall, setValue]"   # export preamble funcs
  --post-js wasm/src/post.js
  $OPTIM_FLAGS
  ${EXTRA_FLAGS[@]}
)
echo "FFMPEG_EM_FLAGS=${FLAGS[@]}"
emmake make -j
emcc "${FLAGS[@]}"

#!/bin/bash
# mayhem/build.sh — builds the dr_libs fuzz target, its standalone reproducer, the upstream test
# suite, and deterministic test vectors. Idempotent and air-gapped: every tool/library used here
# (clang, cmake, python3, flac, lame, libFLAC, libsndfile) is baked into the image by mayhem/Dockerfile,
# so a re-run needs no network.
set -euxo pipefail

cd "${SRC:-/mayhem}"

export SANITIZER_FLAGS="${SANITIZER_FLAGS:--fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
DEBUG_FLAGS="-g -gdwarf-3"          # Mayhem triage needs DWARF <= 3 (clang-19 default -g is DWARF-5)
CC="${CC:-clang}"
LIB_FUZZING_ENGINE="${LIB_FUZZING_ENGINE:--fsanitize=fuzzer}"
STANDALONE_FUZZ_MAIN="${STANDALONE_FUZZ_MAIN:-/opt/mayhem/StandaloneFuzzTargetMain.c}"

# 1) Fuzz target (historical name: drlibs-fuzz / fuzz_dr_flac). mayhem/flac_fuzz.c is upstream's
#    own libFuzzer harness (tests/flac/flac_fuzz.c) ported to the current dr_flac callback API
#    (upstream's copy is stale and no longer compiles). It compiles dr_flac.h into the same TU,
#    so the whole decoder is sanitizer-instrumented.
$CC $SANITIZER_FLAGS $DEBUG_FLAGS ${COVERAGE_FLAGS:-} $LIB_FUZZING_ENGINE \
    mayhem/flac_fuzz.c -o fuzz_dr_flac

# 2) Standalone reproducer (same harness, file-driven main).
$CC $SANITIZER_FLAGS $DEBUG_FLAGS \
    "$STANDALONE_FUZZ_MAIN" mayhem/flac_fuzz.c -o fuzz_dr_flac-standalone

# 3) Upstream test suite, NORMAL flags (mayhem/test.sh RUNS it; it does not compile).
#    Build only the non-playback tests: the *_playback tests need the tests/external/miniaudio
#    submodule (not shipped in-tree) and a real audio device, neither of which exists here.
cmake -S . -B mayhem/build-tests -DDR_LIBS_BUILD_TESTS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build mayhem/build-tests -j"$(nproc)" --target \
    wav_decoding wav_decoding_cpp wav_encoding \
    flac_decoding flac_decoding_cpp flac_seeking \
    mp3_basic mp3_extract

# 4) Deterministic test vectors for the suite (python stdlib PCM synth + in-image flac/lame encoders).
python3 mayhem/gen_vectors.py

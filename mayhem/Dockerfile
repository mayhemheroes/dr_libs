# COMMIT-tier image for dr_libs: full source + .git + toolchain, non-root, re-runnable build.
FROM ghcr.io/mayhemheroes/base:20260621

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS
ARG COVERAGE_FLAGS=
ARG MAYHEM_JOBS=

# Reference libraries + encoders for the upstream test suite:
#   libFLAC (flac_* tests compare dr_flac against it), libsndfile (wav_* tests dlopen it),
#   flac + lame CLIs (deterministic FLAC/MP3 test-vector generation in mayhem/build.sh).
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends libflac-dev libsndfile1-dev libsndfile1 flac lame && \
    rm -rf /var/lib/apt/lists/*

USER mayhem
WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

RUN bash mayhem/build.sh

RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh — repo ships no functional tests"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem

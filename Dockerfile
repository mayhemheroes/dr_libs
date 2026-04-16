FROM --platform=linux/amd64 ubuntu:22.04

COPY . .

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y clang

RUN clang -g -O1 -fsanitize=fuzzer,address -o /fuzz_dr_flac /tests/flac/flac_fuzz.c

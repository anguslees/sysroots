# syntax=docker/dockerfile:1.4@sha256:9ba7531bd80fb0a858632727cf7a112fbfd19b17e94c4e84ced81e24ef1a0dbc
#
# docker buildx build . --output=type=local,dest=/tmp --platform=linux/amd64,linux/arm64
#

FROM --platform=$BUILDPLATFORM public.ecr.aws/ubuntu/ubuntu:22.04 AS builder

RUN apt-get update -q

RUN \
    apt-get install -y -q --no-install-recommends \
    tar xz-utils

COPY --link mksysroot /

FROM --platform=$TARGETPLATFORM public.ecr.aws/amazonlinux/amazonlinux:2 AS amzn2

RUN \
    yum install -y -q \
    glibc-devel gcc gcc-c++

FROM --platform=$BUILDPLATFORM builder AS sysroot-amzn2
RUN --mount=type=bind,from=amzn2,target=/sysroot /mksysroot

FROM --platform=$TARGETPLATFORM public.ecr.aws/ubuntu/ubuntu:22.04 AS ubuntu-22-04

RUN apt-get update -q

RUN \
    apt-get install -y -q --no-install-recommends \
    gcc libc6-dev libstdc++-11-dev

FROM --platform=$BUILDPLATFORM builder AS sysroot-ubuntu-22-04
RUN --mount=type=bind,from=ubuntu-22-04,target=/sysroot /mksysroot

FROM --platform=$TARGETPLATFORM public.ecr.aws/docker/library/alpine:3.18 AS alpine-3-18

RUN \
    apk add -q \
    musl-dev gcc

FROM --platform=$BUILDPLATFORM builder AS sysroot-alpine-3-18
RUN --mount=type=bind,from=alpine-3-18,target=/sysroot /mksysroot

FROM --platform=$TARGETPLATFORM scratch AS tarballs
ARG TARGETARCH
COPY --link --from=sysroot-amzn2 /sysroot.tar.xz /sysroot-amzn2-${TARGETARCH}.tar.xz
COPY --link --from=sysroot-ubuntu-22-04 /sysroot.tar.xz /sysroot-ubuntu-22-04-${TARGETARCH}.tar.xz
COPY --link --from=sysroot-alpine-3-18 /sysroot.tar.xz /sysroot-alpine-3-18-${TARGETARCH}.tar.xz

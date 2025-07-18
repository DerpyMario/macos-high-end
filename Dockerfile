FROM --platform=$BUILDPLATFORM alpine:3.21 AS builder

ARG VERSION_OPENCORE="1.0.4"
ARG REPO_OPENCORE="https://github.com/acidanthera/OpenCorePkg"
ADD $REPO_OPENCORE/releases/download/$VERSION_OPENCORE/OpenCore-$VERSION_OPENCORE-RELEASE.zip /tmp/opencore.zip

RUN apk --update --no-cache add unzip && \
    unzip /tmp/opencore.zip -d /tmp/oc && \
    cp /tmp/oc/Utilities/macserial/macserial.linux /macserial && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

FROM scratch AS runner
COPY --from=qemux/qemu:7.12 / /

ARG VERSION_ARG="0.0"
ARG VERSION_KVM_OPENCORE="v21"
ARG VERSION_OSX_KVM="326053dd61f49375d5dfb28ee715d38b04b5cd8e"
ARG REPO_OSX_KVM="https://raw.githubusercontent.com/kholia/OSX-KVM"
ARG REPO_KVM_OPENCORE="https://github.com/thenickdude/KVM-Opencore"

ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
    xxd \
    fdisk \
    mtools && \
    apt-get clean && \
    echo "$VERSION_ARG" > /run/version && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /assets/
COPY --chmod=755 --from=builder /macserial /usr/local/bin/

ADD --chmod=644 \
    $REPO_OSX_KVM/$VERSION_OSX_KVM/OVMF_CODE.fd \
    $REPO_OSX_KVM/$VERSION_OSX_KVM/OVMF_VARS.fd \
    $REPO_OSX_KVM/$VERSION_OSX_KVM/OVMF_VARS-1024x768.fd \
    $REPO_OSX_KVM/$VERSION_OSX_KVM/OVMF_VARS-1280x1024.fd /usr/share/OVMF/

ADD $REPO_KVM_OPENCORE/releases/download/$VERSION_KVM_OPENCORE/OpenCore-$VERSION_KVM_OPENCORE.iso.gz /opencore.iso.gz

VOLUME /storage
EXPOSE 5900 8006

ENV VERSION="15"
ENV RAM_SIZE="8G"
ENV CPU_CORES="2"
ENV DISK_SIZE="45G"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]

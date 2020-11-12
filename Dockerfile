FROM ubuntu:focal AS builder
WORKDIR /usr
#RUN apk add --update git alpine-sdk linux-headers
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y git build-essential libc6-dev-i386 curl ca-certificates libfuse-dev pkg-config unzip
WORKDIR /usr/
ENV INFERNO_BRANCH=master
ENV INFERNO_COMMIT=ed97654bd7a11d480b44505c8300d06b42e5fefe
  
# fixme

RUN git clone --depth 1 -b ${INFERNO_BRANCH} https://bitbucket.org/inferno-os/inferno-os 
WORKDIR /usr/inferno-os
ADD files/inferno/*.patch /usr/inferno-os/
RUN export PATH=$PATH:/usr/inferno-os/Linux/386/bin &&\
    export MKFLAGS='SYSHOST=Linux OBJTYPE=386 CONF=emu-g ROOT='/usr/inferno-os &&\
    cat mkconfig.patch | patch -p1 &&\
    . ./mkconfig &&\
    ./makemk.sh &&\
    mk $MKFLAGS mkdirs         &&\
    mk $MKFLAGS emuinstall     &&\                
    mk $MKFLAGS emunuke        

RUN export OS=`uname -s| tr '[:upper:]' '[:lower:]'` &&\
  export RELEASE=`curl -s https://api.github.com/repos/kubeless/kubeless/releases/latest | grep tag_name | cut -d '"' -f 4)` &&\
  curl -OL https://github.com/kubeless/kubeless/releases/download/$RELEASE/kubeless_$OS-amd64.zip && \
  unzip kubeless_$OS-amd64.zip && \
  mv bundles/kubeless_$OS-amd64/kubeless /usr/local/bin/


RUN apt-get install -y python3-pip
RUN pip3 install jinja2-cli install jinja2-ansible-filters
WORKDIR /tmp
RUN git clone --depth=1 -b wrapper http://github.com/metacoma/execfuse
WORKDIR /tmp/execfuse
RUN make execfuse-static
RUN cp ./execfuse-static /usr/local/bin/execfuse-static
WORKDIR /tmp/execfuse/wrapper
ADD files/execfuse/sls.yml /tmp/execfuse/wrapper
RUN cat sls.yml | ./wrapper.sh
RUN cp -vr compiled/ /slsfs

#RUN echo hi | /usr/inferno-os/Linux/386/bin/emu-g 

FROM ubuntu:focal
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y \
  libc6-dev-i386    
RUN apt-get install --no-install-recommends -y \
  curl              \
  ca-certificates   \
  npm               \
  jq                
ENV ROOT_DIR /usr/inferno-os
COPY --from=builder /usr/inferno-os/Linux/386/bin/emu-g /usr/bin
COPY --from=builder /usr/inferno-os/dis $ROOT_DIR/dis
COPY --from=builder /usr/inferno-os/appl $ROOT_DIR/appl
COPY --from=builder /usr/inferno-os/lib $ROOT_DIR/lib
COPY --from=builder /usr/inferno-os/module $ROOT_DIR/module
COPY --from=builder /usr/inferno-os/usr $ROOT_DIR/usr
COPY --from=builder /usr/local/bin/kubeless /usr/local/bin/kubeless
COPY --from=builder /usr/local/bin/execfuse-static /usr/local/bin/execfuse-static
ADD files/inferno/profile /usr/inferno-os/lib/sh/profile

RUN npm install -g npm
RUN curl -o- -L https://slss.io/install | bash

RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_386 && \
  chmod +x /usr/local/bin/yq

WORKDIR /usr/local/bin
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x kubectl

RUN mkdir -p /usr/inferno-os/host/slsfs

COPY --from=builder /slsfs /slsfs

ENTRYPOINT ["sh", "-c", "execfuse-static /slsfs /usr/inferno-os/host/slsfs && emu-g /dis/sh /lib/sh/profile"]

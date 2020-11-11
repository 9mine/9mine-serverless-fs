FROM i386/node:lts-alpine AS builder
WORKDIR /usr
RUN apk add --update git alpine-sdk linux-headers
WORKDIR /usr/
ENV INFERNO_BRANCH=master
ENV INFERNO_COMMIT=ed97654bd7a11d480b44505c8300d06b42e5fefe
  
# fixme

RUN git clone --depth 1 -b ${INFERNO_BRANCH} https://bitbucket.org/inferno-os/inferno-os 
WORKDIR /usr/inferno-os
ADD files/inferno/*.patch /usr/inferno-os/
RUN export PATH=$PATH:/usr/inferno-os/Linux/386/bin &&\
    export MKFLAGS='SYSHOST=Linux OBJTYPE=386 CONF=emu-g ROOT='/usr/inferno-os &&\
    (cat disable_freetype.patch mkconfig.patch pthread_yield_define.patch) | patch -p1 &&\
    . ./mkconfig &&\
    ./makemk.sh &&\
    mk $MKFLAGS mkdirs         &&\
    mk $MKFLAGS emuinstall     &&\                
    mk $MKFLAGS emunuke        

#FROM i386/node:lts-alpine
#ENV ROOT_DIR /usr/inferno-os
##
#COPY --from=builder /usr/inferno-os/Linux/386/bin/emu-g /usr/bin
#COPY --from=builder /usr/inferno-os/dis $ROOT_DIR/dis
#COPY --from=builder /usr/inferno-os/appl $ROOT_DIR/appl
#COPY --from=builder /usr/inferno-os/lib $ROOT_DIR/lib
#COPY --from=builder /usr/inferno-os/module $ROOT_DIR/module
#COPY --from=builder /usr/inferno-os/usr $ROOT_DIR/usr
#
#RUN npm i npm@latest -g
#RUN npm install -g serverless
#
#
#ENTRYPOINT ["emu-g"]

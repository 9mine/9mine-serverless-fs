FROM dievri/9p-execfuse-jinja2:master
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install --no-install-recommends -y \
  curl              \
  ca-certificates   \
  npm               \
  unzip             \
  jq                

RUN npm install -g npm
RUN curl -o- -L https://slss.io/install | bash

RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_386 && \
  chmod +x /usr/local/bin/yq

RUN export OS=`uname -s| tr '[:upper:]' '[:lower:]'` &&\
  export RELEASE=`curl -s https://api.github.com/repos/kubeless/kubeless/releases/latest | grep tag_name | cut -d '"' -f 4)` &&\
  curl -OL https://github.com/kubeless/kubeless/releases/download/$RELEASE/kubeless_$OS-amd64.zip &&\ 
  unzip kubeless_$OS-amd64.zip && \
  mv bundles/kubeless_$OS-amd64/kubeless /usr/local/bin/

WORKDIR /usr/local/bin
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x kubectl

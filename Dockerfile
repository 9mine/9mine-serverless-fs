FROM dievri/9p-execfuse-jinja2:master
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get install --no-install-recommends -y \
  curl              \
  ca-certificates   \
  npm               \
  jq                

RUN npm install -g npm
RUN curl -o- -L https://slss.io/install | bash

RUN curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_386 && \
  chmod +x /usr/local/bin/yq

WORKDIR /usr/local/bin
RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod +x kubectl

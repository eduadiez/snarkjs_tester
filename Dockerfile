FROM  ubuntu:18.04

ARG CIRCOM_VERSION=0.5.17
ARG SNARKJS_VERSION=0.3.12
ARG NODE_VERSION=14.7.0 

WORKDIR /usr/src/app

ENV NVM_DIR=/usr/bin

RUN apt-get update && \
    apt install -y curl git && \
    curl https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh | bash  && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install ${NODE_VERSION} && \
    nvm use ${NODE_VERSION} && \ 
    npm install -g circom@${CIRCOM_VERSION} && \
    npm install -g snarkjs@${SNARKJS_VERSION} 

COPY entrypoint.sh /usr/local/bin/entrypoint
ENTRYPOINT [ "entrypoint" ]
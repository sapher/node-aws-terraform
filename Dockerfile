# Setup build arguments with default versions
ARG AWS_CLI_VERSION=1.18.39
ARG TF_VERSION=0.12.24
ARG PYTHON_MAJOR_VERSION=3.7

# Terraform
FROM debian:buster-20200327-slim as terraform
ARG TF_VERSION
RUN apt-get update
RUN apt-get install -y curl=7.64.0-4+deb10u1
RUN apt-get install -y unzip=6.0-23+deb10u1
RUN apt-get install -y gnupg=2.2.12-1+deb10u1
RUN curl -Os https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS
RUN curl -Os https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
RUN curl -Os https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_SHA256SUMS.sig
COPY hashicorp.asc hashicorp.asc
RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TF_VERSION}_SHA256SUMS.sig terraform_${TF_VERSION}_SHA256SUMS
RUN grep terraform_${TF_VERSION}_linux_amd64.zip terraform_${TF_VERSION}_SHA256SUMS | sha256sum -c -
RUN unzip -j terraform_${TF_VERSION}_linux_amd64.zip

# AWS
FROM debian:buster-20200327-slim as aws
ARG AWS_CLI_VERSION
ARG PYTHON_MAJOR_VERSION
ARG NODE_VERSION
ARG NVM_VERSION
RUN apt-get update
RUN apt-get install -y python3=${PYTHON_MAJOR_VERSION}.3-1
RUN apt-get install -y python3-pip=18.1-5
RUN pip3 install awscli==${AWS_CLI_VERSION}

# Final image
FROM node:12.9.1-buster-slim
ARG PYTHON_MAJOR_VERSION
WORKDIR /workspace
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    python3=${PYTHON_MAJOR_VERSION}.3-1 \
    && jq=1.5+dfsg-2+b1 \
    && git=1:2.20.1-2+deb10u1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_MAJOR_VERSION} 1
COPY --from=terraform /terraform /usr/local/bin/terraform
COPY --from=aws /usr/local/bin/aws* /usr/local/bin/
COPY --from=aws /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages /usr/local/lib/python${PYTHON_MAJOR_VERSION}/dist-packages
COPY --from=aws /usr/lib/python3/dist-packages /usr/lib/python3/dist-packages
CMD ["bash"]
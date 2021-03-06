FROM nvidia/cuda:8.0-cudnn5-devel-ubuntu16.04
MAINTAINER Nimbix, Inc. <support@nimbix.net>

# Nimbix base OS
ENV DEBIAN_FRONTEND noninteractive
ADD https://github.com/nimbix/image-common/archive/master.zip /tmp/nimbix.zip
WORKDIR /tmp
RUN apt-get update && apt-get -y install sudo zip unzip && unzip nimbix.zip && rm -f nimbix.zip
RUN /tmp/image-common-master/setup-nimbix.sh
RUN touch /etc/init.d/systemd-logind
RUN apt-get -y install \
  locales \
  module-init-tools \
  xz-utils \
  vim \
  openssh-server \
  libpam-systemd \
  libmlx4-1 \
  libmlx5-1 \
  iptables \
  infiniband-diags \
  build-essential \
  curl \
  libibverbs-dev \
  libibverbs1 \
  librdmacm1 \
  librdmacm-dev \
  rdmacm-utils \
  libibmad-dev \
  libibmad5 \
  byacc \
  flex \
  git \
  cmake \
  screen \
  wget \
  software-properties-common \
  python-software-properties \ 
  grep

# Clean and generate locales
RUN \
  apt-get clean && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8

# Setup Repos
RUN \
  echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | sudo tee -a /etc/apt/sources.list && \
  gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
  gpg -a --export E084DAB9 | apt-key add -&& \
  curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
  add-apt-repository -y ppa:webupd8team/java && apt-get update -q && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  apt-get update -yqq 

# Install H2o dependancies
RUN \
  apt-get install -y \
  python3 \
  python3-dev \
  python3-pip \
  python3-sklearn \
  python3-pandas \
  python3-numpy \
  python3-matplotlib \
  r-base \
  r-base-dev \
  nodejs \
  libxml2-dev \
  libssl-dev \
  libcurl4-openssl-dev \
  libmysqlclient-dev

# Get R dependancies
RUN \
  /usr/bin/R -e 'chooseCRANmirror(graphics=FALSE, ind=54);install.packages(c("R.utils", "AUC", "mlbench", "Hmisc", "flexclust", "randomForest", "bit64", "HDtweedie", "RCurl", "jsonlite", "statmod", "devtools", "roxygen2", "testthat", "Rcpp", "fpc", "RUnit", "ade4", "glmnet", "gbm", "ROCR", "e1071", "ggplot2", "LiblineaR"))' 

WORKDIR /opt

RUN \
## Workaround for LiblineaR problem
  cd /opt && \
  wget https://s3.amazonaws.com/h2o-r/linux/LiblineaR_1.94-2.tar.gz && \
  R CMD INSTALL LiblineaR_1.94-2.tar.gz

# Install Oracle Java 8
RUN \
  apt-get install -y oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/cache/apt/*

RUN \
  mkdir /opt/h2o3-automl

# Install automl, copy the files to the root of the git repo
COPY h2o-*-py2.py3-none-any.whl /opt/h2o3-automl
COPY steam-automl-1.5.99999-SNAPSHOT.jar /opt/h2o3-automl/automl.jar
COPY ./scripts/start-automl.sh /opt/start-automl.sh

RUN \
  /usr/bin/pip3 install --upgrade pip && \
  /usr/bin/pip3 install /opt/h2o3-automl/h2o-*-py2.py3-none-any.whl && \
  chmod +x /opt/start-automl.sh

EXPOSE 54321

# Nimbix Integrations
ADD ./NAE/AppDef.json /etc/NAE/AppDef.json
ADD ./NAE/AppDef.png /etc//NAE/default.png
ADD ./NAE/screenshot.png /etc/NAE/screenshot.png
ADD ./NAE/url.txt /etc/NAE/url.txt

# Nimbix JARVICE emulation
EXPOSE 22
RUN mkdir -p /usr/lib/JARVICE && cp -a /tmp/image-common-master/tools /usr/lib/JARVICE
RUN cp -a /tmp/image-common-master/etc /etc/JARVICE && chmod 755 /etc/JARVICE && rm -rf /tmp/image-common-master
RUN mkdir -m 0755 /data && chown nimbix:nimbix /data
RUN sed -ie 's/start on.*/start on filesystem/' /etc/init/ssh.conf

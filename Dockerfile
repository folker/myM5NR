
# docker build -t mgrast/m5nr-build .

FROM ubuntu:16.04

RUN apt-get update && apt-get install -y \
  git-core \
  lftp \
  libdbi-perl  \
  libdbd-pg-perl \
  libmodule-install-perl \
  zlib1g-dev \
  wget\
  unzip \
  make \
  dh-autoreconf \
  vim \
  curl \
  ncbi-blast+ \
  python-biopython \
  python-yaml \
  python-pip \
  python3 \
  python3-pip

RUN pip2 install --upgrade pip
RUN python -m pip install plyvel nested_dict
RUN pip3 install --upgrade pip
RUN python3 -m pip install PrettyTable pyyaml

# install leveldb
RUN cd /root \
    && wget https://github.com/google/leveldb/archive/v1.20.tar.gz \
    && tar xvzf v1.20.tar.gz \
    && cd leveldb-1.20/ \
    && make \
    && cp out-static/lib* out-shared/lib* /usr/local/lib/ \
    && cd include/ \
    && cp -r leveldb /usr/local/include/ \
    && ldconfig

# install the SEED environment for Subsystem data download
RUN mkdir -p /sas \
    && cd /sas \
    && wget http://blog.theseed.org/downloads/sas.tgz \
    && tar xvzf sas.tgz \
    && cd modules \
    && ./BUILD_MODULES

ENV PERL5LIB $PERL5LIB:/sas/lib:/sas/modules/lib
ENV PATH $PATH:/sas/bin

### install DIAMOND
RUN cd /root \
	&& git clone https://github.com/bbuchfink/diamond.git \
	&& cd diamond \
	&& sh ./build_simple.sh \
	&& install -s -m555 diamond /usr/local/bin \
	&& cd /root ; rm -rf diamond 

### install vsearch 2.43
RUN cd /root \
    && wget https://github.com/torognes/vsearch/archive/v2.4.3.tar.gz \
	&& tar xzf v2*.tar.gz \
	&& cd vsearch-2* \
	&& sh ./autogen.sh \
	&& ./configure --prefix=/usr/local/ \
	&& make \
	&& make install \
	&& make clean \
	&& cd /root ; rm -rf vsearch-2* v2*.tar.gz    

### install sortmerna
RUN cd /root \
	&& wget https://github.com/biocore/sortmerna/archive/2.1b.tar.gz \
	&& tar xvf 2*.tar.gz \
	&& cd sortmerna-2* \
	&& sed -i 's/^\#define READLEN [0-9]*/#define READLEN 500000/' include/common.hpp \
	&& ./configure \
    && make install \
    && make clean \
    && cd /root ; rm -rf sortmerna-2* 2*.tar.gz

### install yq
RUN curl -L "https://github.com/mikefarah/yq/releases/download/1.14.0/yq_linux_amd64" > /usr/bin/yq \
    && chmod +x /usr/bin/yq

# copy myM%NR and set up env
COPY . /myM5NR
ENV PATH $PATH:/myM5NR/bin

RUN mkdir -p /m5nr_data /m5nr_data/Sources /m5nr_data/Parsed /m5nr_data/Build
WORKDIR /m5nr_data

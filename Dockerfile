
FROM ubuntu
MAINTAINER The MG-RAST team (folker@mg-rast.org)

RUN apt-get update && apt-get install -y \
      curl \
      dh-autoreconf \
      diamond-aligner \
      git-core \
      lftp \
      libleveldb-dev \
      libmodule-install-perl \
      libsnappy-dev \
      libz-dev \
      lftp \
      make \
      maven \
      ncbi-blast+ \
      python3 \
      python3-pip \
      python-biopython \
      python-httplib2 \
      python-yaml \
      software-properties-common \
      sortmerna \
      unzip \
      vim \
      vsearch \
      wget \
      && apt-get clean

### install solr-import-export-json
RUN cd / \
    && git clone https://github.com/freedev/solr-import-export-json.git \
    && cd solr-import-export-json \
    && mvn clean package


RUN pip3 install --upgrade pip
RUN python3 -m pip install PrettyTable pyyaml requests_toolbelt

### install yq
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest" && chmod +x /usr/local/bin/yq

# install the SEED environment for Subsystem data download
RUN mkdir -p /sas \
    && cd /sas \
    && wget http://blog.theseed.org/downloads/sas.tgz \
    && tar xvzf sas.tgz \
    && cd modules \
    && ./BUILD_MODULES

ENV PERL5LIB $PERL5LIB:/sas/lib:/sas/modules/lib
ENV PATH $PATH:/sas/bin

#
# copy myM5NR and set up env
RUN mkdir -p /myM5NR /myM5NR/bin /m5nr_data \
   && ln -s /usr/bin/diamond-aligner  /usr/local/bin/diamond
COPY bin/* /myM5NR/bin/
COPY config/*.yaml /myM5NR/
COPY upload/schema/* /myM5NR/schema/

ENV PATH $PATH:/myM5NR/bin
WORKDIR /m5nr_data

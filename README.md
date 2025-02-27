myM5NR
======

local version of M5NR


## Installation with Docker ##

To build this image:


```bash
git clone https://github.com/MG-RAST/myM5NR.git
```

There are seperate dockerfiles for the different actions available: download, parse, build, upload
They can be built with the following commands:

```bash
docker build -t mgrast/m5nr .
```

Examples for manual invocation:
```bash
docker run -t -d --name mgrast/m5nr -v /var/tmp/m5nr:/m5nr_data mgrast/m5nr bash
```

From now steps execute inside the container

Set up some environment bits
```bash
mkdir -p /m5nr_data/Sources
mkdir -p /m5nr_data/Parsed
mkdir -p /m5nr_data/Build
```

To initiate the download (you can use --force to delete old _part directories)
```bash
cd /m5nr_data
/myM5NR/bin/m5nr_compiler.py download --debug 2>&1 | tee /m5nr_data/Sources/logfile.txt
```

To initiate the parsing (work in progress)
```bash
cd /m5nr_data
/myM5NR/bin/m5nr_compiler.py parse --debug 2>&1 | tee /m5nr_data/Parsed/logfile.txt
```

To view status
```bash
cd /m5nr_data
/myM5NR/bin/m5nr_compiler.py status --debug
```

To use an automated wrapper script for full round build
```bash
docker exec m5nr m5nr_master.sh -a download
docker exec m5nr m5nr_master.sh -a parse
docker exec m5nr m5nr_master.sh -a build -v <m5nr version #>
docker exec m5nr m5nr_master.sh -a upload -v <m5nr version #> -t <shock token>
```

To load build data on solr server, run following on same host
```bash
docker exec m5nr docker_setup.sh
docker exec m5nr solr_load.sh -n -i <shock file download url> -v <m5nr version #> -s <solr url>
```

To load build data on cassandra cluster, run following
```bash
docker exec m5nr cassandra_load.py -n -i <shock file download url> -v <m5nr version #> -t <shock token>
```

To check table sizes in cassandra for new m5nr build
```bash
CQLSH="/usr/bin/cqlsh --request-timeout 600 --connect-timeout 600"
for T in `docker exec cassandra-simple $CQLSH -e "USE m5nr_v12; describe tables;"`; do echo $T; docker exec cassandra-simple $CQLSH -e "USE m5nr_v12; CONSISTENCY QUORUM; SELECT COUNT(*) FROM $T;"; done
```

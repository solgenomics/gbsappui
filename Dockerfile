FROM debian:bullseye
# open port 8090
#
EXPOSE 8090

#To build with this Dockerfile run 'docker build . -t gbsappui_docker --build-arg CACHEBUST=`git rev-parse main` && ./devel/run_docker.sh'
# create directory layout
RUN mkdir /var/log/gbsappui

# install system dependencies
RUN apt-get update
RUN apt-get install -y git r-base python3.10 wget libcurl4 apt-utils cpanminus perl-doc vim less htop ack libslurm-perl screen lynx iputils-ping gcc g++ libc6-dev make cmake zlib1g-dev ca-certificates slurmd slurmctld munge libbz2-dev libncurses5-dev libncursesw5-dev liblzma-dev libcurl4-gnutls-dev libssl-dev emacs gedit cron rsyslog net-tools bc ne environment-modules nano python-is-python3
#get bcftools
RUN wget https://github.com/samtools/bcftools/releases/download/1.13/bcftools-1.13.tar.bz2 && \
tar -xvf bcftools-1.13.tar.bz2 &&  cd bcftools-1.13; make && \
rm ../bcftools-1.13.tar.bz2 && \
cd ..
#get samtools
RUN wget https://sourceforge.net/projects/samtools/files/latest/download && \
tar -xvjf download* && rm download* && cd samtools* && make && cd ..
#install picard
RUN wget https://github.com/broadinstitute/picard/releases/download/2.25.6/picard.jar
#install GATK
RUN wget -O GATK4.2.6.1.zip "https://github.com/broadinstitute/gatk/releases/download/4.2.6.1/gatk-4.2.6.1.zip" && \
    unzip GATK4.2.6.1.zip
#install java
RUN wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u322-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz && \
    tar -xvf OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz; rm *tar.gz
#install NextGenMap
RUN update-ca-certificates && \
    git clone https://github.com/Cibiv/NextGenMap.git && cd NextGenMap && git checkout $VERSION_ARG && mkdir -p build && cd build && cmake .. && make && cp -r ../bin/ngm-*/* /usr/bin/ && cd .. && rm -rf NextGenMap && \
    rm -rf /var/lib/apt/lists/*
#install ggplot2
RUN mkdir -p R && \
    cd ./R && \
    R -e 'install.packages("ggplot2", dependencies = TRUE, repos="http://cran.r-project.org", lib="./")'
RUN cpanm Catalyst Catalyst::Restarter Catalyst::View::HTML::Mason
#clone GBSApp from github
RUN git clone https://github.com/bodeolukolu/GBSapp.git
#install Emboss
#ARG CACHEBUST=0
RUN wget http://debian.rub.de/ubuntu/pool/universe/e/emboss/emboss_6.6.0.orig.tar.gz && \
   gunzip emboss_6.6.0.orig.tar.gz && \
   tar xvf emboss_6.6.0.orig.tar && \
   cd EMBOSS-6.6.0 && \
   ./configure --without-x && \
   make && \
   cd .. && \
   rm emboss_6.6.0.orig.tar*
#move all dependencies to GBSapp/tools
RUN mkdir GBSapp/tools
RUN rm GATK* && \
    mv picard.jar ./GBSapp/tools/ && \
    mv NextGenMap ./GBSapp/tools/ && \
    mv gatk-4.2.6.1 ./GBSapp/tools/ && \
    mv R ./GBSapp/tools/ && \
    mv bcftools* ./GBSapp/tools/ && \
    mv jdk8u322-b06 ./GBSapp/tools/ && \
    mv samtools* ./GBSapp/tools/ && \
    mv EMBOSS* ./GBSapp/tools/
RUN mkdir /project/
RUN mkdir /project/refgenomes/
RUN mkdir /project/samples/
RUN apt-get update \
  && apt-get install -y libmunge-dev libmunge2 slurm-wlm
RUN cp ./GBSapp/examples/proj/refgenomes/* /project/refgenomes/
RUN cp ./GBSapp/examples/input_steps.txt /project/
RUN cp ./GBSapp/examples/proj/samples/M* /project/samples/
RUN rm /etc/munge/munge.key

RUN chmod 777 /var/spool/ \
  && mkdir /var/spool/slurmstate \
  && chmod 777 /var/spool/slurmstate/ \
  && /usr/sbin/mungekey \
  && ln -s /var/lib/slurm-llnl /var/lib/slurm \
  && mkdir -p /var/log/slurm

#Don't use cache if the github repository has been updated.
#ARG CACHEBUST
#RUN echo "$CACHEBUST"
RUN git clone https://github.com/solgenomics/gbsappui
RUN mv ./gbsappui/config.sh /project/
RUN cp gbsappui/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN mkdir gbsappui/root/static/js && cd gbsappui/root/static/js && apt-get update && apt-get install -y npm && npm install jquery && npm install js-cookie
# start services when running container...
ENTRYPOINT ["/entrypoint.sh"]

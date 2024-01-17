FROM debian:bullseye
# open port 8090
#
EXPOSE 8090

#To build with this Dockerfile run 'docker build . -t gbsappui_docker --build-arg CACHEBUST=`git rev-parse main` && ./devel/run_docker.sh'

# create directory layout
RUN mkdir /var/log/gbsappui

# install system dependencies
RUN apt-get update && apt-get install -y git r-base python3.10 wget libcurl4 apt-utils cpanminus perl-doc vim less htop ack libslurm-perl screen lynx iputils-ping gcc g++ libc6-dev make cmake zlib1g-dev ca-certificates slurmd slurmctld munge libbz2-dev libncurses5-dev libncursesw5-dev liblzma-dev libcurl4-gnutls-dev libssl-dev emacs gedit cron rsyslog net-tools bc ne environment-modules nano python-is-python3 libmunge-dev libmunge2 slurm-wlm gawk

#install GBS dependencies

#install bcftools
RUN wget https://github.com/samtools/bcftools/releases/download/1.17/bcftools-1.17.tar.bz2 && \
tar -xvf bcftools-1.17.tar.bz2 && cd bcftools-1.17 && \
make && \
rm ../bcftools-1.17.tar.bz2 && \
cd ..

#install bedtools
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.29.1/bedtools-2.29.1.tar.gz && \
tar -zxvf bedtools-2.29.1.tar.gz && \
cd bedtools2 \
&& make  && \
rm ../bedtools-2.29.1.tar.gz

#install samtools
RUN wget https://sourceforge.net/projects/samtools/files/samtools/1.17/samtools-1.17.tar.bz2/download && \
tar -xvjf download* && rm download* && cd samtools* && make && cd ..

#install mafft
#RUN mkdir mafft
#RUN wget https://mafft.cbrc.jp/alignment/software/mafft-7.505-without-#extensions-src.tgz && \
#tar zxvf mafft-7.505-without-extensions-src.tgz && \
#rm mafft-7.505-without-extensions-src.tgz && \
#cd mafft-7.505-without-extensions/core/ && \
 #awk 'NR!=3{print $0}' Makefile | awk 'NR>1{print $0}' | cat <(printf #"BINDIR = ${GBSapp_dir}tools/mafft\n") - | \
 #cat <(printf "PREFIX = ${GBSapp_dir}tools/mafft\n") - > makefile.tmp && \
 #mv makefile.tmp Makefile && \
 #make clean && \
 #make && \
 #make install && \
 #cd ../..

#install picard
RUN wget https://github.com/broadinstitute/picard/releases/download/2.25.6/picard.jar

#install GATK
RUN wget -O GATK4.2.6.1.zip "https://github.com/broadinstitute/gatk/releases/download/4.2.6.1/gatk-4.2.6.1.zip" && \
    unzip GATK4.2.6.1.zip

##install java
RUN wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u322-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz && \
    tar -xvf OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz; rm *tar.gz

#install NextGenMap
RUN update-ca-certificates && \
    git clone https://github.com/Cibiv/NextGenMap.git && cd NextGenMap && git checkout $VERSION_ARG && mkdir -p build && cd build && cmake .. && make && cp -r ../bin/ngm-*/* /usr/bin/ && cd .. && rm -rf NextGenMap && \
    rm -rf /var/lib/apt/lists/*

#install R package: ggplot2
RUN mkdir -p R && \
    cd ./R && \
    R -e 'install.packages("ggplot2", dependencies = TRUE, repos="http://cran.r-project.org", lib="./")'

#install R package: CMplot
RUN R -e 'install.packages("CMplot", dependencies = TRUE, repos="http://cran.r-project.org", lib="./")'
RUN cpanm Catalyst Catalyst::Restarter Catalyst::View::HTML::Mason JSON Email::Sender::Simple

#install Emboss
RUN wget http://debian.rub.de/ubuntu/pool/universe/e/emboss/emboss_6.6.0.orig.tar.gz && \
   gunzip emboss_6.6.0.orig.tar.gz && \
   tar xvf emboss_6.6.0.orig.tar && \
   cd EMBOSS-6.6.0 && \
   ./configure --without-x && \
   make && \
   cd .. && \
   rm emboss_6.6.0.orig.tar*

#install mafft
RUN mkdir mafft
RUN wget https://mafft.cbrc.jp/alignment/software/mafft-7.505-without-extensions-src.tgz
RUN tar zxvf mafft-7.505-without-extensions-src.tgz
RUN rm mafft-7.505-without-extensions-src.tgz
RUN cd mafft-7.505-without-extensions/core/ && \
make clean && \
make && \
su && \
make install && \
cd ../..

#clone GBSApp from github
RUN git clone https://github.com/bodeolukolu/GBSapp.git

#move all GBS dependencies to GBSapp/tools
RUN mkdir GBSapp/tools
RUN rm GATK* && \
    mv picard.jar ./GBSapp/tools/ && \
    mv NextGenMap ./GBSapp/tools/ && \
    mv gatk-4.2.6.1 ./GBSapp/tools/ && \
    mv R ./GBSapp/tools/ && \
    mv bcftools* ./GBSapp/tools/ && \
    mv jdk* ./GBSapp/tools/ && \
    mv samtools* ./GBSapp/tools/ && \
    mv EMBOSS* ./GBSapp/tools/ && \
    mv mafft* ./GBSapp/tools/ && \
    mv bedtools* ./GBSapp/tools/

#setup java paths
RUN export J2SDKDIR=/GBSapp/tools/jdk8u322-b06
RUN export J2REDIR=/GBSapp/tools/jdk8u322-b06
RUN export PATH=$PATH:/GBSapp/tools/jdk8u322-b06/bin:/GBSapp/tools/jdk8u322-b06/db/bin
RUN export JAVA_HOME=/GBSapp/tools/jdk8u322-b06
RUN export DERBY_HOME=/GBSapp/tools/jdk8u322-b06

#Setup analysis folders and template for analysis folders
RUN mkdir /data/
RUN mkdir /project/
RUN mkdir /project/refgenomes/
RUN mkdir /project/samples/
RUN cp ./GBSapp/examples/input_steps.txt /project/

#Setup system files and Edit permissions
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

#clone gbsappui
RUN git clone https://github.com/solgenomics/gbsappui

#setup config file in analysis template directory
RUN cp /gbsappui/config.sh /project/

#edit entrypoint file
RUN cp gbsappui/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#install npm, jquery, and js-cookie
RUN cd gbsappui/root/static/js/ && apt-get update && apt-get install -y npm
RUN cd /gbsappui/root/static/js/node_modules/jquery && npm install jquery && cd ../js-cookie && npm install js-cookie && cd /gbsappui/root/static/js/node_modules/bootstrap && npm install bootstrap@3

#install Beagle
RUN mkdir /beagle && \
    cd /beagle && \
    wget https://faculty.washington.edu/browning/beagle/beagle.22Jul22.46e.jar

# start services when running container...
ENTRYPOINT ["/entrypoint.sh"]

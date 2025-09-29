FROM debian:bookworm
# open port 8090
#
EXPOSE 8090

#To build with this Dockerfile run 'docker build . -t gbsappui_docker --build-arg CACHEBUST=`git rev-parse main` && ./devel/run_docker.sh'

# create directory layout
RUN mkdir /var/log/gbsappui

# install system dependencies
RUN apt-get update && apt-get install -y git r-base-core python3.10 wget libcurl4 apt-utils cpanminus perl-doc vim less htop ack libslurm-perl screen lynx iputils-ping gcc g++ libc6-dev make cmake zlib1g-dev ca-certificates slurmd slurmctld munge libbz2-dev libncurses5-dev libncursesw5-dev liblzma-dev libcurl4-gnutls-dev libssl-dev emacs gedit cron rsyslog net-tools bc ne environment-modules nano python-is-python3 libmunge-dev libmunge2 slurm-wlm gawk

#setup postfix: install postfix, remove exim4 default folder, and edit main.cf to make mail log file
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get install build-essential pkg-config apt-utils gnupg2 curl wget -y
RUN apt-get update && apt-get install -y postfix mailutils
RUN rm -rf /etc/exim4/ \
    && rm -rf /var/log/exim4/

#install Beagle
RUN mkdir /beagle && \
    cd /beagle && \
    wget https://faculty.washington.edu/browning/beagle/beagle.22Jul22.46e.jar && \
    cd /

#install cpan modules
RUN cpanm Module::Pluggable --force
RUN cpanm Devel::InnerPackage Catalyst Catalyst::Runtime Catalyst::Restarter Catalyst::View Catalyst::View::HTML::Mason JSON Email::Sender Email::Sender::Simple

#clone GBSApp from github
RUN git clone https://github.com/bodeolukolu/GBSapp.git

#Install and configure miniconda for ngm installation and install ngm
ENV PATH="/root/miniconda3/bin:$PATH"
ARG PATH="/root/miniconda3/bin:$PATH"

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && mkdir -p /root/.conda \
    && bash /Miniconda3-latest-Linux-x86_64.sh -b -p /root/miniconda3 \
    && rm -f Miniconda3-latest-Linux-x86_64.sh

RUN conda init \
    && conda config --add channels conda-forge \
    && conda config --add channels defaults \
    && conda config --add channels r \
    && conda config --add channels bioconda \
    && conda install nextgenmap -y

#Remove /root/miniconda3 from path after using miniconda
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ARG PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

##install java
RUN mkdir /GBSapp/tools/ && cd /GBSapp/tools/ && wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u322-b06/OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz && \
    tar -xvf OpenJDK8U-jdk_x64_linux_hotspot_8u322b06.tar.gz; rm *tar.gz

#setup java paths
RUN export J2SDKDIR=/GBSapp/tools/jdk8u322-b06
RUN export J2REDIR=/GBSapp/tools/jdk8u322-b06
RUN export PATH=$PATH:/GBSapp/tools/jdk8u322-b06/bin:/GBSapp/tools/jdk8u322-b06/db/bin
RUN export JAVA_HOME=/GBSapp/tools/jdk8u322-b06
RUN export DERBY_HOME=/GBSapp/tools/jdk8u322-b06

#Setup analysis folders and template for analysis folders
RUN mkdir /results/
RUN mkdir /project/
RUN mkdir /project/refgenomes/
RUN mkdir /project/samples/
RUN mkdir /project/gbsappui_slurm_log/

RUN cp ./GBSapp/examples/input_steps.txt /project/
RUN cp /gbsappui/analysis_info.txt /project/

#Setup system files and Edit permissions
RUN rm /etc/munge/munge.key
RUN chmod 777 /var/spool/ \
  && mkdir /var/spool/slurmd \
  && chown slurm:slurm /var/spool/slurmd/ \
  && /usr/sbin/mungekey \
  && ln -s /var/lib/slurm-llnl /var/lib/slurm \
  && mkdir -p /var/log/slurm

#clone gbsappui from github
RUN cd / \
  && git clone https://github.com/solgenomics/gbsappui

#install npm and npm packages
RUN cd /gbsappui/root/static/js/ && apt-get update && apt-get install -y npm
RUN cd /gbsappui/root/static/js/node_modules/jquery && npm install jquery && cd ../js-cookie && npm install js-cookie && cd /gbsappui/root/static/js/node_modules/bootstrap && npm install bootstrap@3

#Replace GBSapp install script and internal parameters with updated versions for ngm changes
RUN cp /gbsappui/GBSapp_internal_parameters.sh /GBSapp/scripts/
RUN cp /gbsappui/install.sh /GBSapp/scripts/

#Install GBSapp dependencies except ngm
RUN cd /GBSapp/ \
    && ./GBSapp install

#Don't use cache if the github repository has been updated.
#ARG CACHEBUST
#RUN echo "$CACHEBUST"

#setup config file in analysis template directory
RUN cp /gbsappui/config.sh /project/

#edit entrypoint file
RUN cp gbsappui/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#make results file in root directory
RUN mkdir /gbsappui/root/results/

# start services when running container...
ENTRYPOINT ["/entrypoint.sh"]

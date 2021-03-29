FROM ubuntu:18.04

LABEL org.label-schema.license="LGPL-3.0" \
      org.label-schema.vcs-url="https://github.com/iambaim/bioticexplorer-docker" \
      org.label-schema.vendor="Institute of Marine Research, Norway"

## Set user to docker
RUN useradd -u 5000 docker \
	&& mkdir /home/docker \
	&& chown docker:docker /home/docker \
	&& addgroup docker staff

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Install tools and dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ed \
		less \
		locales \
		vim-tiny \
		curl \
		wget \
		ca-certificates \
		fonts-texgyre \
		libgomp1 \
		libpango-1.0-0 \
		libpangocairo-1.0-0 \
		libxt6 \
		libsm6 \
	&& rm -rf /var/lib/apt/lists/*

## Configure default locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
        && locale-gen en_US.utf8 \
        && /usr/sbin/update-locale LANG=en_US.UTF-8

## Use major and minor vars to re-use them in non-interactive installation script
ENV MRO_VERSION_MAJOR 4
ENV MRO_VERSION_MINOR 0
ENV MRO_VERSION_BUGFIX 2
ENV MRO_VERSION $MRO_VERSION_MAJOR.$MRO_VERSION_MINOR.$MRO_VERSION_BUGFIX
ENV R_HOME=/opt/microsoft/ropen/$MRO_VERSION/lib64/R

## Download and install MRO & MKL, see https://mran.microsoft.com/download https://mran.blob.core.windows.net/install/mro/4.0.2/microsoft-r-open-4.0.2.tar.gz
RUN apt-get update \
 && cd /tmp \
 && wget https://mran.blob.core.windows.net/install/mro/$MRO_VERSION/Ubuntu/microsoft-r-open-$MRO_VERSION.tar.gz \
 && cd /tmp && tar -xzf microsoft-r-open-$MRO_VERSION.tar.gz \
 && cd microsoft-r-open/ \
 && ./install.sh -a -u \
 && cd .. \
 && rm microsoft-r-open-*.tar.gz \
 && rm -r microsoft-r-open \
 && rm -rf /var/lib/apt/lists/* \
 && chown root:root /tmp \
 && chmod 1777 /tmp

CMD ["/usr/bin/R", "--no-save"]

FROM ubuntu:21.04

LABEL org.label-schema.license="LGPL-3.0" \
      org.label-schema.vcs-url="https://github.com/iambaim/bioticexplorer-docker" \
      org.label-schema.vendor="Institute of Marine Research, Norway"

ENV IDX_PATH=/data/dbIndex.rda
ENV SERVER_MODE=1
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Oslo

RUN apt-get update \
 && apt-get install -y git build-essential libxml2-dev libudunits2-dev libssl-dev libfontconfig1-dev libfreetype6-dev libuv1-dev libxslt1-dev libgdal-dev \
 && apt-get install -y libopenblas-base libxml2 libudunits2-0 fontconfig file diffutils libfontconfig1 libfreetype6 libssl1.1 libgdal28 libxslt1.1 r-base \
 # Frontend
 && git clone https://github.com/MikkoVihtakari/BioticExplorer.git /BioticExplorer \
 && cd /BioticExplorer \
 && Rscript --vanilla  -e "options(repos=\"https://cloud.r-project.org/\"); install.packages(\"RstoxData\", repos = c(\"https://stoxproject.github.io/repo/\", \"https://cloud.r-project.org/\")); source(\"/BioticExplorer/R/install_requirements.R\")" \
 # Database processor
 && git clone https://github.com/MikkoVihtakari/BioticExplorerServer.git /BioticExplorerServer \
 && cd /BioticExplorerServer \
 && Rscript --vanilla  -e "options(repos=\"https://cloud.r-project.org/\"); install.packages(\"remotes\"); remotes::install_deps(); remotes::install_local()" \
 && apt-get remove --purge -y git build-essential libxml2-dev libudunits2-dev libssl-dev libfontconfig1-dev libfreetype6-dev libxslt1-dev libgdal-dev \
 && apt-get autoremove --purge -y \
 && apt-get clean autoclean -y \
 && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

USER 5000

CMD Rscript --vanilla -e "shiny::runApp(\"/BioticExplorer\", host=\"::\", port=8080)"

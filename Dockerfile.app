FROM iambaim/mro:latest

LABEL org.label-schema.license="LGPL-3.0" \
      org.label-schema.vcs-url="https://github.com/iambaim/bioticexplorer-docker" \
      org.label-schema.vendor="Institute of Marine Research, Norway"

ENV IDX_PATH=/data/dbIndex.rda

RUN  apt-get update \
  && apt-get -y install build-essential gfortran make g++ file git zlib1g zlib1g-dev libxml2 libxml2-dev libudunits2-0 libudunits2-dev libgdal20 libgdal-dev libfontconfig1-dev libfontconfig1 libgit2-dev libgit2-26 \
  # Frontend
  && git clone --branch prepare_image https://github.com/iambaim/BioticExplorer.git /BioticExplorer \
  && Rscript --vanilla  -e "library(checkpoint); setSnapshot(\"2021-03-29\"); source(\"/BioticExplorer/install_requirements.R\")" \
  # Database processor
  && git clone --branch prepare_image https://github.com/iambaim/BioticExplorerServer.git /BioticExplorerServer \
  && cd /BioticExplorerServer \
  && Rscript --vanilla  -e "library(checkpoint); setSnapshot(\"2021-03-29\"); install.packages(\"remotes\"); remotes::install_deps(); remotes::install_local()" \
  && apt-get -y --purge autoremove git zlib1g-dev libxml2-dev libudunits2-dev libgdal-dev libfontconfig1-dev libgit2-dev build-essential gfortran make g++ \
  && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

USER 5000

CMD Rscript --vanilla -e "shiny::runApp(\"/BioticExplorer\", host=\"::\", port=8080)"

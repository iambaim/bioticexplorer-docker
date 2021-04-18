#!/bin/bash

# Do the update
docker-compose exec -T dbserver sh -c "rm -fR /var/monetdb5/dbfarm/bioticexplorer-next && monetdb create bioticexplorer-next && monetdb release bioticexplorer-next"
docker-compose exec -T bioticexplorer sh -c "TMPDIR=/data Rscript --vanilla  -e \"BioticExplorerServer::compileDatabase(dbIndexPath = Sys.getenv('IDX_PATH'))\""

# Only do bulk update command below when bioticexplorer-next is available
docker-compose exec -T dbserver sh -c "monetdb stop bioticexplorer-next" && \
docker-compose exec -T dbserver sh -c "monetdb stop bioticexplorer" && \
docker-compose exec -T dbserver sh -c "rm -fR /var/monetdb5/dbfarm/bioticexplorer && monetdb set name=bioticexplorer bioticexplorer-next && monetdb start bioticexplorer" && \
docker-compose restart bioticexplorer


# Installing Biotic Explorer with Docker Compose on IMR Servers

## 0. Install Docker (if you don't have access to it)
Assuming that you can only use rootless Docker and that Docker is installed on the server machine:

1. Ask IT to assign you **sub-UIDs** and **sub-GIDs** on the server.
2. Run:
   ```console
   dockerd-rootless-setuptool.sh install
   ```
3. Some IMR servers uses NFS share for users HOME directory. Rootless Docker won't work with this. Find any physical disks (e.g., `/localscratch`) and run this command:
   ```console
   rm -R ~/.local/share/docker
   mkdir -p /localscratch/${USER}/.local/share/docker
   ln -s /localscratch/${USER}/.local/share/docker ~/.local/share/docker
   ```
4. Run Docker daemon at backend:
   ```console
   screen -dmS dockerd bash -c "export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && dockerd-rootless.sh"
   ```
5. Test your docker installation:
   ```console
   export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
   docker run hello-world
   ```

## 1. Install Docker Compose
1. Prepare your local environment:
   ```console
   echo 'export PATH=$HOME/local/bin:$PATH' >> $HOME/.bash_profile
   echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> $HOME/.bash_profile
   source $HOME/.bash_profile
   ```
   Note that the you only need to do the `source...` command once. The `.bash_profile` content will be executed on every user login.
2. Run the installation command:
   ```console
   curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o ~/local/bin/docker-compose
   chmod +x ~/local/bin/docker-compose
   ```
   Note that newer version might be available. You can check it here: https://docs.docker.com/compose/install/
3. Check if Docker Compose is properly installed using this command:
   ```console
   docker-compose version
   ```

## 2. Run Bioticexplorer
1. Clone `bioticexplorer-docker` repo:
   ```console
   git clone https://github.com/iambaim/bioticexplorer-docker.git
   ```
2. Bring up the Bioticexplorer
   ```console
   cd bioticexplorer-docker
   docker-compose up -d
   ```
3. Setup user crontab for nightly database updates:
   ```console
   echo '0 0 * * * export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && export PATH=/home/${USER}/local/bin:$PATH && export COMPOSE_INTERACTIVE_NO_CLI=1 && cd' $(pwd) '&& ./script/db-update.sh > '$(pwd)'/run.log 2>&1' > tmp-crontab
   
   crontab tmp-crontab
   ```
   Note that the above assumes that we run the automated updates every 00:00 hour in the server time.
4. Populate database for the first time:
   ```console
   screen -dmS firstrun bash -c "export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && ./script/db-update.sh"
   ```
5. Sit back or relax while the database is being created for the first time. Or you can follow the progress by running:
   ```console
   screen -r firstrun
   ```
   Don't forget to do `Ctrl-a-d` to detach from the screen.

6. Meanwhile, the server should be reachable via the address `<server>:8080` and `<server>:8080/notebook` for the R Jupyter notebook server.

## 3. Updating BioticExplorer and BioticExplorerServer apps (and the Docker image)

1. Ensure you have pushed all the necessary changes into the official BioticExplorer and BioticExplorerServer repositories (by default, the image will get them from https://github.com/MikkoVihtakari/BioticExplorer and https://github.com/MikkoVihtakari/BioticExplorerServer). See the `Dockerfile` content.

2. Note down your own Docker Hub repository that will host your image. Previously this was `iambaim/bioticexplorer` (https://hub.docker.com/r/iambaim/bioticexplorer). You can use any name you want, just remember to update the `docker-compose.yml` file to change the source location of the image.

3. Build the image. TIPS: Building the image will take some time. Using `screen` is a good idea:
   ```console
   cd bioticexplorer-docker
   docker build -t mikkovihtakari/bioticexplorer:latest .
   ```
   You can use any username/repository and version (e.g., `mikkovihtakari/bioticexplorer:2.1`). However, don't forget to to update the `docker-compose.yml` file or just stick to using `latest` for version.

4. After the image building is complete, push the image to the Docker Hub (login first if you haven't done that):
   ```console
   docker login -u mikkovihtakari
   ...

   docker push mikkovihtakari/bioticexplorer:latest
   ```

5. Check your Docker Hub page to ensure that the image has been uploaded.

6. If you want to force the running server to use the latest image (again, don't forget to  double check the `docker-compose.yml` file content):
   ```console
   cd bioticexplorer-docker
   docker-compose pull
   docker-compose up -d
   ```

# Troubleshooting
1. If the server is misbehaving, you can restart it using:
   ```console
   cd bioticexplorer-docker
   docker-compose down
   ...
   docker-compose up -d
   ```

2. We can follow the server live logs using this command:
   ```console
   docker-compose logs -f
   ```

3. To edit the live bioticexplorer server, use this command: 
   ```console
   docker-compose exec -u root bioticexplorer bash
   ```
   After that you can go to `/BioticExplorer` directory and edit the files using `vim`. Use this in combination with the live logs to pinpoint any of the server errors.

4. Sometimes the locally stored Docker image can get corrupted. Usually you'll getting this error: `...user XXXX not found...` in `docker-compose logs` and/or that `docker-compose ps` shows that
a service is getting restarted all the time. The possible fix is as follows:
   ```console
   # Shut down the services
   docker-compose down

   # First list all the images
   docker images

   # See the image that is used in the broken service, for example the 'monetdb' image. Delete the image
   docker rmi <IMAGE ID>

   # Asks docker-compose to pull all the images
   docker-compose pull

   # Sometimes the volume used by the service will get corrupted too. We need to delete the volume.
   docker volume ls

   # Let say the broken volume is 'bio_db_data' as that volume is used by the monetdb-based service.
   docker volume rm bio_db_data

   # Restart the service again.
   docker-compose up -d
   ```

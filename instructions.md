# Installing Biotic Explorer with Docker Compose on IMR Servers

## 0. Install Docker (if you don't have access to it)
Assuming that you can only use rootless Docker and that Docker is installed on the server machine:

1. Ask IT to assign you **sub-UIDs** and **sub-GIDs** on the server.
2. Run:
   ```bash 
   dockerd-rootless-setuptool.sh install
   ```
3. Some IMR servers uses NFS share for users HOME directory. Rootless Docker won't work with this. Find any physical disks (e.g., `/localscratch`) and run this command:
   ```bash
   rm -R ~/.local/share/docker
   mkdir -p /localscratch/${USER}/.local/share/docker
   ln -s /localscratch/${USER}/.local/share/docker ~/.local/share/docker
   ```
4. Run Docker daemon at backend:
   ```bash
   screen -dmS dockerd bash -c "export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && dockerd-rootless.sh"
   ```
5. Test your docker installation:
   ```bash
   export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
   docker run hello-world
   ```

## 1. Install Docker Compose
1. Prepare your local environment:
   ```bash
   echo 'export PATH=$HOME/local/bin:$PATH' >> $HOME/.bash_profile
   echo 'export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock' >> $HOME/.bash_profile
   source $HOME/.bash_profile
   ```
   Note that the you only need to do the `source...` command once. The `.bash_profile` content will be executed on every user login.
2. Run the installation command:
   ```bash
   curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o ~/local/bin/docker-compose
   chmod +x ~/local/bin/docker-compose
   ```
   Note that newer version might be available. You can check it here: https://docs.docker.com/compose/install/
3. Check if Docker Compose is properly installed using this command:
   ```bash
   docker-compose version
   ```

## 2. Run Bioticexplorer
1. Clone `bioticexplorer-docker` repo:
   ```bash
   git clone https://github.com/iambaim/bioticexplorer-docker.git
   ```
2. Bring up the Bioticexplorer
   ```bash
   cd bioticexplorer-docker
   docker-compose up -d
   ```
3. Setup user crontab for nightly database updates:
   ```bash
   echo '0 0 * * * export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && export PATH=/home/${USER}/local/bin:$PATH && export COMPOSE_INTERACTIVE_NO_CLI=1 && cd' $(pwd) '&& ./script/db-update.sh > '$(pwd)'/run.log 2>&1' > tmp-crontab
   
   crontab tmp-crontab
   ```
   Note that the above assumes that we run the automated updates every 00:00 hour in the server time.
4. Populate database for the first time:
   ```bash
   screen -dmS firstrun bash -c "export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock && ./script/db-update.sh"
   ```
5. Sit back or relax while the database is being created for the first time. Or you can follow the progress by running:
   ```bash 
   screen -r firstrun
   ```
   Don't forget to do `Ctrl-a-d` to detach from the screen.

6. Meanwhile, the server should be reachable via the address `<server>:8080` and `<server>:8080/notebook` for the R Jupyter notebook server.

## 3. Troubleshooting
1. If the server is misbehaving, you can restart them using:
   ```bash
   cd bioticexplorer-docker
   docker-compose down
   ...
   docker-compose up -d
   ```

2. We can follow the server live logs using this command:
   ```bash
   docker-compose logs -f
   ```

3. To edit the live bioticexplorer server, use this command: 
   ```bash
   docker-compose exec -u root bioticexplorer bash
   ```
   After that you can go to `/BioticExplorer` directory and edit the files using `vim`. Use this in combination with the live logs to pinpoint any of the server errors.


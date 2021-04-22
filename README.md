# GCP (or local machine) + Kaggle Python docker image + VSCode

![vscode_jupyter](https://user-images.githubusercontent.com/1632335/113431667-0d1b8c80-9417-11eb-8183-e89084670f39.png)

This document describes how to setup [Kaggle Python docker image](https://github.com/Kaggle/docker-python) environment on [Google Cloud Platform (GCP)](https://cloud.google.com/) or your local machine by [Docker](https://www.docker.com/) and how to setup [Visual Studio Code (VSCode)](https://code.visualstudio.com/) to connect the environment.

A primally information source comes from [Kaggle's docker-python repository](https://github.com/Kaggle/docker-python). Also, there is a [guide](https://medium.com/kaggleteam/how-to-get-started-with-data-science-in-containers-6ed48cb08266), but unfortunately it's a bit obsoleted guide written in 2016.

**Note: This method may take 20-30 minutes and over 18.5GB disks for data downloads.**

**Note: If you do not use VSCode, no need to read this document. See [here](https://www.kaggle.com/product-feedback/159602).**

All files in this document are available on [my repository](https://github.com/susumuota/kaggleenv).

There are 2 options, GCP or local machine. If you are going to setup the environment on your local machine, skip to `[Option 2] Setup the environment on your local machine` section.

## [Option 1] Setup the environment on GCP

On GCP, ["AI Platform Notebooks"](https://cloud.google.com/ai-platform/notebooks/docs) would be easier than ["Compute Engine"](https://cloud.google.com/compute/docs/) (GCE) to setup [Kaggle Python docker image](https://github.com/Kaggle/docker-python).

### Create an AI Platform Notebook

- Access https://console.cloud.google.com/ai/platform/notebooks
- Select a project e.g. `kaggle-shopee-1` (You must create a project beforehand)
- Click `NEW INSTANCE`
- Choose `Customize instance`
- Instance name: e.g. `kaggle-test-1`
- Environment: `Kaggle Python [BETA]` (This option will automatically prepare [Kaggle Python docker image](https://github.com/Kaggle/docker-python) at startup the VM instance)
- GPU type: e.g. `NVIDIA Tesla T4`
  - Mark the checkbox `Install NVIDIA GPU driver automatically for me`

![gcp_notebook_1](https://user-images.githubusercontent.com/1632335/115653028-636e5200-a369-11eb-9bda-8c34036591f4.png)

- Open `Networking` section
  - Mark the radio button `Networks in this project`
  - Clear the checkbox `Allow proxy access when it's available` (This option will avoid to load unnecessary proxy Docker container)
- Click `CREATE`

![gcp_notebook_2](https://user-images.githubusercontent.com/1632335/115653237-c7911600-a369-11eb-88b1-db382a1f997e.png)

- Wait for around 20-30 minutes to start up the VM instance. I guess it's because of `docker pull`. If you choose GPU type: `None`, it takes a few minutes.

### Connect to the VM instance

- [Install Cloud SDK](https://cloud.google.com/sdk/docs/quickstart). If you are using macOS and Homebrew, `brew install --cask google-cloud-sdk` may be convenient.

After that, `gcloud` command should be available on your terminal.

- SSH to the VM instance with port forwarding

```
% gcloud compute --project "kaggle-shopee-1" ssh --zone "us-west1-b" "kaggle-test-1" -- -L 8080:localhost:8080
```

- Open web browser and try to access `http://localhost:8080`

Note: There is no `token=...`.

If you do not use VSCode, that's all. You do not have to do anything below.

### Stop pre-installed Docker container

If you use VSCode to connect GCP Notebook, you must tweak Docker container. At the moment, VSCode can only access to remote Jupyter servers with `token` option enabled. But pre-installed Docker container disables `token` option by `c.NotebookApp.token = ''`. You must stop pre-installed Docker container and run a new Docker container with `token` option enabled instead.

- Stop pre-installed Docker container

Stop pre-installed Docker container and turn off the startup option. See details [here](https://docs.docker.com/config/containers/start-containers-automatically/).

```
% docker ps -a
% docker inspect -f "{{.Name}} {{.HostConfig.RestartPolicy.Name}}" $(docker ps -aq)
% docker update --restart no payload-container
% docker inspect -f "{{.Name}} {{.HostConfig.RestartPolicy.Name}}" $(docker ps -aq)
% docker stop payload-container
% docker ps -a
```

- Install `docker-compose`

`docker-compose` will be convenient to run containers, even on a single container. See details [here](https://docs.docker.com/compose/install/).

```
% sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
% sudo chmod +x /usr/local/bin/docker-compose
```

Skip to `Run Docker container` section.

## [Option 2] Setup the environment on your local machine

If you setup the environment on your local machine, [install and setup Docker](https://docs.docker.com/get-docker/).

After that, `docker` and `docker-compose` commands should be available on your terminal.

```sh
% docker -v
Docker version 20.10.5, build 55c4c88
% docker-compose -v
docker-compose version 1.28.5, build c4eb3a1f
```

## Run Docker container (both GCP and local machine)

I prepared a [sample repository](https://github.com/susumuota/kaggleenv) of the `Dockerfile`, etc. If you do not care about details, execute these commands and skip to `Open Notebook by web browser` section.

```
% git clone https://github.com/susumuota/kaggleenv.git
% cd kaggleenv
% docker-compose build
% docker-compose up -d
% docker-compose logs
# Find and copy http://localhost:8080/?token=...
```

Otherwise, follow the instructions below.

### Create `Dockerfile`

Create a directory (e.g. `kaggleenv`) and go there. If you clone the sample repository, just `cd kaggleenv`.

Create `Dockerfile` like the following. See details [here](https://docs.docker.com/engine/reference/builder/#format). If you use CPU instead of GPU, edit `FROM` lines.

```Dockerfile
# for CPU
# FROM gcr.io/kaggle-images/python:latest
# for GPU
FROM gcr.io/kaggle-gpu-images/python:latest

# apply patch to enable token and change notebook directory to /tmp/working
# see jupyter_notebook_config.py.patch
COPY jupyter_notebook_config.py.patch /opt/jupyter/.jupyter/
RUN (cd /opt/jupyter/.jupyter/ && patch < jupyter_notebook_config.py.patch)

# add extra modules here
# RUN pip install -U pip
```

You can specify a tag (e.g. edit `latest` to `v99`) to keep using the same environment, otherwise it fetches latest one every time you build image. You can find tags from [GCR page](https://gcr.io/kaggle-images/python).

### Create `jupyter_notebook_config.py.patch`

This Docker image will run Jupyter Lab with startup script `/run_jupyter.sh` and config `/opt/jupyter/.jupyter/jupyter_notebook_config.py`. It needs to be tweaked like the following.

- Enable token (so that VSCode can connect properly)
- Change notebook directory to `/tmp/working`

Create `jupyter_notebook_config.py.patch` like the following.

```patch
--- jupyter_notebook_config.py.orig	2021-02-17 07:52:56.000000000 +0000
+++ jupyter_notebook_config.py	2021-04-05 06:19:23.640584228 +0000
@@ -4 +4 @@
-c.NotebookApp.token = ''
+# c.NotebookApp.token = ''
@@ -11 +11,2 @@
-c.NotebookApp.notebook_dir = '/home/jupyter'
+# c.NotebookApp.notebook_dir = '/home/jupyter'
+c.NotebookApp.notebook_dir = '/tmp/working'
```

Note: This patch may not work in the future version of [Kaggle Python docker image](https://github.com/Kaggle/docker-python). In that case, create a new patch with `diff -u original new > patch`. At least I confirmed this patch work on `v99` tag.

### Create `docker-compose.yml`

Create `docker-compose.yml` like the following. See details [here](https://docs.docker.com/compose/). This setting mounts current directory on your local machine to `/tmp/working` on the container. If you use CPU instead of GPU, comment out `runtime: nvidia`.

```yaml
version: "3"
services:
  jupyter:
    build: .
    volumes:
      - $PWD:/tmp/working
    working_dir: /tmp/working
    ports:
      - "8080:8080"
    hostname: localhost
    restart: always
    # for GPU
    runtime: nvidia
```

### Create `.dockerignore`

Create `.dockerignore` like the following. See details [here](https://docs.docker.com/engine/reference/builder/#dockerignore-file). This setting specifies subdirectories and files that should be ignored when building Docker images. You will **mount** the current directory, so you do not need to **include** subdirectories and files into image. Especially, `input` directory should be ignored because it may include large files so that build process may take long time.

```
README.md
input
output
.git
.gitignore
.vscode
.ipynb_checkpoints
```

### Run `docker-compose build`

Run `docker-compose build` to build the Docker image. See details [here](https://docs.docker.com/compose/reference/build/).

**Note: This process may take 20-30 minutes and 18.5GB disks for data downloads on your local machine**.

```sh
% docker-compose build
```

Confirm the image by `docker images`.

```sh
% docker images
REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
kaggleenv_jupyter   latest    ............   28 minutes ago   18.5GB
```

### Run `docker-compose up -d`

Run `docker-compose up -d` to start Docker container in the background. In addition, the container will automatically run at startup VM instance or local machine. See details [here](https://docs.docker.com/compose/reference/up/) and [here](https://docs.docker.com/config/containers/start-containers-automatically/).

```sh
% docker-compose up -d
% docker ps -a
% docker inspect -f "{{.Name}} {{.HostConfig.RestartPolicy.Name}}" $(docker ps -aq)
```

Find the Notebook URL on the log and copy it.

```
% docker-compose logs

http://localhost:8080/?token=...
```

### Open Notebook by web browser

- Open web browser and type the Notebook URL (`http://localhost:8080/?token=...`).
- Create a `Python 3` Notebook.
- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

![jupyter_kaggle](https://user-images.githubusercontent.com/1632335/113484058-5afcc700-94e1-11eb-9f2e-a6fd01a0121a.png)

### Setup Kaggle API

[Setup Kaggle API credentials](https://github.com/Kaggle/kaggle-api#api-credentials).

After that, `~/.kaggle/kaggle.json` file should be on your local machine.

- Copy `~/.kaggle/kaggle.json` to current directory **on your local machine** (so that it can be accessed from the container at `/tmp/working/kaggle.json`)

```sh
% cp -p ~/.kaggle/kaggle.json .
```

- Create a code cell on the Notebook and confirm `/tmp/working/kaggle.json` on the container.

```sh
!ls -l /tmp/working/kaggle.json
-rw------- 1 root root 65 Mar 22 07:59 /tmp/working/kaggle.json
```

- Copy it to `~/.kaggle` directory on the container.

```sh
!cp -p /tmp/working/kaggle.json ~/.kaggle/
```

- Remove `kaggle.json` on the current directory **on your local machine**.

```sh
% rm -i kaggle.json
```

- Try `kaggle` command on the Notebook.

```sh
!kaggle competitions list
```

### Shutdown the AI Platform Notebook (GCP)

After you finished your work, stop the VM instance.

- Access https://console.cloud.google.com/ai/platform/notebooks/list/instances
- Check the VM instance on the list
- Click `STOP` or `DELETE`

If you `DELETE` the VM instance, you will not charge anything (as far as I know).

However, if you `STOP` the VM instance, you will charge for resources (e.g. persistent disk) until you `DELETE` it. You should `DELETE` if you do not use it for a long time (though you must setup the environment again). See details [here](https://cloud.google.com/compute/docs/instances/stop-start-instance#billing).

### Run `docker-compose down` (local machine)

After you finished your work, run `docker-compose down` to stop Docker container. See details [here](https://docs.docker.com/compose/reference/down/).

```sh
% docker-compose down
```

## Setup VSCode to open remote Notebooks

If you are using [Visual Studio Code (VSCode)](https://code.visualstudio.com/), you can setup VSCode to connect to the remote Notebook.

### [Optional] Install the latest Notebook extension

There is a revamped version of Notebook extension. See details [here](https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/). I recommend installing it because this new version can handle custom extensions (e.g. key bindings) properly inside code cells, etc.

![vscode_jupyter](https://user-images.githubusercontent.com/1632335/113431667-0d1b8c80-9417-11eb-8183-e89084670f39.png)

### Connect to the remote Notebook

Connect to the remote Notebook. See details [here](https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server).

- Open `Command Palette...`
- Type `Jupyter: Specify local or remote Jupyter server for connections`

![vscode_palette](https://user-images.githubusercontent.com/1632335/113466765-3bca4f00-9479-11eb-914e-7d90ac073daf.png)

- Choose `Existing: Specify the URI of an existing server`

![vscode_existing](https://user-images.githubusercontent.com/1632335/113467276-01fb4780-947d-11eb-93f6-a4f5a974d323.png)

- Specify the Notebook URL (`http://localhost:8080/?token=...`)

Note: `token` must be specified.

![vscode_uri](https://user-images.githubusercontent.com/1632335/113467238-c2ccf680-947c-11eb-9388-1ecd2297eb6b.png)

- Press `Reload` button

![vscode_reload](https://user-images.githubusercontent.com/1632335/113467629-31ab4f00-947f-11eb-9062-1bbc5566ab86.png)

- Open `Command Palette...`
- Type `Jupyter: Create New Blank Notebook`

![vscode_create](https://user-images.githubusercontent.com/1632335/113467560-9f0ab000-947e-11eb-865e-62beeed43f12.png)

- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

![vscode_new_notebook](https://user-images.githubusercontent.com/1632335/113467525-75518900-947e-11eb-86e1-e9e79d84e610.png)

## Increase Docker memory (local machine)

Sometimes containers need much memory more than 2GB. You can increase the amount of memory from Docker preferences.

- Click Docker icon
- Choose `Preferences...`
- Click `Resources`
- Click `ADVANCED`
- Increase `Memory` slider over `2.00 GB`
- Click `Apply & Restart`

![docker_preferences](https://user-images.githubusercontent.com/1632335/113466563-dc1f7400-9477-11eb-861d-fa4dd0ce357c.png)

## Maintain Docker containers, images and cache

Basically `docker-compose up -d` and `docker-compose down` work well, but sometimes you may need to use these commands to maintain Docker containers, images and cache.

- How to remove containers. See details [here](https://docs.docker.com/engine/reference/commandline/rm/).

```sh
% docker ps -a  # confirm container ids to remove
% docker rm CONTAINER  # remove container by id
% docker rm $(docker ps --filter status=exited -q)  # remove all containers that have exited
```

- How to remove images. See details [here](https://docs.docker.com/engine/reference/commandline/rmi/).

```sh
% docker images  # confirm image ids to remove
% docker rmi IMAGE  # remove image by id
```

- How to remove cache. See details [here](https://docs.docker.com/engine/reference/commandline/builder_prune/) and [here](https://docs.docker.com/engine/reference/commandline/volume_prune/).

```sh
% docker system df  # confirm how much disk used by cache
% docker builder prune
% docker volume prune
```

## TODO

- Workflow to submit local Notebook to Kaggle

## Links

- https://github.com/Kaggle/docker-python
- https://medium.com/kaggleteam/how-to-get-started-with-data-science-in-containers-6ed48cb08266
- https://github.com/susumuota/kaggleenv
- https://cloud.google.com/ai-platform/notebooks/docs
- https://cloud.google.com/sdk/docs/quickstart
- https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server
- https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/
- https://www.kaggle.com/product-feedback/159602
- https://amalog.hateblo.jp/entry/data-analysis-docker  (Japanese)

## Author

Susumu OTA

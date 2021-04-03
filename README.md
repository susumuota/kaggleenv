# How to setup "Python Notebooks on Kaggle" environment on your local machine by Docker and VSCode

![vscode_jupyter](https://user-images.githubusercontent.com/1632335/113431667-0d1b8c80-9417-11eb-8183-e89084670f39.png)

This is a short description about how to setup ["Python Notebooks on Kaggle"](https://github.com/Kaggle/docker-python) environment on your local machine by [Docker](https://www.docker.com/) and how to setup [Visual Studio Code (VSCode)](https://code.visualstudio.com/) to connect the environment.

A primally information source comes from [Kaggle's repository](https://github.com/Kaggle/docker-python) and [guide](https://medium.com/kaggleteam/how-to-get-started-with-data-science-in-containers-6ed48cb08266) (but unfortunately it's a bit obsoleted guide written in 2016).

**Note: This method may take 30 minutes and 18.5GB disks for data downloads.**

All files in this document are available on [my repository](https://github.com/susumuota/kaggleenv).

## Install Docker

[Install and setup Docker](https://docs.docker.com/get-docker/).

After that, `docker` and `docker-compose` commands should be available on your terminal.

```sh
% docker -v
Docker version 20.10.5, build 55c4c88
% docker-compose -v
docker-compose version 1.28.5, build c4eb3a1f
```

## Create `Dockerfile`

Create a directory (e.g. `projectname`) and go to there.

Create `Dockerfile` like the following. See details [here](https://docs.docker.com/engine/reference/builder/#format).

```Dockerfile
FROM gcr.io/kaggle-images/python:v99
# FROM gcr.io/kaggle-gpu-images/python:v99  # for GPU

# add extra modules here
RUN pip install -U pip
```

You could specify a tag (e.g. `v99`) to keep using same environment, otherwise it fetches latest one every time you build image. You can find tags from [GCR page](https://gcr.io/kaggle-images/python).

## Create `docker-compose.yml`

Create `docker-compose.yml` like the following. See details [here](https://docs.docker.com/compose/). This setting mounts current directory on your local machine to `/tmp/working` on the container.

```yaml
version: "3"
services:
  jupyter:
    build: .
    volumes:
      - $PWD:/tmp/working
    working_dir: /tmp/working
    ports:
      - "8888:8888"
    hostname: localhost
    command: jupyter-lab --ip=0.0.0.0 --allow-root --no-browser --notebook-dir=/tmp/working
```

## Create `.dockerignore`

Create `.dockerignore` like the following. See details [here](https://docs.docker.com/engine/reference/builder/#dockerignore-file). This setting specifies subdirectories and files that should be ignored when building docker image. Basically, you will **mount** current directory, so you don't need to **include** subdirectories and files into image. Especially `input` directory should be ignored because it may include large files so that build process may take long time.

```
README.md
input
output
.git
.gitignore
.vscode
```

## Run `docker-compose build`

Run `docker-compose build` to build docker image. See details [here](https://docs.docker.com/compose/reference/build/).

**Note: This may take 30 minutes and 18.5GB disks for data downloads**.

```sh
% docker-compose build
```

Confirm the image by `docker images`.

```sh
% docker images
REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
projectname_jupyter   latest    ............   28 minutes ago   18.5GB
```

## Run `docker-compose up`

Run `docker-compose up` to start docker container. See details [here](https://docs.docker.com/compose/reference/up/).

```sh
% docker-compose up
```

Find the Notebook URL on the log and copy it.

```
http://localhost:8888/?token=...
```

## Open Notebook by web browser

- Open web browser and type the Notebook URL (`http://localhost:8888/?token=...`).
- Create a `Python 3` Notebook.
- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

## Setup Kaggle API


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

## Run `docker-compose down`

After you finished your work, run `docker-compose down` to stop docker container. See details [here](https://docs.docker.com/compose/reference/down/).

```sh
% docker-compose down
```

## Remove containers, images and cache

Basically `docker-compose up` and `docker-compose down` works well, but sometimes you may need to use these commands.

How to remove containers. See details [here](https://docs.docker.com/engine/reference/commandline/rm/).

```sh
docker ps -a  # confirm container ids to remove
docker rm CONTAINER  # remove container by id
docker rm $(docker ps --filter status=exited -q)  # remove all containers that have exited
```

How to remove images. See details [here](https://docs.docker.com/engine/reference/commandline/rmi/).

```sh
docker images  # confirm image ids to remove
docker rmi IMAGE  # remove image by id
```

How to remove cache. See details [here](https://docs.docker.com/engine/reference/commandline/builder_prune/) and [here](https://docs.docker.com/engine/reference/commandline/volume_prune/).

```sh
docker system df  # confirm how much disk used by cache
docker builder prune
docker volume prune
```

## Setup VSCode to open Notebooks

If you are using [Visual Studio Code (VSCode)](https://code.visualstudio.com/), you can setup VSCode to connect the Notebook.

### [Optional] Install newest Notebook extension

There is a revamped version of Notebook extension. See details [here](https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/). I recommend to install it because this new version can handle custom extensions (e.g. key bindings) properly inside code cells, etc.

![vscode_jupyter](https://user-images.githubusercontent.com/1632335/113431667-0d1b8c80-9417-11eb-8183-e89084670f39.png)

### Connect to remote Notebook

Connect to the remote Notebook. See details [here](https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server).

- Open `Command Palette...`
- Type `Jupyter: Specify local or remote Jupyter server for connections`

![vscode_palette](https://user-images.githubusercontent.com/1632335/113466765-3bca4f00-9479-11eb-914e-7d90ac073daf.png)

- Choose `Existing: Specify the URI of an existing server`

![vscode_existing](https://user-images.githubusercontent.com/1632335/113467276-01fb4780-947d-11eb-93f6-a4f5a974d323.png)

- Specify the Notebook URL (`http://localhost:8888/?token=...`)

![vscode_uri](https://user-images.githubusercontent.com/1632335/113467238-c2ccf680-947c-11eb-9388-1ecd2297eb6b.png)

- Press `Reload` button

![vscode_reload](https://user-images.githubusercontent.com/1632335/113467629-31ab4f00-947f-11eb-9062-1bbc5566ab86.png)

- Open `Command Palette...`
- Type `Jupyter: Create New Blank Notebook`

![vscode_create](https://user-images.githubusercontent.com/1632335/113467560-9f0ab000-947e-11eb-865e-62beeed43f12.png)

- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

![vscode_new_notebook](https://user-images.githubusercontent.com/1632335/113467525-75518900-947e-11eb-86e1-e9e79d84e610.png)

## Increase Docker memory

Sometimes containers need much memory more than 2GB (is it default value?). You can increase amount of memory from Docker preferences.

- Click Docker icon
- Choose `Preferences...`
- Click `Resources`
- Click `ADVANCED`
- Increase `Memory` slider over `2.00 GB`
- Click `Apply & Restart`

![docker_preferences](https://user-images.githubusercontent.com/1632335/113466563-dc1f7400-9477-11eb-861d-fa4dd0ce357c.png)

## TODO

- Setup on GCP with GPU
- Workflow to submit local Notebook to Kaggle

## Links

- https://github.com/Kaggle/docker-python
- https://medium.com/kaggleteam/how-to-get-started-with-data-science-in-containers-6ed48cb08266
- https://github.com/susumuota/kaggleenv
- https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server
- https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/
- https://amalog.hateblo.jp/entry/data-analysis-docker  (Japanese)

## Author

Susumu OTA

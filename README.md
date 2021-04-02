# How to setup "Python Notebooks on Kaggle" environment on your local machine by Docker and VSCode

This is a short description about how to create "Python Notebooks on Kaggle" environment on your local machine by Docker and how to setup Visual Studio Code (VSCode) to connect the environment.

A primally information source comes from [here](https://github.com/Kaggle/docker-python). But unfortunately it lacks tutorials to setup environment right now.

Note: This method may take 30 minutes and **18.5GB** for data downloads. If it's too much for your computer, you should consider an another way.

All files in this document are available from [here](https://github.com/susumuota/kaggleenv)

## Install Docker

Install and setup Docker from [here](https://docs.docker.com/get-docker/).

After that, `docker` and `docker-compose` commands should be available on your terminal.

```sh
% docker -v
Docker version 20.10.5, build 55c4c88
% docker-compose -v
docker-compose version 1.28.5, build c4eb3a1f
```

## Edit `Dockerfile`

Create a directory (e.g. `projectname`) and go to there. Or open terminal and type `git clone https://github.com/susumuota/kaggleenv.git`.

Create a `Dockerfile` like the following. See details [here](https://docs.docker.com/engine/reference/builder/).

```Dockerfile
FROM gcr.io/kaggle-images/python:v99
# FROM gcr.io/kaggle-gpu-images/python:v99  # for GPU

# add extra modules here
RUN pip install -U pip
```

You could specify tag (e.g. `v99`) to keep using same environment, otherwise it always changes to latest one. You can find tags from [here](https://gcr.io/kaggle-images/python). `v99` is latest right now.

## Edit `docker-compose.yml`

Edit `docker-compose.yml`. See details [here](https://docs.docker.com/compose/).

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

## Run `docker-compose build`

This may take 30 minutes and **18.5GB** data downloads.

```sh
% docker-compose build
```

See details [here](https://docs.docker.com/compose/reference/build/).

Confirm by `docker images`.

```sh
% docker images
REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
projectname_jupyter   latest    ............   28 minutes ago   18.5GB
```

## Run `docker-compose up`

Run `docker-compose up` to start docker container.

See details [here](https://docs.docker.com/compose/reference/up/).

```sh
% docker-compose up
```

Find Notebook URL on the log and copy it.

```
http://localhost:8888/?token=...
```

## Open Notebook by web browser

- Open web browser and type the Notebook URL (`http://localhost:8888/?token=...`).
- Create a Python3 Notebook.
- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

## Setup VSCode to open Notebook

If you are using [Visual Studio Code (VSCode)](https://code.visualstudio.com/), you can setup VSCode to connect the Notebook.

### [Optional] Install newest Notebook extension

There is a revamped version of Notebook extention. See details [here](https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/). I recommend to install it because this new version can handle custom extensions (e.g. key bindings) properly inside code cells, etc.

### Connect to remote Notebook

Connect to the remote Notebook. See details [here](https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server).

- Open `Settings`
- Change `Jupyter: Jupyter Server Type` to `remote`
- Open `Command Palette...`,
- Type `Jupyter: Specify local or remote Jupyter server for connections`
- Choose `Existing: Specify the URI of an existing server`
- Specify the Notebook URL (`http://localhost:8888/?token=...`)
- Press `Reload` button
- Open `Command Palette...`
- Type `Jupyter: Create New Blank Notebook`
- Create code cells and execute `!pwd`, `!ls` and `!pip list` to confirm Python environment.

## Remove containers, images and cache

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

## Setup Kaggle API on Notebook

Open terminal **on your local machine** and copy `~/.kaggle/kaggle.json` to current directory (so that it can be accessed from the container at `/tmp/working/kaggle.json`)

```sh
% cp -p ~/.kaggle/kaggle.json .
```

Create a code cell on the Notebook and type

```sh
!ls -l /tmp/working/kaggle.json
-rw------- 1 root root 65 Mar 22 07:59 /tmp/working/kaggle.json
```

Copy it to `~/.kaggle` directory on the container.

```sh
!cp -p /tmp/working/kaggle.json ~/.kaggle
```

Remove `kaggle.json` on the current directory **on your local machine**.

```sh
% rm -i kaggle.json
```

Try `kaggle` command on the Notebook.

```sh
!kaggle competitions list
...
```

Done!

## Increase Docker memory

Sometimes containers need much memory more than 2GB (default value). You can increase amount of memory from Docker preferences.

- Click Docker icon
- `Preferences...`
- `ADVANCED`
- `Memory`
- Increase value over `2.00 GB`

## TODO

- Setup on GCP with GPU
- Workflow to submit local Notebook to Kaggle

## Links

- https://github.com/Kaggle/docker-python
- https://github.com/susumuota/kaggleenv.git
- https://code.visualstudio.com/docs/python/jupyter-support#_connect-to-a-remote-jupyter-server
- https://devblogs.microsoft.com/python/notebooks-are-getting-revamped/
- https://amalog.hateblo.jp/entry/data-analysis-docker  (Japanese)

## Author

Susumu OTA

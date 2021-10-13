# for CPU
# FROM gcr.io/kaggle-images/python:v105
# for GPU
FROM gcr.io/kaggle-gpu-images/python:v105

# apply patch to enable token and change notebook directory to /kaggle/working
# see jupyter_notebook_config.py.patch
COPY jupyter_notebook_config.py.patch /opt/jupyter/.jupyter/
RUN (cd /opt/jupyter/.jupyter/ && patch < jupyter_notebook_config.py.patch)

# add extra modules here
# RUN pip install -U pip

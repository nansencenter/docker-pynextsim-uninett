FROM jupyter/scipy-notebook:d990a62010ae as miniconda
RUN conda config --set channel_priority strict && \
    conda install --quiet --yes --update-all -c conda-forge \
    'nbconvert' \
    'tqdm' \
    'yapf==0.29*' \
    'rise==5.6.*' \
    'nbdime==2.*' \
    'jupyterhub==1.1.0' \
    'jupyterlab==2.1.*' \
    'jupyter_contrib_nbextensions==0.5*' \
    'jupyter-server-proxy==1.4*' && \
    jupyter labextension install \
    '@jupyterlab/github' \
    'nbdime-jupyterlab' \
    '@jupyterlab/toc' \
    '@jupyterlab/hub-extension' && \
    pip install ipyparallel==6.2.* jupyterlab-github escapism && \
    git clone https://github.com/paalka/nbresuse /tmp/nbresuse && pip install /tmp/nbresuse/ && \
    jupyter serverextension enable --py nbresuse --sys-prefix && \
    jupyter serverextension enable jupyter_server_proxy --sys-prefix && \
    jupyter nbextension install --py nbresuse --sys-prefix && \
    jupyter nbextension enable --py nbresuse --sys-prefix

RUN conda install --quiet --yes --update-all -c conda-forge cartopy gdal
RUN pip install netcdftime cmocean netcdf4 pyproj shapely


FROM jupyter/scipy-notebook:d990a62010ae
LABEL maintainer NERSC <anton.korosov@nersc.no>

USER root

# Setup ENV for Appstore to be picked up
ENV APP_UID=999 \
    APP_GID=999 \
    PKG_JUPYTER_NOTEBOOK_VERSION=5.7.x
RUN groupadd -g "$APP_GID" notebook && \
    useradd -m -s /bin/bash -N -u "$APP_UID" -g notebook notebook && \
    usermod -G users notebook && chmod go+rwx -R "$CONDA_DIR/bin"
COPY --chown=notebook:notebook --from=miniconda $CONDA_DIR $CONDA_DIR
# hadolint ignore=DL3002
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    less \
    net-tools \
    man-db \
    iputils-ping \
    screen \
    tmux \
    graphviz \
    cmake \
    rsync \
    p7zip-full \
    tzdata \
    vim \
    unrar \
    ca-certificates \
    sudo \
    openmpi-bin \
    libopenmpi-dev \
&& apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/share/zoneinfo/Europe/Oslo /etc/localtime

ENV NEXTSIMDIR=/tmp \
    BAMGDIR=/opt/local/bamg

# copy source, compile and copy libs of BAMG
COPY bamg /tmp/contrib/bamg
WORKDIR /tmp/contrib/bamg/src
RUN make -j8 \
&&  mkdir -p /opt/local/bamg/lib  \
&&  cp -d $NEXTSIMDIR/lib/libbamg* /opt/local/bamg/lib/ \
&&  cp -r $NEXTSIMDIR/contrib/bamg/include /opt/local/bamg \
&&  echo /opt/local/bamg/lib/ >> /etc/ld.so.conf
RUN ldconfig


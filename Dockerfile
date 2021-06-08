FROM quay.io/uninett/jupyter-spark:20210514-6405497
LABEL maintainer="Anton Korosov <anton.korosov@nersc.no>"
LABEL version="0.4.0"

USER root
RUN apt-get update \
&&  apt-get install --no-install-recommends -y libopenmpi-dev \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/*

# copy source, compile and copy libs of BAMG
ENV NEXTSIMDIR=/tmp \
    BAMGDIR=/opt/local/bamg
COPY bamg /tmp/contrib/bamg
WORKDIR /tmp/contrib/bamg/src
RUN make -j8 \
&&  mkdir -p /opt/local/bamg/lib  \
&&  cp -d $NEXTSIMDIR/lib/libbamg* /opt/local/bamg/lib/ \
&&  cp -r $NEXTSIMDIR/contrib/bamg/include /opt/local/bamg \
&&  echo /opt/local/bamg/lib/ >> /etc/ld.so.conf
RUN ldconfig
ENV NEXTSIMDIR=/nextsim

# install conda environment
USER notebook
COPY environment.yml /tmp/environment.yml
RUN  conda env create -f /tmp/environment.yml \
&&   conda clean --all -f -y
USER root
RUN bash -c 'source activate pynextsim \
&& ipython kernel install --name=pynextsim --display-name="Python 3 (pynextsim)"'

USER notebook
WORKDIR $HOME



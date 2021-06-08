FROM quay.io/uninett/jupyter-spark:20210514-6405497
LABEL maintainer="Anton Korosov <anton.korosov@nersc.no>"

USER root

RUN apt-get update \
&&  apt-get install -y libopenmpi-dev

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

USER notebook
COPY environment.yml /tmp/environment.yml
RUN  conda env create -f /tmp/environment.yml
#RUN conda create -n pynextsim -c conda-forge -y --file /tmp/environment.txt

#WORKDIR $HOME



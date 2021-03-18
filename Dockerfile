FROM quay.io/uninett/jupyterhub-singleuser:20210215-8a4afc6
LABEL maintainer="Anton Korosov <anton.korosov@nersc.no>"

USER root

RUN apt-get update \
&&  apt-get install -y libgdal* gdal* libopenmpi-dev \
&&  pip install netcdftime cmocean netcdf4 pyproj shapely cartopy xarray

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

RUN chmod go+rwx -R "$CONDA_DIR/bin" \
&&  chown notebook:notebook -R "$CONDA_DIR/bin" "$HOME" \
&&  chown notebook:notebook "$CONDA_DIR"

USER notebook
WORKDIR $HOME
CMD ["/usr/local/bin/start-notebook.sh"]

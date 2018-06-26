#
#
#
FROM eu.gcr.io/was-config-tool/was_9.0.0.7_dmgr:1.1

MAINTAINER Hermann Huebler "hermann_huebler@de.ibm.com"

LABEL name="eu.gcr.io/was-config-tool/was_9.0.0.7_dmgr:1.1.ci"

RUN rm -rf /opt/gcptest && \
    cd /opt && \
    git clone https://github.com/hhue13/gcptest.git && \
    # git clone git@github.com:hhue13/gcptest.git && \
    cp gcptest/bin/startContainer.sh /bin/startContainer.sh && \
    chmod +x /bin/startContainer.sh && \
    echo "Done ..."

ENTRYPOINT ["/bin/startContainer.sh"]

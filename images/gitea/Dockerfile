FROM gitea/gitea:1.6.1

USER root
COPY /root/etc/s6/gitea-init/ /etc/s6/gitea-init/
RUN chmod -R 755 /etc/s6/gitea-init
RUN ( echo; echo "chmod 0755 /data" ) >> /etc/s6/gitea/setup

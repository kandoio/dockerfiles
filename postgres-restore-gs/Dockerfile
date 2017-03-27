FROM alpine:3.4
MAINTAINER Johannes Schickling "schickling.j@gmail.com"

ADD install.sh install.sh
RUN sh install.sh && rm install.sh
ENV PATH /root/google-cloud-sdk/bin:$PATH

ENV POSTGRES_DATABASE **None**
ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV GS_BUCKET **None**
ENV GS_PREFIX 'backup'
ENV DROP_PUBLIC 'no'

ADD restore.sh restore.sh

CMD ["sh", "restore.sh"]

FROM armory/armory-cli:latest
WORKDIR /
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
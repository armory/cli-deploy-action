FROM armory/armory-cli:latest

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ['/entrypoint.sh']
FROM th3morg/a-cli:v0.30.0-rc-1

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
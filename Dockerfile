FROM th3morg/a-cli:v0.30.0-rc-2

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
FROM curlimages/curl:latest as lineage_builder
RUN curl https://api.github.com/repos/armory/cli-deploy-action/pulls/21 > /tmp/lineage.json
RUN echo "$GITHUB_ACTOR" > /tmp/github_actor.txt

FROM armory/armory-cli:latest

COPY --from=lineage_builder /tmp/lineage.json /lineage.json
COPY --from=lineage_builder /tmp/github_actor.txt /github_actor.txt
RUN cat github_actor.txt
COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
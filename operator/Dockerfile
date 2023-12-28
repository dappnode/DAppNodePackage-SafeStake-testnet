ARG UPSTREAM_VERSION

FROM parastate/dvf-operator:${UPSTREAM_VERSION}

# To get the Public IP from the Dappmanager API
RUN apt update && apt install -y jq curl

ENV OPERATOR_NETWORK=prater \
    REGISTRY_CONTRACT_ADDRESS=f31605c163b54C00371b10af21E8eDa32B969F21 \
    NETWORK_CONTRACT_ADDRESS=C1b4AA96afA5D3566A86920e69Fc6C274d54F3B4 \
    TTD=10790000 \
    GAS_LIMIT_INTEGER=30000000

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
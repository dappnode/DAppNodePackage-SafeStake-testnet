#!/bin/bash

NODE_PUBKEY_FILE_PATH=/root/.lighthouse/v1/${OPERATOR_NETWORK}/node_key.json

case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER in
"goerli-geth.dnp.dappnode.eth")
    EXECUTION_CLIENT_WS="ws://goerli-geth.dappnode:8546"
    ;;
"goerli-nethermind.dnp.dappnode.eth")
    EXECUTION_CLIENT_WS="ws://goerli-nethermind.dappnode:8546"
    ;;
"goerli-besu.dnp.dappnode.eth")
    EXECUTION_CLIENT_WS="ws://goerli-besu.dappnode:8546"
    ;;
"goerli-erigon.dnp.dappnode.eth")
    EXECUTION_CLIENT_WS="ws://goerli-erigon.dappnode:8545"
    ;;
*)
    echo "Unknown execution client. Using $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER as WS endpoint."
    EXECUTION_CLIENT_WS="$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_PRATER"
    ;;
esac

case "$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER" in
"prysm-prater.dnp.dappnode.eth")
    BEACON_NODE_ENDPOINT="http://beacon-chain.prysm-prater.dappnode:3500"
    ;;
"teku-prater.dnp.dappnode.eth")
    BEACON_NODE_ENDPOINT="http://beacon-chain.teku-prater.dappnode:3500"
    ;;
"lighthouse-prater.dnp.dappnode.eth")
    BEACON_NODE_ENDPOINT="http://beacon-chain.lighthouse-prater.dappnode:3500"
    ;;
"nimbus-prater.dnp.dappnode.eth")
    BEACON_NODE_ENDPOINT="http://beacon-validator.nimbus-prater.dappnode:4500"
    ;;
"lodestar-prater.dnp.dappnode.eth")
    BEACON_NODE_ENDPOINT="http://beacon-chain.lodestar-prater.dappnode:3500"
    ;;
*)
    echo "Unknown consensus client. Using $_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER as beacon API endpoint."
    BEACON_NODE_ENDPOINT="$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER"
    ;;
esac

# 1. Execute the dvf_key_tool to generate the keys if they don't exist
if [ -f "$NODE_PUBKEY_FILE_PATH" ]; then
    echo "Keys already exist. Skipping key generation."
else
    echo "Keys don't exist. Generating keys..."
    dvf_key_tool ${OPERATOR_NETWORK}
    echo "Keys generated and stored in $NODE_PUBKEY_FILE_PATH"
fi

# The keys have the following format:
# {
#     "name": "A9/9999CQXgr8+yja4kH9Jc9MqaH12yTf863PZE+dQDp",
#     "secret": "ewvw8tb5PT1GJvH6b5B+ssUMJbyTTUfUucxmNkwUdVY="
# }

# 2. POST the public key to the dappmanager
NODE_PUBKEY=$(jq -r '.name' $NODE_PUBKEY_FILE_PATH)
curl -X POST "http://my.dappnode/data-send?key=pubkey&data=${NODE_PUBKEY}"

# 3. Wait until the operator is registered in https://testnet.safestake.xyz/
if [ -z "$OPERATOR_ID" ]; then
    echo "OPERATOR_ID is empty. Register in https://testnet.safestake.xyz/ and set your operator ID in the package configuration and click UPDATE."
    sleep infinity
else
    echo "OPERATOR_ID has been set to $OPERATOR_ID."
fi

# 3. Start operator
NODE_IP=$(curl -s http://my.dappnode/global-envs | jq -r '.PUBLIC_IP')
dvf validator_client --debug-level=info --network=${OPERATOR_NETWORK} --beacon-nodes=${BEACON_NODE_ENDPOINT} --api=${API_SERVER} --ws-url=${EXECUTION_CLIENT_WS} --ip=${NODE_IP} --id=${OPERATOR_ID} --registry-contract=${REGISTRY_CONTRACT_ADDRESS} --network-contract=${NETWORK_CONTRACT_ADDRESS} --base-port=26000 2>&1

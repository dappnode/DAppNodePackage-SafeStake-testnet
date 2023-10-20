#!/bin/bash

NODE_PUBKEY_FILE_PATH=/root/.lighthouse/v1/${OPERATOR_NETWORK}/node_key.json
DAPPMANAGER_ALIASES=("my.dappnode" "dappmanager.dappnode" "dappmanager.dnp.dappnode.eth.dappmanager.dappnode" "172.33.1.7")

MAX_RETRIES=5
SLEEP_DURATION=10

function retry_request() {
    local callback=$1
    local max_retries=${2:-5}    # Default to 5 retries if not provided
    local sleep_duration=${3:-5} # Default to 5 seconds if not provided

    local retry_count=0
    local success=false
    local result=""

    while [ $retry_count -lt $max_retries ] && [ $success == false ]; do
        for alias in "${DAPPMANAGER_ALIASES[@]}"; do
            result=$($callback "$alias")

            # Check if callback succeeded
            if [[ $? -eq 0 ]]; then
                # Echoing only the result upon successful callback
                echo "$result"
                return 0
            else
                echo "[ERROR] Failed request to ${alias} on attempt $((retry_count + 1))"
            fi
        done

        # If request was unsuccessful, sleep before retrying
        if [ $success == false ]; then
            sleep $sleep_duration
            ((retry_count++))
        fi
    done

    return 1
}

# Callback function for posting the NODE_PUBKEY
function post_pubkey() {
    local alias=$1
    curl -X POST "http://${alias}/data-send?key=pubkey&data=${NODE_PUBKEY}"
    return $?
}

# Callback function for getting the PUBLIC_IP
function get_public_ip() {
    local alias=$1
    local result=$(curl -s "http://${alias}/global-envs" | jq -r '.PUBLIC_IP')

    # Check if the result is not empty and not "null"
    if [[ -z "$result" || "$result" == "null" ]]; then
        # If result is empty or "null", return an error code
        return 1
    else
        # Echo the result so that it can be captured by retry_request
        echo "$result"
        return 0
    fi
}

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
    echo "[INFO] Keys already exist. Skipping key generation."
else
    echo "[INFO] Keys don't exist. Generating keys..."
    dvf_key_tool ${OPERATOR_NETWORK}

    # If command returns an error, exit
    if [ $? -ne 0 ]; then
        echo "[ERROR] Error generating keys. Exiting..."
        exit 1
    fi

    echo "[INFO] Keys generated and stored in $NODE_PUBKEY_FILE_PATH"
fi

# The keys have the following format:
# {
#     "name": "A9/9999CQXgr8+yja4kH9Jc9MqaH12yTf863PZE+dQDp",
#     "secret": "ewvw8tb5PT1GJvH6b5B+ssUMJbyTTUfUucxmNkwUdVY="
# }

# 2. POST the public key to the dappmanager
NODE_PUBKEY=$(jq -r '.name' $NODE_PUBKEY_FILE_PATH)
if ! retry_request post_pubkey $MAX_RETRIES $SLEEP_DURATION; then
    echo "[ERROR] All attempts to post node public key to dappmanager failed after $MAX_RETRIES retries."
    exit 1
fi

# 3. Wait until the operator is registered in https://testnet.safestake.xyz/
if [ -z "$OPERATOR_ID" ]; then
    echo "[INFO] OPERATOR_ID is empty. Register in https://testnet.safestake.xyz/ and set your operator ID in the package configuration and click UPDATE."
    sleep infinity
else
    echo "[INFO] OPERATOR_ID has been set to $OPERATOR_ID."
fi

# 4. Start operator

# If _DAPPNODE_GLOBAL_PUBLIC_IP is set, use it as NODE_IP
if [ -n "$_DAPPNODE_GLOBAL_PUBLIC_IP" ]; then
    echo "[INFO] _DAPPNODE_GLOBAL_PUBLIC_IP is set. Using it as NODE_IP."
    NODE_IP=$_DAPPNODE_GLOBAL_PUBLIC_IP
else
    echo "[INFO] _DAPPNODE_GLOBAL_PUBLIC_IP is not set. Retrieving NODE_IP from dappmanager..."
    NODE_IP=$(retry_request get_public_ip $MAX_RETRIES $SLEEP_DURATION)

    if [[ -z "$NODE_IP" ]]; then
        echo "[ERROR] Failed to retrieve PUBLIC_IP from dappmanager after $MAX_RETRIES retries. Exiting..."
        exit 1
    fi
fi

echo "[INFO] NODE_IP set to $NODE_IP"

dvf validator_client --debug-level=info --network=${OPERATOR_NETWORK} --beacon-nodes=${BEACON_NODE_ENDPOINT} --api=${API_SERVER} --ws-url=${EXECUTION_CLIENT_WS} --ip=${NODE_IP} --id=${OPERATOR_ID} --registry-contract=${REGISTRY_CONTRACT_ADDRESS} --network-contract=${NETWORK_CONTRACT_ADDRESS} --base-port=26000 2>&1

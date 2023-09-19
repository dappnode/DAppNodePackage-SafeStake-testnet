#!/bin/bash

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
    BEACON_HTTP_API="http://beacon-chain.prysm-prater.dappnode:3500"
    ;;
"teku-prater.dnp.dappnode.eth")
    BEACON_HTTP_API="http://beacon-chain.teku-prater.dappnode:3500"
    ;;
"lighthouse-prater.dnp.dappnode.eth")
    BEACON_HTTP_API="http://beacon-chain.lighthouse-prater.dappnode:3500"
    ;;
"nimbus-prater.dnp.dappnode.eth")
    BEACON_HTTP_API="http://beacon-validator.nimbus-prater.dappnode:4500"
    ;;
"lodestar-prater.dnp.dappnode.eth")
    BEACON_HTTP_API="http://beacon-chain.lodestar-prater.dappnode:3500"
    ;;
*)
    echo "Unknown consensus client. Using $_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER as beacon API endpoint."
    BEACON_HTTP_API="$_DAPPNODE_GLOBAL_CONSENSUS_CLIENT_PRATER"
    ;;
esac

sleep infinity


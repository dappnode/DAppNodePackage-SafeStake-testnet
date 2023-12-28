# Dappnode Package: SafeStake Operator

Run your own distributed validator node with SafeStake Operator.

_Note: This package needs a Goerli/Prater full node to work. You can set it up in the Stakers>Prater page._

## Recovering an existing setup

If you have already set up your SafeStake Operator node and want to recover it, you can do so by following these steps:

1. Install the package and set the commitee fee recipient in the setup wizard

2. Go to Package Settings and input your `OPERATOR_ID`

3. Go to the Package Backup and click on `Restore` to upload your backup file

## Setting up a new operator

If you want to set up a new SafeStake Operator node, you can do so by following these steps:

1. Install the package and set the commitee fee recipient in the setup wizard

2. Go to [SafeStake](https://testnet.safestake.xyz) and register a new operator with your address and the public key of the node (you will find it in the Package Info tab)

3. Once you are registered as an operator, grab your `OPERATOR_ID` and input it in the Package Settings

4. Go to the Package Backup and click on `Backup` to download your backup file
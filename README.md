# Ionia

The First Land of Starknet Core Contracts on Aptos

## Setup

### Aptos CLI

```bash
curl -fsSL "https://aptos.dev/scripts/install_cli.py" | python3
```

[Reference](https://aptos.dev/en/build/cli/install-cli/install-cli-linux)

### Docker

```bash
curl -fsSL "https://get.docker.com" -o get-docker.sh
sudo sh get-docker.sh
```

[Reference](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)


## Testing

### Unit

```bash
aptos move test
```

### Local

Start Aptos local

```bash
aptos node run-local-testnet --with-indexer-api
```

Create a local profile

```bash
aptos init --profile <your-profile-name> --network local
```

Publish to local

```bash
aptos move publish --profile <your-profile-name> --network local
```

## StarkNet Consensus Protocol Contracts

PoC solidity implementation of the following Starknet Decentralized Protocol proposal:

- [I - Introduction](https://community.starknet.io/t/starknet-decentralized-protocol-i-introduction/2671/1)
- [II - Candidate for Leader Elections](https://community.starknet.io/t/starknet-decentralized-protocol-ii-candidate-for-leader-elections/4751)
- [III - Consensus](https://community.starknet.io/t/starknet-decentralized-protocol-iii-consensus/5386)
- [IV - Proofs in the Protocol](https://community.starknet.io/t/starknet-decentralized-protocol-iv-proofs-in-the-protocol/6030)
- [V - Checkpoints for Fast Finality](https://community.starknet.io/t/starknet-decentralized-protocol-v-checkpoints-for-fast-finality/6032)
- [VI - The Buffer Problem](https://community.starknet.io/t/starknet-decentralized-protocol-vi-the-buffer-problem/7098)
- [VII - Chained Proof Protocols & Braiding](https://community.starknet.io/t/starknet-decentralized-protocol-vii-chained-proof-protocols-braiding/18831)
## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

Explication
- MainCrowdfundingContract : Ce contrat crée et gère les campagnes en créant des instances dans Campaign.
- Campaign : Ce contrat gère les contributions, vérifie les objectifs et gère les réclamations de fonds et les remboursements.
- TokenExchange : Simplifie les échanges de tokens pour les contributeurs, offrant une modularité pour les échanges entre différents ERC-20.
- FundsManagement : Offre des fonctions utilitaires pour les transferts et remboursements, garantissant une séparation claire des responsabilités.
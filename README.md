# Plateforme de Crowdfunding avec Échange de Tokens (CROWDTK)

## Description

CROWDTK est une plateforme de crowdfunding décentralisée permettant aux créateurs de lever des fonds via un système d'échange de tokens. La particularité de cette plateforme est son mécanisme d'échange de tokens avec un ratio de 1:100, permettant aux utilisateurs d'échanger leurs tokens existants contre des tokens CROWDTK (CTK) pour participer aux campagnes.

## Architecture

### Contrats Intelligents

#### 1. CROWDTKToken (CTK)

- Token ERC20 standard
- Symbole : CTK
- Fonctionnalités :
  - Minting contrôlé par le propriétaire
  - Transferts standards ERC20
  - Gestion des permissions Ownable

#### 2. CROWD (Contrat Principal)

- Gère l'échange de tokens et les campagnes
- Fonctionnalités principales :
  ```solidity
  - exchangeTokens() : Échange des tokens externes contre des CTK (1:100)
  - createCampaign() : Création de nouvelles campagnes
  - acceptCampaign() : Validation des campagnes par l'admin
  - withdrawExchangeTokens() : Retrait des tokens échangés
  ```

#### 3. Campaign

- Gère une campagne individuelle
- Fonctionnalités :
  ```solidity
  - contribute() : Permet aux utilisateurs de contribuer en CTK
  - claimFunds() : Réclamation des fonds par l'initiateur
  - refund() : Remboursement en cas d'échec
  ```

## Fonctionnalités Clés

### 1. Échange de Tokens (1:100)

- Les utilisateurs peuvent échanger leurs tokens existants contre des CTK
- Ratio fixe : 1 token externe = 100 CROWDTK
- Processus transparent et automatisé

### 2. Gestion des Campagnes

- Création avec objectifs minimum et maximum
- Période de financement définie
- Système de validation par l'administrateur
- Suivi des contributions

### 3. Sécurité

- Contrôles d'accès stricts
- Vérifications des balances
- Gestion sécurisée des transferts
- Protection contre les dépassements

## Guide d'Utilisation

### Pour les Créateurs

1. **Création d'une Campagne**

```solidity
function createCampaign(
    uint256 _tokenTargetMinAmount,
    uint256 _tokenTargetMaxAmount,
    uint256 _startDate,
    uint256 _endDate
)
```

2. **Réclamation des Fonds**

```solidity
function claimFunds()
// Disponible une fois l'objectif minimum atteint
```

### Pour les Contributeurs

1. **Échange de Tokens**

```solidity
// Approuver d'abord les tokens d'échange
exchangeToken.approve(crowdPlatformAddress, amount);
// Échanger les tokens
crowdPlatform.exchangeTokens(amount);
```

2. **Contribution à une Campagne**

```solidity
// Approuver les tokens CTK
crowdToken.approve(campaignAddress, amount);
// Contribuer
campaign.contribute(amount);
```

3. **Demande de Remboursement**

```solidity
campaign.refund()
// Disponible si la campagne n'atteint pas son objectif minimum
```

## Tests

Le projet inclut une suite de tests complète couvrant :

- Échange de tokens
- Création et gestion de campagnes
- Contributions et remboursements
- Réclamation de fonds
- Cas d'erreur et limites

Pour exécuter les tests :

```bash
forge test
```

## Installation et Déploiement

1. **Prérequis**

```bash
- Foundry
- Node.js
- Git
```

2. **Installation**

```bash
git clone [URL_DU_REPO]
cd crowdtk-platform
forge install
```

3. **Compilation**

```bash
forge build
```

4. **Déploiement**

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url <URL> --private-key <KEY>
```

## Contribuer

1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## Sécurité

- Les smart contracts ont été développés avec les meilleures pratiques de sécurité
- Utilisation de la bibliothèque OpenZeppelin pour les standards ERC20
- Tests exhaustifs des scénarios critiques

## Licence

MIT

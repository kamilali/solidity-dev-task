# WrapMe 

A simple ERC20 wrapper interface to fungiblize liquidity mining incentives and autocompound rewards.

## Overview

Yield bearing tokens (i.e., Uni LP, 3crv, aTokens, etc.) are (obviously) fungible but as DeFi building blocks have increased in complexity, additional incentives provided to holders and stakers of yield bearing tokens often lose it's fungibility characteristics. This simple wrapper provides 3 primary features:

1) Static accounting of monotonically increasing rebasing tokens. (e.g., aTokens). This allows protocols to abstract out the additional accounting overhead of rebasing tokens into this wrapper contract.
2) Receiving external liquidity mining rewards beyond the base yield. This wrapper natively accepts rewards denominated in ERC20 tokens and native assets like ETH or WAVAX. This wrapper also provides a base implementation that allows arbitrary function calls to staking contracts to withdraw rewards into the wrapper.
3) Built in autocompounding of Reward Token -> Underlying Token. This wrapper inherits a naive router implementation that not only swaps base level ERC-20 assets across DEXs but also integrates the final step of converting a base ERC20 into the underlying yield bearing asset. It currently supports swaps into UniV2-like LP tokens, aTokens, Compound-like tokens and will support Curve LP tokens and more.

## Blueprint

```ml

contracts
└─ src
   ├─ Vault.sol — "Base implementation of the wrapper. Inherit this contract to implement custom integrations for calling rewards"
   ├─ Router.sol — "Naive router implementation. Routes for each Reward Token -> Underlying need to be hardcoded upon deployment"
   ├─ Lever.sol — "Simple router inheritor to expose swapping functionality"
   └─ integrations
      ├─ aaveVault.sol - "Adds additional functionality to claim rewards from AAVE Incentive controller. Also takes a cut from underlying yield"
      ├─ compVault.sol - "Adds additional functionality to claim rewards from Comptroller. Also takes a cut from underlying yield"
      ├─ CRVVault.sol - "Handles depositing and withdrawing from a liquidity gauge for CRV LP tokens"
      ├─ JLPVault.sol - "Handles depositing and withdrawal into Trader Joe MasterChef strategies"
      └─ sJOEVault.sol - "Handles depositing and withdrawal into Trader Joe sJOE staking"

```

## Development

**Install Foundry**
```https://github.com/gakonst/foundry```


**Building**
```
cd contracts
forge update
forge build
```

**Testing**
```
cd contracts
forge test --fork-url="https://api.avax.network/ext/bc/C/rpc" --fork-block-number=12435550
```

To run anchor tests
```
forge test --fork-url="https://api.avax.network/ext/bc/C/rpc" --fork-block-number=14318158 --match-contract=aUST
```

## License

[AGPL-3.0-only]

## Disclaimer

_These smart contracts are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of the user interface or the smart contracts. They have not been audited and as such there can be no assurance they will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk._

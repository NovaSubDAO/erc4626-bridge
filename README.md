# erc4626-bridge

## development

run the following command to install git hooks to your local repo:
```bash
./setup.sh
```

## tests
```bash
source .env
forge test --rpc-url $SEPOLIA_RPC_URL -vvv
```
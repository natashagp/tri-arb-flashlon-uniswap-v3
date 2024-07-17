# Flashloan with Triangular Arbitrage in Uniswap V3

### Step 1

```shell
git clone https://github.com/natashagp/tri-arb-flashlon-uniswap-v3.git
```

### Step 2

Change to directory tri-arb-flashlon-uniswap-v3

```shell
cd tri-arb-flashlon-uniswap-v3
```

### Step 3

Install packages as a clean install. This is important to ensure that your versions are exactly the same as in this project.
```shell
npm ci
```

### Step 3

Configure your own ```.env``` file, as shown in the ```.env.example``` file.
Create a ```.env``` file and add your ```ETHEREUM_RPC_URL```, ```ETHEREUM_TESTNET_RPC_URL``` and ```WALLET_PRIVATE_KEY``` to be able to run this project.
To create your ```ETHEREUM_RPC_URL``` and ```ETHEREUM_TESTNET_RPC_URL``` you can use [Alchemy](https://www.alchemy.com/) or [Infura](https://www.infura.io/).
You ```WALLET_PRIVATE_KEY``` can be found in your Metamask Wallet.

### Step 4
```shell
npx hardhat test
```
You will likely see a "Arbitrage not profitable" error come up, if the arbitrage is not profitable. This is the most common result and in fact means the code is working.

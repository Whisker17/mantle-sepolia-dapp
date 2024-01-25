#!/bin/bash

source .env
source "$(dirname "$0")/utils/deploy.sh"
source "$(dirname "$0")/utils/utils.sh"

# 1. deploy ERC20 token

echo -e "=================== Start deploy erc-20 tokens ==================="

deploy_erc20 "DexTestA" "DTA" 1000
DTA=$deployed_to

deploy_erc20 "DexTestB" "DTB" 1000
DTB=$deployed_to

echo -e "\n=================== Start deploy simpleSwap ==================="

# 2. deploy simpleSwap contract
resultSS=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
    --constructor-args $DTA $DTB \
    --private-key $ACCOUNT_PRIVATE_KEY \
    src/simpleSwap/simpleSwap.sol:SimpleSwap)

simpleSwap=$(echo "$resultSS" | grep "Deployed to" | awk '{print $NF}')
echo -e "SimpleSwap Deployed to: $simpleSwap"

# 3. approve tokens to simpleSwap contract

echo -e "\n=================== Start approve tokens to simpleSwap ==================="

cast send $DTA "approve(address,uint256)" $simpleSwap 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC
cast send $DTB "approve(address,uint256)" $simpleSwap 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 4. add liquidity to simpleSwap contract

echo -e "\n=================== Start add liquidity to simpleSwap ==================="

cast send $simpleSwap "addLiquidity(uint256,uint256)" 100 100 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# check balance and reserve

echo -e "\n=================== Check balance of simpleSwap contract ==================="

result=$(cast call $simpleSwap "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result" 100 "User"

cast send $simpleSwap "swap(uint,address,uint)" 100 $DTA 30 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

echo -e "\n=================== Check reserve of two swaped tokenss ==================="

result0=$(cast call $simpleSwap "reserve0()" --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result0" 200 "Reserve0"

result1=$(cast call $simpleSwap "reserve1()" --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result1" 50 "Reserve1"

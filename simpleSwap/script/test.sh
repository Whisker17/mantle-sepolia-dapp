#!/bin/bash

# 从.env文件中读取环境变量
source .env

# 部署 ERC-20 合约的函数
deploy_erc20() {
    local name=$1
    local symbol=$2
    local initialSupply=$3

    result=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
                          --constructor-args "$name" "$symbol" $initialSupply \
                          --private-key $ACCOUNT_PRIVATE_KEY \
                          src/erc-20.sol:MyCustomToken)

    deployed_to=$(echo "$result" | grep "Deployed to" | awk '{print $NF}')
    echo "$name Deployed to: $deployed_to"
}

# 部署 DTA 和 DTB 合约
deploy_erc20 "DexTestA" "DTA" 1000
DTA=$deployed_to

deploy_erc20 "DexTestB" "DTB" 1000
DTB=$deployed_to

# 部署 simpleSwap 合约
resultSS=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
    --constructor-args $DTA $DTB \
    --private-key $ACCOUNT_PRIVATE_KEY \
    src/simpleSwap.sol:SimpleSwap)

simpleSwap=$(echo "$resultSS" | grep "Deployed to" | awk '{print $NF}')
echo "SimpleSwap Deployed to: $simpleSwap"

# 3. approve tokens to simpleSwap contract

cast send $DTA "approve(address,uint256)" $simpleSwap 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC
cast send $DTB "approve(address,uint256)" $simpleSwap 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 4. add liquidity to simpleSwap contract

cast send $simpleSwap "addLiquidity(uint256,uint256)" 100 100 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 最后一段检查余额和储备量的逻辑
check_balance() {
    local result=$1
    local expected_balance=$2
    local token_name=$3

    hex_balance=$(echo $result | awk '{print $NF}')
    decimal_balance=$(echo "ibase=16; $hex_balance" | bc)

    if [ "$decimal_balance" -ne "$expected_balance" ]; then
        echo "Error: $token_name Balance is not equal to $expected_balance"
    else
        echo "$token_name Balance is equal to $expected_balance"
    fi
}

# 检查余额
result=$(cast call $simpleSwap "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result" 100 "User"

cast send $simpleSwap "swap(uint,address,uint)" 100 $DTA 30 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 检查储备量
result0=$(cast call $simpleSwap "reserve0()" --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result0" 200 "Reserve0"

result1=$(cast call $simpleSwap "reserve1()" --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result1" 50 "Reserve1"

#!/bin/bash

source .env
source "$(dirname "$0")/utils/deploy.sh"
source "$(dirname "$0")/utils/utils.sh"

# 1. deploy ERC20 token

echo -e "=================== Start deploy erc-20 tokens ==================="

deploy_erc20 "LendTestA" "LTA" 10000
LTA=$deployed_to

# 2. deploy simpleLending contract

echo -e "\n=================== Start deploy simpleLending ==================="

resultSS=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
    --private-key $ACCOUNT_PRIVATE_KEY \
    src/lending/simpleLending.sol:Lending)

simpleLending=$(echo "$resultSS" | grep "Deployed to" | awk '{print $NF}')
echo -e "simpleLending Deployed to: $simpleLending"

# 3. approve tokens to simpleLending contract

echo -e "\n=================== Start approve tokens to simpleLending ==================="

cast send $LTA "approve(address,uint256)" $simpleLending 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC
cast send $LTA "approve(address,uint256)" $simpleLending 1000 --private-key $ACCOUNT_PRIVATE_KEY_2 --rpc-url $MANTLE_SEPOLIA_RPC

# 4. deposit erc-20 tokens to lending contract

echo -e "\n=================== Start deposit erc-20 tokens to lending contract ==================="

cast send $simpleLending "deposit(address,uint256)" $LTA 1000 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $LTA "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "LTA Balance for depositor: $result"
check_balance "$result" 9000 "User"

result=$(cast call $simpleLending "s_accountToTokenDeposits(address,address)" $ACCOUNT_ADDRESS $LTA --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "s_accountToTokenDeposits: $result"
check_balance "$result" 1000 "LTA"

# 5. withdraw erc-20 tokens from lending contract

echo -e "\n=================== Start withdraw erc-20 tokens from lending contract ==================="

cast send $simpleLending "withdraw(address,uint256)" $LTA 100 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $LTA "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "LTA Balance for depositor: $result"
check_balance "$result" 9100 "User"

result=$(cast call $simpleLending "s_accountToTokenDeposits(address,address)" $ACCOUNT_ADDRESS $LTA --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "s_accountToTokenDeposits: $result"
check_balance "$result" 900 "LTA"

# 6. borrow erc-20 tokens from lending contract

echo -e "\n=================== Start borrow erc-20 tokens from lending contract ==================="

cast send $simpleLending "borrow(address,uint256)" $LTA 200 --private-key $ACCOUNT_PRIVATE_KEY_2 --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $simpleLending "s_accountToTokenBorrows(address,address)" $ACCOUNT_ADDRESS_2 $LTA --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "s_accountToTokenBorrows: $result"
check_balance "$result" 200 "LTA"

result=$(cast call $LTA "balanceOf(address)" $ACCOUNT_ADDRESS_2 --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "LTA Balance for depositor: $result"
check_balance "$result" 200 "LTA"

# 7. repay erc-20 tokens from lending contract

echo -e "\n=================== Start repay erc-20 tokens from lending contract ==================="

cast send $simpleLending "repay(address,uint256)" $LTA 200 --private-key $ACCOUNT_PRIVATE_KEY_2 --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $LTA "balanceOf(address)" $ACCOUNT_ADDRESS_2 --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "LTA Balance for depositor: $result"
check_balance "$result" 0 "LTA"

result=$(cast call $simpleLending "s_accountToTokenBorrows(address,address)" $ACCOUNT_ADDRESS_2 $LTA --rpc-url $MANTLE_SEPOLIA_RPC)
echo -e "s_accountToTokenBorrows: $result"
check_balance "$result" 0 "LTA"

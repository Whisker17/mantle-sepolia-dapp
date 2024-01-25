#!/bin/bash

source .env
source "$(dirname "$0")/utils/deploy.sh"
source "$(dirname "$0")/utils/utils.sh"

# 1. deploy ERC721 token

echo -e "=================== Start deploy NFT ==================="

deploy_nft "NFTTestA" "NTA"
NTA=$deployed_to

# 2. mint tokens to your address

echo -e "\n=================== Start mint tokens to your address ==================="

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 3. Test your address NFT balance

echo -e "\n=================== Start test your address NFT balance ==================="

result=$(cast call $NTA "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result" 1 "NTA"

echo -e "\n=================== Start test if the address is matched ==================="

result=$(cast call $NTA "ownerOf(uint256)" 0 --rpc-url $MANTLE_SEPOLIA_RPC)
check_address "$result" $ACCOUNT_ADDRESS

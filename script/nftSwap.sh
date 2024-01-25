#!/bin/bash

source .env
source "$(dirname "$0")/utils/deploy.sh"
source "$(dirname "$0")/utils/utils.sh"

# 1. deploy ERC721 token

echo -e "\n=================== Start deploy NFT ==================="

deploy_nft "NFTTestA" "NTA"
NTA=$deployed_to

# 2. mint tokens to your address

echo -e "\n=================== Start mint tokens to your address ==================="

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 1 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 3. Test your address NFT balance

echo -e "\n=================== Start test your address NFT balance ==================="

result=$(cast call $NTA "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result" 2 "NTA"

echo -e "\n=================== Start test if the address is matched ==================="

result=$(cast call $NTA "ownerOf(uint256)" 0 --rpc-url $MANTLE_SEPOLIA_RPC)
check_address "$result" $ACCOUNT_ADDRESS

# 4. deploy nftSwap dapp

deploy_nftSwap() {
  result=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
                        --private-key $ACCOUNT_PRIVATE_KEY \
                        src/nftSwap/nftSwap.sol:NFTSwap)

  deployed_to=$(echo "$result" | grep "Deployed to" | awk '{print $NF}')
  echo "NFT Swap Deployed to: $deployed_to"
}

echo -e "\n=================== Start deploy nftSwap contract ==================="

deploy_nftSwap
nftSwap=$deployed_to

# 5. approve your nft to nftSwap contract

echo -e "\n=================== Start approve your nft to nftSwap contract ==================="

cast send $NTA "approve(address,uint256)" $nftSwap 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC
cast send $NTA "approve(address,uint256)" $nftSwap 1 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 6. list your nfts

echo -e "\n=================== Start list your nfts ==================="

cast send $nftSwap "list(address,uint256,uint256)" $NTA 0 1 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC
cast send $nftSwap "list(address,uint256,uint256)" $NTA 1 1 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 7. check your listed nfts

echo -e "\n=================== Start check your listed nfts ==================="

result=$(cast call $nftSwap "nftList(address,uint256)" $NTA 0 --rpc-url $MANTLE_SEPOLIA_RPC)

check_address_and_price "$result" $ACCOUNT_ADDRESS 1

# 8. update nft price

echo -e "\n=================== Start update nft price ==================="

cast send $nftSwap "update(address,uint256,uint256)" $NTA 0 2 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $nftSwap "nftList(address,uint256)" $NTA 0 --rpc-url $MANTLE_SEPOLIA_RPC)

check_address_and_price "$result" $ACCOUNT_ADDRESS 2

# 9. revoke your NFT

echo -e "\n=================== Start revoke your NFT ==================="

cast send $nftSwap "revoke(address,uint256)" $NTA 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

result=$(cast call $nftSwap "nftList(address,uint256)" $NTA 0 --rpc-url $MANTLE_SEPOLIA_RPC)

check_balance "$result" 0 "NTA #0"

# 10. buy your nft
echo -e "\n=================== Start buy your NFT ==================="

cast send $nftSwap "purchase(address,uint256)" $NTA 1 --private-key $ACCOUNT_PRIVATE_KEY_2 --rpc-url $MANTLE_SEPOLIA_RPC --value 1

result=$(cast call $NTA "ownerOf(uint256)" 1 --rpc-url $MANTLE_SEPOLIA_RPC)
check_address "$result" $ACCOUNT_ADDRESS_2

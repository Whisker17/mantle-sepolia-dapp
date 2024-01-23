#!/bin/bash

source .env

# 1. deploy ERC721 token

deploy_nft() {
    local name=$1
    local symbol=$2

    result=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
                          --constructor-args "$name" "$symbol" \
                          --private-key $ACCOUNT_PRIVATE_KEY \
                          src/nft/myNFT.sol:myNFT)

    deployed_to=$(echo "$result" | grep "Deployed to" | awk '{print $NF}')
    echo "$name Deployed to: $deployed_to"
}

echo -e "\n=================== Start deploy NFT ==================="

deploy_nft "NFTTestA" "NTA"
NTA=$deployed_to

# 2. mint tokens to your address

echo -e "\n=================== Start mint tokens to your address ==================="

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 1 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

# 3. Test your address NFT balance

echo -e "\n=================== Start test your address NFT balance ==================="

check_balance() {
    local result=$1
    local expected_balance=$2
    local token_name=$3

    hex_balance=$(echo $result | awk '{print $NF}')
    decimal_balance=$(printf "%d" $hex_balance)

    if [ "$decimal_balance" -ne "$expected_balance" ]; then
        echo "Error: $token_name Balance is not equal to $expected_balance"
    else
        echo "$token_name Balance is equal to $expected_balance"
    fi
}

result=$(cast call $NTA "balanceOf(address)" $ACCOUNT_ADDRESS --rpc-url $MANTLE_SEPOLIA_RPC)
check_balance "$result" 2 "NTA"

echo -e "\n=================== Start test if the address is matched ==================="

check_address() {
    normalized_address=$(echo "$1" | sed 's/^0x//;s/^0*//;s/[a-fA-F]/\L&/g')

    normalized_address1="0x$(echo $normalized_address | tr 'a-f' 'A-F')"

    normalized_address=$(echo "$2" | sed 's/^0x//;s/^0*//;s/[a-fA-F]/\L&/g')

    normalized_address2="0x$(echo $normalized_address | tr 'a-f' 'A-F')"


    if [ "$normalized_address1" = "$normalized_address2" ]; then
        echo "The address is matched！"
    else
        echo "The address is not matched。"
    fi
}

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

check_address_and_price() {
    local input_address=$1
    local expected_address=$2
    local expected_price=$3

    address=$(echo "$input_address" | sed 's/^0x//')

    len=${#address}
    mid=$((len / 2))

    address_part1=${address:0:mid}
    address_part2=${address:mid}

    address_part1="0x$address_part1"
    address_part2="0x$address_part2"

    echo "address: $address_part1"
    echo "price: $address_part2"

    check_address "$address_part1" $expected_address
    check_balance "$address_part2" $expected_price "NTA"
}

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

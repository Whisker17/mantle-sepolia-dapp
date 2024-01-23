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

echo -e "=================== Start deploy NFT ==================="

deploy_nft "NFTTestA" "NTA"
NTA=$deployed_to

# 2. mint tokens to your address

echo -e "\n=================== Start mint tokens to your address ==================="

cast send $NTA "mint(address,uint256)" $ACCOUNT_ADDRESS 0 --private-key $ACCOUNT_PRIVATE_KEY --rpc-url $MANTLE_SEPOLIA_RPC

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
check_balance "$result" 1 "NTA"

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

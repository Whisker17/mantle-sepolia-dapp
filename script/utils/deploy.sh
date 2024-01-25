deploy_erc20() {
    local name=$1
    local symbol=$2
    local initialSupply=$3

    result=$(forge create --rpc-url $MANTLE_SEPOLIA_RPC \
                          --constructor-args "$name" "$symbol" $initialSupply \
                          --private-key $ACCOUNT_PRIVATE_KEY \
                          src/simpleSwap/erc-20.sol:MyCustomToken)

    deployed_to=$(echo "$result" | grep "Deployed to" | awk '{print $NF}')
    echo "$name Deployed to: $deployed_to"
}

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

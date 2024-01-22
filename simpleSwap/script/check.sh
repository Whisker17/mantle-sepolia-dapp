check_balance() {
    local result=$1
    local expected_balance=$2
    local token_name=$3

    echo "result: $result"
    echo "expected_balance: $expected_balance"
    echo "token_name: $token_name"
    hex_balance=$(echo $result | awk '{print $NF}')
    echo "hex_balance: $hex_balance"
    decimal_balance=$(printf "%d" $hex_balance)
    echo "decimal_balance: $decimal_balance"

    if [ "$decimal_balance" -ne "$expected_balance" ]; then
        echo "Error: $token_name Balance is not equal to $expected_balance"
    else
        echo "$token_name Balance is equal to $expected_balance"
    fi
}

result0=$(cast call 0x43EAcFb02026E6a324Ff0e059a8dD096742CA450 "reserve0()" --rpc-url "https://rpc.sepolia.mantle.xyz")
check_balance "$result0" 200 "Reserve0"

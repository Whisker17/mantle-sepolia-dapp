# check balance and reserve
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

# check address
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

# check address and price
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

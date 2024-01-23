check_address() {
    normalized_address=$(echo "$1" | sed 's/^0x//;s/^0*//;s/[a-fA-F]/\L&/g')

    normalized_address1="0x$(echo $normalized_address | tr 'a-f' 'A-F')"

    normalized_address=$(echo "$2" | sed 's/^0x//;s/^0*//;s/[a-fA-F]/\L&/g')

    normalized_address2="0x$(echo $normalized_address | tr 'a-f' 'A-F')"


    if [ "$normalized_address1" = "$normalized_address2" ]; then
        echo "地址匹配！"
    else
        echo "地址不匹配。"
    fi
}

# 例子
result="0x000000000000000000000000e1f10afe71ff3397a85aace99d42db6661e02bb9"

check_address "$result" 0xE1F10AfE71FF3397A85aAce99D42Db6661E02bB9

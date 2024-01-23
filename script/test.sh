split_and_rename() {
    local input_address="$1"

    # 移除前置的0x
    address=$(echo "$input_address" | sed 's/^0x//')

    # 计算字符串长度
    len=${#address}

    # 计算中间位置
    mid=$((len / 2))

    # 分割字符串为两部分
    address_part1=${address:0:mid}
    address_part2=${address:mid}

    # 添加前缀0x
    address_part1="0x$address_part1"
    address_part2="0x$address_part2"

    # 输出结果
    echo "address: $address_part1"
    echo "price: $address_part2"
}

# 示例用法
result=$(split_and_rename "0x000000000000000000000000e1f10afe71ff3397a85aace99d42db6661e02bb9000000000000000000000000000000000000000000000000000000000000004d")

# 输出分割和命名后的结果
echo "$result"

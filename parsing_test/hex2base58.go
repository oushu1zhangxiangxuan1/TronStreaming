package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"math/big"
)

// ToHexAddress T ---->  41
func ToHexAddress(address string) string {
    return hex.EncodeToString(base58Decode([]byte(address)))
}

// FromHexAddress 41 ---- > T
func FromHexAddress(hexAddress string) (string, error) {
    addrByte, err := hex.DecodeString(hexAddress)
    if err != nil {
        return "", err
    }

    sha := sha256.New()
    sha.Write(addrByte)
    shaStr := sha.Sum(nil)

    sha2 := sha256.New()
    sha2.Write(shaStr)
    shaStr2 := sha2.Sum(nil)

    addrByte = append(addrByte, shaStr2[:4]...)

    return string(base58Encode(addrByte)), nil
}

var base58Alphabets = []byte("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

// base58Encode 编码
func base58Encode(input []byte) []byte {
    x := big.NewInt(0).SetBytes(input)
    base := big.NewInt(58)
    zero := big.NewInt(0)
    mod := &big.Int{}
    var result []byte
    for x.Cmp(zero) != 0 {
        x.DivMod(x, base, mod)
        result = append(result, base58Alphabets[mod.Int64()])
    }
    reverseBytes(result)
    return result
}

// base58Decode 解码
func base58Decode(input []byte) []byte {
    result := big.NewInt(0)
    for _, b := range input {
        charIndex := bytes.IndexByte(base58Alphabets, b)
        result.Mul(result, big.NewInt(58))
        result.Add(result, big.NewInt(int64(charIndex)))
    }
    decoded := result.Bytes()
    if input[0] == base58Alphabets[0] {
        decoded = append([]byte{0x00}, decoded...)
    }
    return decoded[:len(decoded)-4]
}

// reverseBytes 翻转字节
func reverseBytes(data []byte) {
    for i, j := 0, len(data)-1; i < j; i, j = i+1, j-1 {
        data[i], data[j] = data[j], data[i]
    }
}

func main() {
    // hexAddr := ToHexAddress("TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t") // 将地址转换为 hexString
    // fmt.Println("HexAddr：", hexAddr)

    // addr, _ := FromHexAddress("41e40302d6b5e889bfbd395ed884638d7f03ee3f87") // 将 hexString 转换为地址
    addr, _ := FromHexAddress("41fa07f94f6c5217d1328deb8e96d96b05d6509406") // 将 hexString 转换为地址
    fmt.Println("Addr：", addr)

	
}
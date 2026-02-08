#!/bin/bash

echo "🔐 使用后端API生成正确的hash"
echo "=========================="
echo ""

# 思路：让后端暴露一个临时端点来生成hash
# 或者，直接修改backend代码添加一个初始化脚本

echo "1️⃣ 创建临时hash生成工具..."

# 复制backend代码并在本地生成
cd /Users/kis/data/cursor_test

cat > /tmp/hash-gen.go << 'EOF'
package main

import (
	"fmt"
	"os"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: hash-gen <password>")
		return
	}
	password := os.Args[1]
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	fmt.Println(string(hash))
}
EOF

echo "2️⃣ 编译并运行hash生成器..."
docker run --rm -v /tmp:/work -w /work golang:1.21-alpine sh -c '
apk add --no-cache git > /dev/null 2>&1
go mod init hashgen 2>/dev/null
go get golang.org/x/crypto/bcrypt 2>/dev/null
go run hash-gen.go admin123
' 2>&1 | grep '^\$2'

echo ""

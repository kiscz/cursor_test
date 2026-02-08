#!/bin/bash

echo "🎬 创建示例短剧（5集）"
echo "======================"
echo ""

# 1. 登录获取token
echo "1️⃣ 管理员登录..."
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@example.com","password":"admin123"}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "❌ 登录失败"
    echo "$LOGIN_RESPONSE"
    exit 1
fi

echo "✅ 登录成功"
echo "Token: ${TOKEN:0:30}..."
echo ""

# 2. 获取分类列表
echo "2️⃣ 获取分类列表..."
CATEGORIES=$(curl -s http://localhost:9090/api/categories)
echo "$CATEGORIES" | head -c 200
echo ""

# 提取第一个分类的ID（假设是分类1）
CATEGORY_ID=$(echo "$CATEGORIES" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

if [ -z "$CATEGORY_ID" ]; then
    echo "❌ 无法找到分类，使用默认ID=1"
    CATEGORY_ID=1
else
    echo "✅ 找到分类ID: $CATEGORY_ID"
fi

echo ""

# 3. 创建短剧
echo "3️⃣ 创建短剧..."
DRAMA_DATA='{
  "title": "霸道总裁的替身新娘",
  "description": "一场意外的替身婚礼，让平凡女孩林晓雪成为了商业帝国总裁秦墨轩的新娘。本以为只是一场交易，却不料深陷情网...",
  "category_id": '$CATEGORY_ID',
  "cover_image": "https://via.placeholder.com/400x600/667eea/ffffff?text=Drama+Cover",
  "total_episodes": 5,
  "status": "ongoing",
  "is_vip": false,
  "is_featured": true,
  "view_count": 0,
  "tags": ["都市", "霸总", "甜宠"]
}'

DRAMA_RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/dramas \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$DRAMA_DATA")

DRAMA_ID=$(echo "$DRAMA_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')

if [ -z "$DRAMA_ID" ]; then
    echo "❌ 创建短剧失败"
    echo "$DRAMA_RESPONSE"
    exit 1
fi

echo "✅ 短剧创建成功！ID: $DRAMA_ID"
echo ""

# 4. 创建5集
echo "4️⃣ 创建5集..."

for EP_NUM in {1..5}; do
    echo "   创建第 $EP_NUM 集..."
    
    EPISODE_DATA='{
      "drama_id": '$DRAMA_ID',
      "episode_number": '$EP_NUM',
      "title": "第'$EP_NUM'集",
      "duration": 180,
      "video_url": "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4",
      "thumbnail": "https://via.placeholder.com/640x360/667eea/ffffff?text=Episode+'$EP_NUM'",
      "is_free": '$([ $EP_NUM -le 2 ] && echo "true" || echo "false")',
      "status": "published"
    }'
    
    EP_RESPONSE=$(curl -s -X POST http://localhost:9090/api/admin/episodes \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$EPISODE_DATA")
    
    EP_ID=$(echo "$EP_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | grep -o '[0-9]*')
    
    if [ -z "$EP_ID" ]; then
        echo "   ❌ 第 $EP_NUM 集创建失败"
        echo "   $EP_RESPONSE"
    else
        FREE_STATUS=$([ $EP_NUM -le 2 ] && echo "免费" || echo "VIP")
        echo "   ✅ 第 $EP_NUM 集创建成功 (ID: $EP_ID) - $FREE_STATUS"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "短剧信息:"
echo "  ID: $DRAMA_ID"
echo "  标题: 霸道总裁的替身新娘"
echo "  分类: $CATEGORY_ID"
echo "  总集数: 5集"
echo "  前2集免费，后3集需要VIP"
echo ""
echo "查看:"
echo "  前端: http://localhost:3000/drama/$DRAMA_ID"
echo "  管理后台: http://localhost:3001"
echo ""

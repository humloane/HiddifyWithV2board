# V2Board API 完整文档

## 基本信息

- **基础URL**: `http://your-domain.com/api/v1`
- **认证方式**: Bearer Token (通过 `Authorization` 头部传递)
- **数据格式**: JSON
- **请求方法**: GET, POST
- **响应格式**: JSON

## 1. 认证相关 API (Passport)

### 1.1 用户注册
```
POST /api/v1/passport/auth/register
```

**请求参数:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "invite_code": "ABC123", // 可选
  "email_code": "123456", // 邮箱验证码
  "recaptcha_data": "recaptcha_token" // reCAPTCHA验证
}
```

**响应:**
```json
{
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "auth_data": "encoded_user_data"
  }
}
```

### 1.2 用户登录
```
POST /api/v1/passport/auth/login
```

**请求参数:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**响应:**
```json
{
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
    "auth_data": "encoded_user_data"
  }
}
```

### 1.3 忘记密码
```
POST /api/v1/passport/auth/forget
```

**请求参数:**
```json
{
  "email": "user@example.com"
}
```

### 1.4 发送邮箱验证码
```
POST /api/v1/passport/comm/sendEmailVerify
```

**请求参数:**
```json
{
  "email": "user@example.com"
}
```

## 2. 用户信息 API

### 2.1 获取用户信息
```
GET /api/v1/user/info
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": {
    "email": "user@example.com",
    "transfer_enable": 107374182400, // 总流量（字节）
    "device_limit": 3, // 设备限制
    "last_login_at": 1640995200, // 最后登录时间
    "created_at": 1640995200, // 创建时间
    "banned": 0, // 是否被封禁
    "auto_renewal": 1, // 是否自动续费
    "plan_id": 1, // 套餐ID
    "expired_at": 1672531200, // 过期时间
    "u": 1073741824, // 已上传流量
    "d": 2147483648, // 已下载流量
    "balance": 10.50, // 余额
    "commission_balance": 5.25, // 佣金余额
    "invite_user_id": 123 // 邀请人ID
  }
}
```

### 2.2 获取用户统计
```
GET /api/v1/user/getStat
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    2, // 待处理订单数
    1, // 待处理工单数
    5  // 邀请用户数
  ]
}
```

### 2.3 获取订阅信息
```
GET /api/v1/user/getSubscribe
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": {
    "plan_id": 1,
    "token": "user_token_string",
    "expired_at": 1672531200,
    "u": 1073741824,
    "d": 2147483648,
    "transfer_enable": 107374182400,
    "device_limit": 3,
    "alive_ip": 2, // 在线设备数
    "subscribe_url": "https://your-domain.com/api/v1/client/subscribe?token=xxx",
    "reset_day": 1 // 重置日期
  }
}
```

### 2.4 重置订阅链接
```
GET /api/v1/user/resetSecurity
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": "https://your-domain.com/api/v1/client/subscribe?token=new_token"
}
```

## 3. 订单相关 API

### 3.1 创建订单
```
POST /api/v1/user/order/save
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "plan_id": 1,
  "period": "month", // month, quarter, half_year, year
  "coupon_code": "DISCOUNT20" // 可选
}
```

**响应:**
```json
{
  "data": "order_trade_no_string"
}
```

### 3.2 订单结算
```
POST /api/v1/user/order/checkout
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "trade_no": "order_trade_no_string",
  "method": 1 // 支付方式ID
}
```

### 3.3 获取订单列表
```
GET /api/v1/user/order/fetch
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    {
      "id": 1,
      "trade_no": "20231201123456",
      "plan_id": 1,
      "period": "month",
      "total_amount": 10.00,
      "status": 1, // 0:待支付 1:已支付 2:已取消
      "created_at": 1640995200
    }
  ]
}
```

### 3.4 获取支付方式
```
GET /api/v1/user/order/getPaymentMethod
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "支付宝",
      "payment": "alipay",
      "icon": "alipay.png"
    },
    {
      "id": 2,
      "name": "微信支付",
      "payment": "wechat",
      "icon": "wechat.png"
    }
  ]
}
```

## 4. 套餐相关 API

### 4.1 获取套餐列表
```
GET /api/v1/user/plan/fetch
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "基础套餐",
      "content": "月付套餐，100GB流量",
      "transfer_enable": 107374182400,
      "device_limit": 3,
      "speed_limit": 0,
      "month_price": 10.00,
      "quarter_price": 27.00,
      "half_year_price": 48.00,
      "year_price": 96.00,
      "two_year_price": 180.00,
      "three_year_price": 252.00,
      "onetime_price": null,
      "reset_price": null
    }
  ]
}
```

## 5. 服务器相关 API

### 5.1 获取服务器列表
```
GET /api/v1/user/server/fetch
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    {
      "id": 1,
      "name": "香港节点1",
      "type": "shadowsocks",
      "rate": 1.0,
      "host": "hk1.example.com",
      "port": 443,
      "server_port": 8080,
      "cipher": "aes-256-gcm",
      "created_at": 1640995200,
      "last_check_at": 1640995200,
      "parent_id": null,
      "tags": ["香港", "高速"]
    }
  ]
}
```

## 6. 邀请相关 API

### 6.1 生成邀请码
```
GET /api/v1/user/invite/save
Headers: Authorization: Bearer {token}
```

### 6.2 获取邀请列表
```
GET /api/v1/user/invite/fetch
Headers: Authorization: Bearer {token}
```

### 6.3 获取邀请详情
```
GET /api/v1/user/invite/details
Headers: Authorization: Bearer {token}
```

## 7. 工单相关 API

### 7.1 创建工单
```
POST /api/v1/user/ticket/save
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "subject": "工单标题",
  "level": 0, // 优先级: 0低 1中 2高
  "message": "工单内容"
}
```

### 7.2 获取工单列表
```
GET /api/v1/user/ticket/fetch
Headers: Authorization: Bearer {token}
```

### 7.3 回复工单
```
POST /api/v1/user/ticket/reply
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "id": 1,
  "message": "回复内容"
}
```

### 7.4 关闭工单
```
POST /api/v1/user/ticket/close
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "id": 1
}
```

## 8. 客户端订阅 API

### 8.1 获取订阅配置
```
GET /api/v1/client/subscribe?token={user_token}
```

**响应:** 返回订阅配置文件（Clash、V2Ray等格式）

## 9. 通用配置 API

### 9.1 获取系统配置
```
GET /api/v1/user/comm/config
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": {
    "is_email_verify": true,
    "is_invite_force": false,
    "email_whitelist_suffix": [".edu", ".gov"],
    "is_recaptcha": true,
    "recaptcha_site_key": "site_key",
    "app_description": "高速稳定的代理服务",
    "app_url": "https://example.com"
  }
}
```

## 10. 优惠券相关 API

### 10.1 验证优惠券
```
POST /api/v1/user/coupon/check
Headers: Authorization: Bearer {token}
```

**请求参数:**
```json
{
  "code": "DISCOUNT20",
  "plan_id": 1,
  "period": "month"
}
```

## 11. 流量统计 API

### 11.1 获取流量日志
```
GET /api/v1/user/stat/getTrafficLog
Headers: Authorization: Bearer {token}
```

**响应:**
```json
{
  "data": [
    {
      "date": "2023-12-01",
      "u": 1073741824,
      "d": 2147483648,
      "total": 3221225472
    }
  ]
}
```

## 错误响应格式

```json
{
  "message": "错误信息",
  "errors": {
    "field_name": ["具体错误描述"]
  }
}
```

## HTTP 状态码

- `200` - 成功
- `400` - 请求参数错误
- `401` - 未授权/Token无效
- `403` - 禁止访问
- `404` - 资源不存在
- `422` - 验证失败
- `500` - 服务器内部错误

## 使用示例

### Dart/Flutter示例

```dart
class V2BoardAPI {
  static const String baseUrl = 'https://your-domain.com/api/v1';
  
  // 用户登录
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/passport/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    return json.decode(response.body);
  }
  
  // 获取用户信息
  static Future<Map<String, dynamic>> getUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/info'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return json.decode(response.body);
  }
  
  // 获取订阅信息
  static Future<Map<String, dynamic>> getSubscription(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/getSubscribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return json.decode(response.body);
  }
  
  // 获取订阅配置
  static Future<String> getSubscriptionConfig(String userToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/client/subscribe?token=$userToken'),
    );
    return response.body;
  }
}
```

这个API文档涵盖了v2board的所有主要接口，可以用于HiddifyWithPanels的面板集成功能。

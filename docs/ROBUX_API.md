# Robux API Documentation

## Overview

The Robux system is a comprehensive cryptocurrency and virtual currency management system designed for the Tweetapus platform. This API enables users to manage Robux balances, perform transactions, and interact with the virtual economy.

## Base URL

```
/api/v1/robux
```

## Authentication

All API endpoints require authentication via JWT token. Include the token in the Authorization header:

```
Authorization: Bearer <JWT_TOKEN>
```

## Endpoints

### Balance Management

#### Get User Balance
Retrieve the current Robux balance for an authenticated user.

```
GET /api/v1/robux/balance
```

**Request Headers:**
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "userId": "user_id_123",
  "balance": 5000,
  "currency": "ROBUX",
  "lastUpdated": "2025-12-23T14:27:24Z"
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or missing authentication token
- `404 Not Found`: User not found

---

#### Update Balance
Add or deduct Robux from a user's account (admin only).

```
POST /api/v1/robux/balance/update
```

**Request Body:**
```json
{
  "userId": "user_id_123",
  "amount": 1000,
  "operation": "add|subtract",
  "reason": "Daily reward|Purchase|Refund|etc",
  "transactionId": "txn_unique_id"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "userId": "user_id_123",
  "previousBalance": 5000,
  "newBalance": 6000,
  "transactionId": "txn_unique_id",
  "timestamp": "2025-12-23T14:27:24Z"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid amount or operation
- `401 Unauthorized`: Admin access required
- `409 Conflict`: Insufficient balance for subtract operation

---

### Transactions

#### Get Transaction History
Retrieve transaction history for an authenticated user.

```
GET /api/v1/robux/transactions?limit=50&offset=0
```

**Query Parameters:**
- `limit` (optional): Number of transactions to return (default: 50, max: 100)
- `offset` (optional): Pagination offset (default: 0)
- `startDate` (optional): Filter by start date (ISO 8601 format)
- `endDate` (optional): Filter by end date (ISO 8601 format)
- `type` (optional): Filter by transaction type (add, subtract, purchase, reward)

**Response (200 OK):**
```json
{
  "userId": "user_id_123",
  "transactions": [
    {
      "transactionId": "txn_001",
      "amount": 500,
      "type": "purchase",
      "reason": "Item purchase",
      "balance": 4500,
      "timestamp": "2025-12-23T10:00:00Z"
    },
    {
      "transactionId": "txn_002",
      "amount": 1000,
      "type": "reward",
      "reason": "Daily login bonus",
      "balance": 5500,
      "timestamp": "2025-12-22T23:00:00Z"
    }
  ],
  "total": 2,
  "limit": 50,
  "offset": 0
}
```

**Error Responses:**
- `401 Unauthorized`: Authentication required
- `404 Not Found`: User not found

---

#### Get Transaction Details
Retrieve details for a specific transaction.

```
GET /api/v1/robux/transactions/{transactionId}
```

**Path Parameters:**
- `transactionId` (required): The unique transaction identifier

**Response (200 OK):**
```json
{
  "transactionId": "txn_001",
  "userId": "user_id_123",
  "amount": 500,
  "type": "purchase",
  "reason": "Item purchase",
  "previousBalance": 5000,
  "newBalance": 4500,
  "metadata": {
    "itemId": "item_456",
    "itemName": "Premium Avatar"
  },
  "status": "completed",
  "timestamp": "2025-12-23T10:00:00Z"
}
```

**Error Responses:**
- `404 Not Found`: Transaction not found
- `401 Unauthorized`: User not authorized to view transaction

---

### Purchases

#### Initiate Purchase
Initiate a purchase transaction using Robux.

```
POST /api/v1/robux/purchase
```

**Request Body:**
```json
{
  "itemId": "item_456",
  "quantity": 1,
  "price": 500,
  "currency": "ROBUX"
}
```

**Response (201 Created):**
```json
{
  "purchaseId": "purchase_789",
  "transactionId": "txn_003",
  "itemId": "item_456",
  "quantity": 1,
  "amount": 500,
  "status": "completed",
  "newBalance": 4500,
  "timestamp": "2025-12-23T14:27:24Z"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid item or quantity
- `402 Payment Required`: Insufficient balance
- `404 Not Found`: Item not found

---

#### Refund Purchase
Request a refund for a previous purchase.

```
POST /api/v1/robux/refund
```

**Request Body:**
```json
{
  "purchaseId": "purchase_789",
  "reason": "Item not as expected"
}
```

**Response (200 OK):**
```json
{
  "refundId": "refund_001",
  "purchaseId": "purchase_789",
  "transactionId": "txn_004",
  "amount": 500,
  "status": "processed",
  "newBalance": 5000,
  "timestamp": "2025-12-23T14:27:24Z"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid purchase or refund reason
- `404 Not Found`: Purchase not found
- `409 Conflict`: Purchase cannot be refunded (already refunded or outside refund window)

---

### Rewards

#### Claim Daily Reward
Claim the daily Robux reward.

```
POST /api/v1/robux/rewards/daily
```

**Response (200 OK):**
```json
{
  "rewardId": "reward_123",
  "transactionId": "txn_005",
  "amount": 100,
  "type": "daily_login",
  "newBalance": 5100,
  "nextClaimTime": "2025-12-24T14:27:24Z",
  "timestamp": "2025-12-23T14:27:24Z"
}
```

**Error Responses:**
- `429 Too Many Requests`: Daily reward already claimed
- `401 Unauthorized`: Authentication required

---

#### Get Reward Status
Check the current reward status and claim eligibility.

```
GET /api/v1/robux/rewards/status
```

**Response (200 OK):**
```json
{
  "dailyRewardAvailable": true,
  "lastDailyClaimTime": "2025-12-22T14:27:24Z",
  "nextClaimTime": "2025-12-24T14:27:24Z",
  "streakDays": 5,
  "streakBonus": 50,
  "totalRewardsEarned": 1500
}
```

---

### Leaderboard

#### Get Leaderboard
Retrieve the top Robux holders leaderboard.

```
GET /api/v1/robux/leaderboard?limit=100&period=all_time
```

**Query Parameters:**
- `limit` (optional): Number of entries to return (default: 100, max: 1000)
- `period` (optional): Time period for ranking (all_time, monthly, weekly, daily)

**Response (200 OK):**
```json
{
  "period": "all_time",
  "generatedAt": "2025-12-23T14:27:24Z",
  "leaderboard": [
    {
      "rank": 1,
      "userId": "user_001",
      "username": "RobuxKing",
      "balance": 50000,
      "totalEarned": 100000
    },
    {
      "rank": 2,
      "userId": "user_002",
      "username": "CryptoQueen",
      "balance": 45000,
      "totalEarned": 95000
    }
  ],
  "total": 10000
}
```

---

#### Get User Leaderboard Rank
Retrieve a specific user's ranking position.

```
GET /api/v1/robux/leaderboard/rank/{userId}?period=all_time
```

**Path Parameters:**
- `userId` (required): The user's unique identifier

**Response (200 OK):**
```json
{
  "userId": "user_id_123",
  "username": "player_name",
  "rank": 45,
  "balance": 12500,
  "percentile": 99.5,
  "period": "all_time"
}
```

---

## Error Handling

All errors follow a consistent format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": {
      "field": "Specific field that caused the error (if applicable)",
      "expectedFormat": "Description of expected format"
    },
    "timestamp": "2025-12-23T14:27:24Z",
    "requestId": "req_unique_id"
  }
}
```

### Common Error Codes

- `INVALID_REQUEST`: Request format is invalid
- `UNAUTHORIZED`: Authentication required or insufficient permissions
- `FORBIDDEN`: User does not have access to requested resource
- `NOT_FOUND`: Resource not found
- `CONFLICT`: Request conflicts with current state
- `RATE_LIMITED`: Too many requests
- `INTERNAL_ERROR`: Server error

---

## Rate Limiting

The API implements rate limiting to ensure fair usage:

- **Standard Users**: 100 requests per minute
- **Premium Users**: 500 requests per minute
- **Admin Users**: 5000 requests per minute

Rate limit information is included in response headers:

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1703340444
```

---

## Data Types

### Robux Amount
All Robux amounts are represented as integers representing the smallest unit (1 Robux).

### Timestamps
All timestamps use ISO 8601 format with UTC timezone (e.g., `2025-12-23T14:27:24Z`).

### User ID
User IDs are unique string identifiers assigned at account creation.

---

## Webhook Events

The Robux system can emit webhook events for real-time transaction monitoring:

- `robux.balance.updated`: User's balance has changed
- `robux.transaction.completed`: Transaction completed
- `robux.purchase.completed`: Purchase transaction completed
- `robux.refund.processed`: Refund processed
- `robux.reward.claimed`: Reward claimed

---

## Best Practices

1. **Always validate user input** before making API requests
2. **Implement exponential backoff** for retries on rate limiting
3. **Cache balance information** where appropriate to reduce API calls
4. **Securely store** authentication tokens
5. **Monitor webhook events** for real-time updates
6. **Use pagination** for large result sets
7. **Implement proper error handling** for all API responses

---

## Changelog

### Version 1.0.0 (2025-12-23)
- Initial API release
- Balance management endpoints
- Transaction history and details
- Purchase and refund functionality
- Daily rewards system
- Leaderboard functionality

/**
 * Robux API Implementation
 * Handles Robux currency management, transactions, and wallet operations
 * 
 * @file src/api/robux.js
 * @version 1.0.0
 * @created 2025-12-23
 */

const axios = require('axios');
const { EventEmitter } = require('events');

/**
 * RobuxAPI Class
 * Manages all Robux-related API operations
 */
class RobuxAPI extends EventEmitter {
  constructor(config = {}) {
    super();
    
    this.baseURL = config.baseURL || process.env.ROBUX_API_URL || 'https://api.robux.local';
    this.apiKey = config.apiKey || process.env.ROBUX_API_KEY;
    this.timeout = config.timeout || 10000;
    this.retryAttempts = config.retryAttempts || 3;
    this.retryDelay = config.retryDelay || 1000;
    
    // Initialize axios instance
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: this.timeout,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        'X-API-Version': '1.0'
      }
    });

    // Cache for user balances
    this.balanceCache = new Map();
    this.cacheExpiry = config.cacheExpiry || 300000; // 5 minutes

    this._setupInterceptors();
  }

  /**
   * Setup axios interceptors for error handling and retry logic
   * @private
   */
  _setupInterceptors() {
    this.client.interceptors.response.use(
      response => response,
      error => {
        if (error.response?.status === 429) {
          // Rate limited
          this.emit('rateLimit', { retryAfter: error.response.headers['retry-after'] });
        }
        throw error;
      }
    );
  }

  /**
   * Get user's current Robux balance
   * @param {string} userId - User ID
   * @returns {Promise<number>} User's Robux balance
   */
  async getBalance(userId) {
    try {
      // Check cache first
      const cached = this._getFromCache(userId);
      if (cached !== null) {
        return cached;
      }

      const response = await this._retryRequest(() =>
        this.client.get(`/users/${userId}/balance`)
      );

      const balance = response.data.balance;
      this._setInCache(userId, balance);

      return balance;
    } catch (error) {
      this.emit('error', { action: 'getBalance', userId, error });
      throw new Error(`Failed to get balance for user ${userId}: ${error.message}`);
    }
  }

  /**
   * Add Robux to user's account
   * @param {string} userId - User ID
   * @param {number} amount - Amount of Robux to add
   * @param {string} reason - Reason for the transaction
   * @returns {Promise<object>} Transaction details
   */
  async addRobux(userId, amount, reason = 'Manual addition') {
    try {
      if (amount <= 0) {
        throw new Error('Amount must be greater than 0');
      }

      const response = await this._retryRequest(() =>
        this.client.post(`/users/${userId}/add-robux`, {
          amount,
          reason,
          timestamp: new Date().toISOString()
        })
      );

      // Invalidate cache
      this.balanceCache.delete(userId);

      this.emit('robuxAdded', {
        userId,
        amount,
        newBalance: response.data.newBalance,
        transactionId: response.data.transactionId
      });

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'addRobux', userId, amount, error });
      throw new Error(`Failed to add Robux to user ${userId}: ${error.message}`);
    }
  }

  /**
   * Subtract Robux from user's account
   * @param {string} userId - User ID
   * @param {number} amount - Amount of Robux to subtract
   * @param {string} reason - Reason for the transaction
   * @returns {Promise<object>} Transaction details
   */
  async subtractRobux(userId, amount, reason = 'Manual subtraction') {
    try {
      if (amount <= 0) {
        throw new Error('Amount must be greater than 0');
      }

      const response = await this._retryRequest(() =>
        this.client.post(`/users/${userId}/subtract-robux`, {
          amount,
          reason,
          timestamp: new Date().toISOString()
        })
      );

      // Invalidate cache
      this.balanceCache.delete(userId);

      this.emit('robuxSubtracted', {
        userId,
        amount,
        newBalance: response.data.newBalance,
        transactionId: response.data.transactionId
      });

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'subtractRobux', userId, amount, error });
      throw new Error(`Failed to subtract Robux from user ${userId}: ${error.message}`);
    }
  }

  /**
   * Transfer Robux between users
   * @param {string} fromUserId - Source user ID
   * @param {string} toUserId - Destination user ID
   * @param {number} amount - Amount of Robux to transfer
   * @param {string} reason - Reason for transfer
   * @returns {Promise<object>} Transfer details
   */
  async transferRobux(fromUserId, toUserId, amount, reason = 'User transfer') {
    try {
      if (amount <= 0) {
        throw new Error('Amount must be greater than 0');
      }

      if (fromUserId === toUserId) {
        throw new Error('Cannot transfer to the same user');
      }

      const response = await this._retryRequest(() =>
        this.client.post('/transfer', {
          fromUserId,
          toUserId,
          amount,
          reason,
          timestamp: new Date().toISOString()
        })
      );

      // Invalidate caches
      this.balanceCache.delete(fromUserId);
      this.balanceCache.delete(toUserId);

      this.emit('robuxTransferred', {
        fromUserId,
        toUserId,
        amount,
        fromBalance: response.data.fromBalance,
        toBalance: response.data.toBalance,
        transactionId: response.data.transactionId
      });

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'transferRobux', fromUserId, toUserId, amount, error });
      throw new Error(`Failed to transfer Robux from ${fromUserId} to ${toUserId}: ${error.message}`);
    }
  }

  /**
   * Get transaction history for a user
   * @param {string} userId - User ID
   * @param {object} options - Query options
   * @param {number} options.limit - Number of transactions to retrieve
   * @param {number} options.offset - Offset for pagination
   * @returns {Promise<array>} Array of transactions
   */
  async getTransactionHistory(userId, options = {}) {
    try {
      const { limit = 50, offset = 0 } = options;

      const response = await this._retryRequest(() =>
        this.client.get(`/users/${userId}/transactions`, {
          params: { limit, offset }
        })
      );

      return response.data.transactions;
    } catch (error) {
      this.emit('error', { action: 'getTransactionHistory', userId, error });
      throw new Error(`Failed to get transaction history for user ${userId}: ${error.message}`);
    }
  }

  /**
   * Validate Robux purchase
   * @param {string} userId - User ID
   * @param {number} amount - Amount of Robux
   * @param {string} packageId - Package identifier
   * @returns {Promise<object>} Validation result
   */
  async validatePurchase(userId, amount, packageId) {
    try {
      const response = await this._retryRequest(() =>
        this.client.post('/validate-purchase', {
          userId,
          amount,
          packageId,
          timestamp: new Date().toISOString()
        })
      );

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'validatePurchase', userId, amount, packageId, error });
      throw new Error(`Failed to validate purchase for user ${userId}: ${error.message}`);
    }
  }

  /**
   * Complete a Robux purchase
   * @param {string} userId - User ID
   * @param {number} amount - Amount of Robux
   * @param {string} packageId - Package identifier
   * @param {string} paymentMethod - Payment method used
   * @returns {Promise<object>} Purchase details
   */
  async completePurchase(userId, amount, packageId, paymentMethod) {
    try {
      const response = await this._retryRequest(() =>
        this.client.post('/complete-purchase', {
          userId,
          amount,
          packageId,
          paymentMethod,
          timestamp: new Date().toISOString()
        })
      );

      // Invalidate cache
      this.balanceCache.delete(userId);

      this.emit('purchaseCompleted', {
        userId,
        amount,
        packageId,
        purchaseId: response.data.purchaseId
      });

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'completePurchase', userId, amount, packageId, error });
      throw new Error(`Failed to complete purchase for user ${userId}: ${error.message}`);
    }
  }

  /**
   * Get available Robux packages
   * @returns {Promise<array>} Array of available packages
   */
  async getAvailablePackages() {
    try {
      const response = await this._retryRequest(() =>
        this.client.get('/packages')
      );

      return response.data.packages;
    } catch (error) {
      this.emit('error', { action: 'getAvailablePackages', error });
      throw new Error(`Failed to get available packages: ${error.message}`);
    }
  }

  /**
   * Get promotion details
   * @param {string} promotionId - Promotion ID
   * @returns {Promise<object>} Promotion details
   */
  async getPromotion(promotionId) {
    try {
      const response = await this._retryRequest(() =>
        this.client.get(`/promotions/${promotionId}`)
      );

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'getPromotion', promotionId, error });
      throw new Error(`Failed to get promotion ${promotionId}: ${error.message}`);
    }
  }

  /**
   * Apply a promotion code to user account
   * @param {string} userId - User ID
   * @param {string} promoCode - Promotion code
   * @returns {Promise<object>} Promotion result
   */
  async applyPromoCode(userId, promoCode) {
    try {
      const response = await this._retryRequest(() =>
        this.client.post(`/users/${userId}/apply-promo`, {
          promoCode,
          timestamp: new Date().toISOString()
        })
      );

      // Invalidate cache
      this.balanceCache.delete(userId);

      this.emit('promoApplied', {
        userId,
        promoCode,
        bonusAmount: response.data.bonusAmount
      });

      return response.data;
    } catch (error) {
      this.emit('error', { action: 'applyPromoCode', userId, promoCode, error });
      throw new Error(`Failed to apply promo code for user ${userId}: ${error.message}`);
    }
  }

  /**
   * Clear balance cache
   */
  clearCache() {
    this.balanceCache.clear();
    this.emit('cacheCleared');
  }

  /**
   * Get cache stats
   * @returns {object} Cache statistics
   */
  getCacheStats() {
    return {
      size: this.balanceCache.size,
      entries: Array.from(this.balanceCache.keys())
    };
  }

  /**
   * Get balance from cache
   * @private
   */
  _getFromCache(userId) {
    if (!this.balanceCache.has(userId)) {
      return null;
    }

    const { value, timestamp } = this.balanceCache.get(userId);
    if (Date.now() - timestamp > this.cacheExpiry) {
      this.balanceCache.delete(userId);
      return null;
    }

    return value;
  }

  /**
   * Set balance in cache
   * @private
   */
  _setInCache(userId, balance) {
    this.balanceCache.set(userId, {
      value: balance,
      timestamp: Date.now()
    });
  }

  /**
   * Retry request with exponential backoff
   * @private
   */
  async _retryRequest(requestFn) {
    let lastError;

    for (let attempt = 0; attempt < this.retryAttempts; attempt++) {
      try {
        return await requestFn();
      } catch (error) {
        lastError = error;

        // Don't retry on 4xx errors except 429 (rate limit)
        if (error.response?.status >= 400 && error.response?.status < 500 && error.response?.status !== 429) {
          throw error;
        }

        if (attempt < this.retryAttempts - 1) {
          const delay = this.retryDelay * Math.pow(2, attempt);
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }

    throw lastError;
  }
}

module.exports = RobuxAPI;

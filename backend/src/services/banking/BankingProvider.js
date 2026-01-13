/**
 * Base class for all banking providers.
 * Ensures a consistent interface across different aggregators.
 */
class BankingProvider {
    constructor(config = {}) {
        this.config = config;
    }

    /**
     * Generates an authentication link for PSD2/Open Banking.
     * @param {Object} params
     * @returns {Promise<string>}
     */
    async getAuthLink(params) {
        throw new Error('Method getAuthLink() must be implemented');
    }

    /**
     * Fetches the list of accounts.
     * @param {string} token
     * @returns {Promise<Array>}
     */
    async getAccounts(token) {
        throw new Error('Method getAccounts() must be implemented');
    }

    /**
     * Fetches transactions for a specific account.
     * @param {string} accountId
     * @param {Object} options
     * @returns {Promise<Array>}
     */
    async getTransactions(accountId, options) {
        throw new Error('Method getTransactions() must be implemented');
    }

    /**
     * Normalizes provider-specific transaction to StandardTransaction format.
     * @param {Object} rawTransaction
     * @returns {Object} StandardTransaction
     */
    normalizeTransaction(rawTransaction) {
        throw new Error('Method normalizeTransaction() must be implemented');
    }
}

module.exports = BankingProvider;

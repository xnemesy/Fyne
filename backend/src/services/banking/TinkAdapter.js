const axios = require('axios');
const BankingProvider = require('./BankingProvider');

class TinkAdapter extends BankingProvider {
    constructor(config = {}) {
        super(config);
        this.clientId = process.env.TINK_CLIENT_ID;
        this.clientSecret = process.env.TINK_CLIENT_SECRET;
        this.baseUrl = 'https://api.tink.com/api/v1';
    }

    /**
     * Generates a Tink Link URL for account connection.
     */
    async getAuthLink({ redirectUrl, market = 'IT', locale = 'it_IT', state }) {
        // Tink Link URL construction
        // Documentation: https://backend.tink.com/docs/tink-link/transactions/getting-started
        const params = new URLSearchParams({
            client_id: this.clientId,
            redirect_uri: redirectUrl,
            market: market,
            locale: locale,
            scope: 'accounts:read,transactions:read,identity:read',
            state: state || ''
        });

        // RequisitionId in Tink context could be a 'state' or we handle it after callback
        // For Tink, we don't 'create' a requisition via API first for the basic flow
        return {
            link: `https://link.tink.com/1.0/transactions/connect-accounts?${params.toString()}`,
            requisitionId: state // We use state to track back to user
        };
    }

    /**
     * Exchanges auth code for tokens
     */
    async exchangeCode(code) {
        try {
            const response = await axios.post(`${this.baseUrl}/oauth/token`,
                new URLSearchParams({
                    client_id: this.clientId,
                    client_secret: this.clientSecret,
                    grant_type: 'authorization_code',
                    code: code
                }),
                { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
            );
            return response.data; // access_token, refresh_token, etc.
        } catch (error) {
            console.error('Tink exchangeCode Error:', error.response?.data || error.message);
            throw error;
        }
    }

    async getUserProfile(accessToken) {
        const response = await axios.get(`${this.baseUrl}/user`, {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        return response.data; // { id: '...', ... }
    }

    /**
     * Refreshes the access token
     */
    async refreshToken(refreshToken) {
        try {
            const response = await axios.post(`${this.baseUrl}/oauth/token`,
                new URLSearchParams({
                    client_id: this.clientId,
                    client_secret: this.clientSecret,
                    grant_type: 'refresh_token',
                    refresh_token: refreshToken
                }),
                { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } }
            );
            return {
                accessToken: response.data.access_token,
                newRefreshToken: response.data.refresh_token,
                expiresIn: response.data.expires_in
            };
        } catch (error) {
            console.error('Tink refreshToken Error:', error.response?.data || error.message);
            throw new Error('Impossibile rinnovare la sessione bancaria.');
        }
    }

    async getRequisition(requisitionId, accessToken) {
        // For Tink, we just fetch accounts using the accessToken
        const accounts = await this.getAccounts(accessToken);
        return {
            id: requisitionId,
            accounts: accounts.map(a => a.id)
        };
    }

    async getAccounts(accessToken) {
        const response = await axios.get(`${this.baseUrl}/accounts`, {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        return response.data.accounts;
    }

    /**
     * Fetches transactions for all accounts or a specific one
     */
    async getTransactions(accessToken, options = {}) {
        const params = {};
        if (options.accountId) params.accountIds = options.accountId;

        const response = await axios.get(`${this.baseUrl}/transactions`, {
            headers: { 'Authorization': `Bearer ${accessToken}` },
            params: params
        });

        return response.data.transactions.map(tx => this.normalizeTransaction(tx));
    }

    normalizeTransaction(tinkTx) {
        return {
            externalId: tinkTx.id,
            amount: tinkTx.amount,
            currency: tinkTx.currencyDenominatedAmount.currencyCode,
            bookingDate: tinkTx.dates.booked || tinkTx.dates.value,
            description: tinkTx.descriptions.display || tinkTx.descriptions.original,
            categoryHint: tinkTx.categoryDetails?.defaultCategoryName,
            counterPartyName: tinkTx.merchantDetails?.name || 'Ignoto',
            metadata: {
                provider: 'tink',
                mcc: tinkTx.merchantDetails?.mcc,
                type: tinkTx.type
            }
        };
    }
}

module.exports = TinkAdapter;

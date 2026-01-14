const axios = require('axios');
const BankingProvider = require('./BankingProvider');

/**
 * GoCardless (formerly Nordigen) Adapter for Open Banking.
 */
class GoCardlessAdapter extends BankingProvider {
    constructor(config = {}) {
        super(config);
        this.baseUrl = 'https://bankaccountdata.gocardless.com/api/v2';
        this.secretId = process.env.GOCARDLESS_SECRET_ID;
        this.secretKey = process.env.GOCARDLESS_SECRET_KEY;
        this.token = null;
    }

    /**
     * Refreshes the API access token.
     */
    async authenticate() {
        try {
            const response = await axios.post(`${this.baseUrl}/token/new/`, {
                secret_id: this.secretId,
                secret_key: this.secretKey,
            });
            this.token = response.data.access;
            return this.token;
        } catch (error) {
            console.error('GoCardless Authentication Error:', error.response?.data || error.message);
            throw new Error('Failed to authenticate with GoCardless');
        }
    }

    /**
     * Generates authentication link for a specific bank (institution).
     */
    async getAuthLink({ institutionId, redirectUrl, reference }) {
        if (!this.token) await this.authenticate();

        try {
            // 1. Create requisition
            const response = await axios.post(
                `${this.baseUrl}/requisitions/`,
                {
                    redirect: redirectUrl,
                    institution_id: institutionId,
                    reference: reference,
                    user_language: 'IT',
                },
                { headers: { Authorization: `Bearer ${this.token}` } }
            );

            return {
                requisitionId: response.data.id,
                link: response.data.link,
            };
        } catch (error) {
            console.error('GoCardless Requisition Error:', error.response?.data || error.message);
            throw new Error('Failed to create GoCardless requisition');
        }
    }

    /**
     * Normalizes GoCardless transaction to StandardTransaction.
     */
    normalizeTransaction(raw) {
        return {
            providerId: 'gocardless',
            externalId: raw.transactionId || raw.internalTransactionId,
            amount: parseFloat(raw.transactionAmount.amount),
            currency: raw.transactionAmount.currency,
            description: raw.remittanceInformationUnstructured || raw.proprietaryBankTransactionCode || 'No description',
            bookingDate: raw.bookingDate,
            valueDate: raw.valueDate,
            counterPartyName: raw.creditorName || raw.debtorName || 'Unknown',
            status: raw.status || 'BOOKED',
        };
    }

    async getRequisition(requisitionId) {
        if (!this.token) await this.authenticate();
        try {
            const response = await axios.get(
                `${this.baseUrl}/requisitions/${requisitionId}/`,
                { headers: { Authorization: `Bearer ${this.token}` } }
            );
            return response.data;
        } catch (error) {
            console.error('GoCardless Requisition Info Error:', error.response?.data || error.message);
            throw new Error('Failed to fetch requisition info');
        }
    }

    async getTransactions(accountId) {
        if (!this.token) await this.authenticate();

        try {
            const response = await axios.get(
                `${this.baseUrl}/accounts/${accountId}/transactions/`,
                { headers: { Authorization: `Bearer ${this.token}` } }
            );

            const booked = response.data.transactions.booked || [];
            const pending = response.data.transactions.pending || [];

            return [...booked, ...pending].map(tx => this.normalizeTransaction(tx));
        } catch (error) {
            console.error('GoCardless Transactions Error:', error.response?.data || error.message);
            throw new Error('Failed to fetch transactions from GoCardless');
        }
    }
}

module.exports = GoCardlessAdapter;

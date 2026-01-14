const BankingProvider = require('./BankingProvider');
const { v4: uuidv4 } = require('uuid');

/**
 * Mock Provider to simulate real Open Banking flow without external APIs.
 */
class MockBankingAdapter extends BankingProvider {
    constructor(config = {}) {
        super(config);
    }

    async getInstitutions(country = 'IT') {
        return [
            { id: 'SANDBOX_BANK', name: 'Fyne Sandbox Bank', bic: 'FYNESANDBOX', logo: 'https://cdn-icons-png.flaticon.com/512/2830/2830284.png' },
            { id: 'MOCK_INTESA', name: 'Intesa Sanpaolo (Simulata)', bic: 'BCITITMM', logo: 'https://vignette.wikia.nocookie.net/logopedia/images/e/e0/Intesa_Sanpaolo_2007.png' }
        ];
    }

    async getAuthLink({ institutionId, redirectUrl, reference }) {
        // We redirect to a simple static page or even just return success
        // For a true "real-like" experience, we use a simulation URL
        const requisitionId = `mock_req_${Date.now()}`;
        return {
            requisitionId: requisitionId,
            link: `https://banking-abstraction-layer-719543584184.europe-west8.run.app/api/test/simulate-auth?req=${requisitionId}&redirect=${encodeURIComponent(redirectUrl)}`
        };
    }

    async getTransactions(accountId) {
        return [
            {
                externalId: `mock_tx_${Date.now()}_1`,
                amount: -1250.00,
                currency: 'EUR',
                description: 'Affitto Gennaio 2026',
                bookingDate: new Date().toISOString().split('T')[0],
                counterPartyName: 'Proprietario Casa',
                status: 'BOOKED'
            },
            {
                externalId: `mock_tx_${Date.now()}_2`,
                amount: -45.90,
                currency: 'EUR',
                description: 'Amazon.it Market',
                bookingDate: new Date().toISOString().split('T')[0],
                counterPartyName: 'Amazon',
                status: 'BOOKED'
            }
        ];
    }

    async getRequisition(requisitionId) {
        return {
            id: requisitionId,
            status: 'LN',
            accounts: [`mock_acc_${Date.now()}`]
        };
    }

    normalizeTransaction(raw) {
        return raw; // Already normalized in mock
    }
}

module.exports = MockBankingAdapter;

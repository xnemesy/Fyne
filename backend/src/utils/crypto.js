const crypto = require('crypto');

const ALGORITHM = 'aes-256-cbc';
const IV_LENGTH = 16;

/**
 * Encrypts text using AES-256-CBC
 * @param {string} text - The text to encrypt
 * @param {string} masterKey - The master key (should be held by the client or a secure vault)
 * @returns {string} - Combined IV and encrypted text in hex
 */
function encrypt(text, masterKey) {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, Buffer.from(masterKey, 'hex'), iv);
    let encrypted = cipher.update(text);
    encrypted = Buffer.concat([encrypted, cipher.final()]);
    return iv.toString('hex') + ':' + encrypted.toString('hex');
}

/**
 * Decrypts text using AES-256-CBC
 * @param {string} text - The combined IV and encrypted text
 * @param {string} masterKey - The master key
 * @returns {string} - Decrypted text
 */
function decrypt(text, masterKey) {
    const textParts = text.split(':');
    const iv = Buffer.from(textParts.shift(), 'hex');
    const encryptedText = Buffer.from(textParts.join(':'), 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, Buffer.from(masterKey, 'hex'), iv);
    let decrypted = decipher.update(encryptedText);
    decrypted = Buffer.concat([decrypted, decipher.final()]);
    return decrypted.toString();
}

module.exports = { encrypt, decrypt };

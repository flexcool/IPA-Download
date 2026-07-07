import getMAC from 'getmac';
import crypto from 'crypto';
import os from 'os';
import path from 'path';
import {existsSync, mkdirSync, readFileSync, writeFileSync} from 'fs';

function normalizeGuid(value) {
    const cleaned = String(value || '').replace(/[^0-9a-f]/gi, '').toUpperCase();
    return cleaned.length >= 12 ? cleaned.slice(0, 12) : '';
}

function randomGuid() {
    return crypto.randomBytes(6).toString('hex').toUpperCase();
}

function systemGuid() {
    try {
        return normalizeGuid(getMAC());
    } catch {
        return '';
    }
}

function supportDir() {
    if (process.env.IPA_DEVICE_DIR) return process.env.IPA_DEVICE_DIR;
    if (process.env.IPA_SESSION_DIR) return path.dirname(process.env.IPA_SESSION_DIR);
    if (process.platform === 'darwin') {
        return path.join(os.homedir(), 'Library', 'Application Support', 'Pastel');
    }
    if (process.platform === 'win32') {
        return path.join(process.env.APPDATA || os.homedir(), 'Pastel');
    }
    return path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'), 'Pastel');
}

function guidFile() {
    return path.join(supportDir(), 'device-guid.txt');
}

export function getDeviceGuid() {
    const envGuid = normalizeGuid(process.env.IPA_DEVICE_GUID);
    if (envGuid) return envGuid;

    const file = guidFile();
    try {
        if (existsSync(file)) {
            const saved = normalizeGuid(readFileSync(file, 'utf8'));
            if (saved) return saved;
        }
    } catch {
        // Fall through and regenerate.
    }

    const guid = systemGuid() || randomGuid();
    try {
        mkdirSync(path.dirname(file), {recursive: true, mode: 0o700});
        writeFileSync(file, `${guid}\n`, {mode: 0o600});
    } catch {
        // A stable in-memory value is still better than failing the login.
    }
    return guid;
}

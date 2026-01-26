import { describe, it, expect, vi, beforeEach } from 'vitest';
import { get } from 'svelte/store';

// Mock the API client
vi.mock('$lib/api/client', () => ({
  auth: {
    me: vi.fn(),
    requestMagicLink: vi.fn(),
    verifyMagicLink: vi.fn(),
    logout: vi.fn()
  },
  passkeys: {
    registerOptions: vi.fn(),
    register: vi.fn(),
    authenticateOptions: vi.fn(),
    authenticate: vi.fn()
  }
}));

// Mock navigator.credentials
const mockCredentialsCreate = vi.fn();
const mockCredentialsGet = vi.fn();

Object.defineProperty(globalThis, 'navigator', {
  value: {
    credentials: {
      create: mockCredentialsCreate,
      get: mockCredentialsGet
    }
  },
  writable: true
});

import { auth as authApi, passkeys as passkeysApi } from '$lib/api/client';
import { authStore, isAuthenticated, currentUser, isLoading } from './auth';

describe('Auth Store', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.resetAllMocks();
    // Reset store to clean state
    (authStore as any)._reset();
  });

  describe('initialize', () => {
    it('sets loading to false when no token in storage', async () => {
      await authStore.initialize();
      expect(get(isLoading)).toBe(false);
      expect(get(isAuthenticated)).toBe(false);
    });

    it('validates token and loads user when token exists', async () => {
      localStorage.setItem('controlcopypasta_token', 'valid-token');
      vi.mocked(authApi.me).mockResolvedValueOnce({
        user: { id: '123', email: 'test@example.com', inserted_at: '2024-01-01' }
      });

      await authStore.initialize();

      expect(authApi.me).toHaveBeenCalledWith('valid-token');
      expect(get(isAuthenticated)).toBe(true);
      expect(get(currentUser)?.email).toBe('test@example.com');
      expect(get(isLoading)).toBe(false);
    });

    it('clears invalid token from storage', async () => {
      localStorage.setItem('controlcopypasta_token', 'invalid-token');
      vi.mocked(authApi.me).mockRejectedValueOnce(new Error('Invalid token'));

      await authStore.initialize();

      expect(localStorage.getItem('controlcopypasta_token')).toBeNull();
      expect(get(isAuthenticated)).toBe(false);
      expect(get(isLoading)).toBe(false);
    });
  });

  describe('requestMagicLink', () => {
    it('calls API to request magic link', async () => {
      vi.mocked(authApi.requestMagicLink).mockResolvedValueOnce({
        message: 'Check your email'
      });

      const result = await authStore.requestMagicLink('test@example.com');

      expect(authApi.requestMagicLink).toHaveBeenCalledWith('test@example.com');
      expect(result.message).toBe('Check your email');
    });
  });

  describe('verifyMagicLink', () => {
    it('verifies token and stores JWT', async () => {
      vi.mocked(authApi.verifyMagicLink).mockResolvedValueOnce({
        token: 'jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });

      await authStore.verifyMagicLink('magic-token');

      expect(authApi.verifyMagicLink).toHaveBeenCalledWith('magic-token');
      expect(localStorage.getItem('controlcopypasta_token')).toBe('jwt-token');
      expect(get(isAuthenticated)).toBe(true);
      expect(get(currentUser)?.email).toBe('test@example.com');
    });
  });

  describe('logout', () => {
    it('clears token from storage and store', async () => {
      // First, set up an authenticated state
      vi.mocked(authApi.verifyMagicLink).mockResolvedValueOnce({
        token: 'jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });
      await authStore.verifyMagicLink('magic-token');
      expect(get(isAuthenticated)).toBe(true);

      // Now logout
      vi.mocked(authApi.logout).mockResolvedValueOnce({ message: 'Logged out' });
      await authStore.logout();

      expect(authApi.logout).toHaveBeenCalledWith('jwt-token');
      expect(localStorage.getItem('controlcopypasta_token')).toBeNull();
      expect(get(isAuthenticated)).toBe(false);
      expect(get(currentUser)).toBeNull();
    });

    it('clears state even if API call fails', async () => {
      vi.mocked(authApi.verifyMagicLink).mockResolvedValueOnce({
        token: 'jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });
      await authStore.verifyMagicLink('magic-token');

      vi.mocked(authApi.logout).mockRejectedValueOnce(new Error('Network error'));
      await authStore.logout();

      expect(localStorage.getItem('controlcopypasta_token')).toBeNull();
      expect(get(isAuthenticated)).toBe(false);
    });
  });

  describe('getToken', () => {
    it('returns current token', async () => {
      vi.mocked(authApi.verifyMagicLink).mockResolvedValueOnce({
        token: 'jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });
      await authStore.verifyMagicLink('magic-token');

      expect(authStore.getToken()).toBe('jwt-token');
    });

    it('returns null when not authenticated', () => {
      expect(authStore.getToken()).toBeNull();
    });
  });

  describe('registerPasskey', () => {
    it('registers a passkey when authenticated', async () => {
      // First authenticate
      vi.mocked(authApi.verifyMagicLink).mockResolvedValueOnce({
        token: 'jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });
      await authStore.verifyMagicLink('magic-token');

      // Mock server options response
      const mockOptions = {
        challenge: 'dGVzdC1jaGFsbGVuZ2U', // base64url of "test-challenge"
        challengeToken: 'challenge-token',
        rp: { name: 'Test', id: 'localhost' },
        user: { id: 'dXNlci1pZA', name: 'test@example.com', displayName: 'test@example.com' }, // base64url of "user-id"
        pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
        timeout: 60000,
        attestation: 'none',
        excludeCredentials: [],
        authenticatorSelection: {
          residentKey: 'preferred',
          userVerification: 'preferred'
        }
      };

      // Mock native WebAuthn credential response
      const mockRawId = new Uint8Array([1, 2, 3, 4]).buffer;
      const mockClientDataJSON = new Uint8Array([5, 6, 7, 8]).buffer;
      const mockAttestationObject = new Uint8Array([9, 10, 11, 12]).buffer;

      const mockCredential = {
        id: 'AQIDBA', // base64url of [1,2,3,4]
        rawId: mockRawId,
        type: 'public-key',
        response: {
          clientDataJSON: mockClientDataJSON,
          attestationObject: mockAttestationObject,
          getTransports: () => ['internal']
        }
      };

      vi.mocked(passkeysApi.registerOptions).mockResolvedValueOnce(mockOptions);
      mockCredentialsCreate.mockResolvedValueOnce(mockCredential);
      vi.mocked(passkeysApi.register).mockResolvedValueOnce({
        data: { id: 'passkey-id', name: 'My Passkey', transports: ['internal'], inserted_at: '2024-01-01' }
      });

      const result = await authStore.registerPasskey('My Passkey');

      expect(passkeysApi.registerOptions).toHaveBeenCalledWith('jwt-token');
      expect(mockCredentialsCreate).toHaveBeenCalled();
      expect(passkeysApi.register).toHaveBeenCalledWith(
        'jwt-token',
        expect.objectContaining({
          id: 'AQIDBA',
          type: 'public-key'
        }),
        'challenge-token',
        'My Passkey',
        ['internal']
      );
      expect(result.name).toBe('My Passkey');
    });

    it('throws error when not authenticated', async () => {
      await expect(authStore.registerPasskey()).rejects.toThrow('Not authenticated');
    });
  });

  describe('authenticateWithPasskey', () => {
    it('authenticates with passkey and stores token', async () => {
      // Mock server options response
      const mockOptions = {
        challenge: 'YXV0aC1jaGFsbGVuZ2U', // base64url of "auth-challenge"
        challengeToken: 'auth-challenge-token',
        timeout: 60000,
        rpId: 'localhost',
        allowCredentials: [{ id: 'Y3JlZC1pZA', type: 'public-key', transports: ['internal'] }], // base64url of "cred-id"
        userVerification: 'preferred'
      };

      // Mock native WebAuthn credential response
      const mockRawId = new Uint8Array([1, 2, 3, 4]).buffer;
      const mockClientDataJSON = new Uint8Array([5, 6, 7, 8]).buffer;
      const mockAuthenticatorData = new Uint8Array([9, 10, 11, 12]).buffer;
      const mockSignature = new Uint8Array([13, 14, 15, 16]).buffer;
      const mockUserHandle = new Uint8Array([17, 18, 19, 20]).buffer;

      const mockCredential = {
        id: 'AQIDBA',
        rawId: mockRawId,
        type: 'public-key',
        response: {
          clientDataJSON: mockClientDataJSON,
          authenticatorData: mockAuthenticatorData,
          signature: mockSignature,
          userHandle: mockUserHandle
        }
      };

      vi.mocked(passkeysApi.authenticateOptions).mockResolvedValueOnce(mockOptions);
      mockCredentialsGet.mockResolvedValueOnce(mockCredential);
      vi.mocked(passkeysApi.authenticate).mockResolvedValueOnce({
        token: 'passkey-jwt-token',
        user: { id: '123', email: 'test@example.com' }
      });

      const result = await authStore.authenticateWithPasskey('test@example.com');

      expect(passkeysApi.authenticateOptions).toHaveBeenCalledWith('test@example.com');
      expect(mockCredentialsGet).toHaveBeenCalled();
      expect(passkeysApi.authenticate).toHaveBeenCalledWith(
        expect.objectContaining({
          id: 'AQIDBA',
          type: 'public-key'
        }),
        'auth-challenge-token'
      );
      expect(result.token).toBe('passkey-jwt-token');
      expect(localStorage.getItem('controlcopypasta_token')).toBe('passkey-jwt-token');
      expect(get(isAuthenticated)).toBe(true);
      expect(get(currentUser)?.email).toBe('test@example.com');
    });

    it('throws error when no passkeys registered for email', async () => {
      const mockOptions = {
        challenge: 'auth-challenge',
        challengeToken: 'auth-challenge-token',
        timeout: 60000,
        rpId: 'localhost',
        allowCredentials: [],
        userVerification: 'preferred'
      };

      vi.mocked(passkeysApi.authenticateOptions).mockResolvedValueOnce(mockOptions);

      await expect(authStore.authenticateWithPasskey('test@example.com')).rejects.toThrow(
        'No passkeys registered for this email'
      );
    });
  });
});

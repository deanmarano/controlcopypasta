import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';
import { auth as authApi, passkeys as passkeysApi } from '$lib/api/client';

// Helper: Convert base64url string to ArrayBuffer
function base64urlToBuffer(base64url: string): ArrayBuffer {
  const base64 = base64url.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (base64.length % 4)) % 4;
  const padded = base64.padEnd(base64.length + padLength, '=');
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer as ArrayBuffer;
}

// Helper: Convert ArrayBuffer to base64url string
function bufferToBase64url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

interface User {
  id: string;
  email: string;
  is_admin?: boolean;
  onboarding_completed?: boolean;
}

interface AuthState {
  token: string | null;
  user: User | null;
  loading: boolean;
}

const TOKEN_KEY = 'controlcopypasta_token';
const TOKEN_COOKIE = 'controlcopypasta_token';

function setSharedCookie(token: string) {
  if (!browser) return;
  const hostname = window.location.hostname;
  // Set cookie on parent domain so subdomains (e.g. admin.) can read it
  const domainParts = hostname.split('.');
  const domain = domainParts.length >= 2
    ? '.' + domainParts.slice(-2).join('.')
    : hostname;
  const secure = window.location.protocol === 'https:' ? '; Secure' : '';
  document.cookie = `${TOKEN_COOKIE}=${token}; domain=${domain}; path=/; max-age=2592000; SameSite=Lax${secure}`;
}

function clearSharedCookie() {
  if (!browser) return;
  const hostname = window.location.hostname;
  const domainParts = hostname.split('.');
  const domain = domainParts.length >= 2
    ? '.' + domainParts.slice(-2).join('.')
    : hostname;
  document.cookie = `${TOKEN_COOKIE}=; domain=${domain}; path=/; max-age=0`;
}

function createAuthStore() {
  const initialState: AuthState = {
    token: browser ? localStorage.getItem(TOKEN_KEY) : null,
    user: null,
    loading: true
  };

  const { subscribe, set, update } = writable<AuthState>(initialState);

  return {
    subscribe,

    async initialize() {
      const token = browser ? localStorage.getItem(TOKEN_KEY) : null;
      if (!token) {
        update((s) => ({ ...s, loading: false }));
        return;
      }

      try {
        const { user } = await authApi.me(token);
        setSharedCookie(token);
        update((s) => ({ ...s, token, user, loading: false }));
      } catch {
        // Token is invalid, clear it
        if (browser) localStorage.removeItem(TOKEN_KEY);
        clearSharedCookie();
        update((s) => ({ ...s, token: null, user: null, loading: false }));
      }
    },

    async requestMagicLink(email: string) {
      return authApi.requestMagicLink(email);
    },

    async verifyMagicLink(token: string) {
      const result = await authApi.verifyMagicLink(token);
      if (browser) localStorage.setItem(TOKEN_KEY, result.token);
      setSharedCookie(result.token);
      set({ token: result.token, user: result.user, loading: false });
      return result;
    },

    async logout() {
      const token = this.getToken();

      if (token) {
        try {
          await authApi.logout(token);
        } catch {
          // Ignore logout errors
        }
      }

      if (browser) localStorage.removeItem(TOKEN_KEY);
      clearSharedCookie();
      set({ token: null, user: null, loading: false });
    },

    getToken(): string | null {
      let token: string | null = null;
      let unsub: (() => void) | null = null;
      unsub = subscribe((s) => {
        token = s.token;
        // Defer unsubscribe to avoid calling before assignment
        if (unsub) unsub();
      });
      return token;
    },

    async registerPasskey(name?: string) {
      const token = this.getToken();
      if (!token) throw new Error('Not authenticated');

      // Get registration options from server
      const options = await passkeysApi.registerOptions(token);
      const { challengeToken } = options;

      // Convert to native WebAuthn format
      // Build options carefully to avoid issues with password manager extensions
      const userId = base64urlToBuffer(options.user.id);
      const challenge = base64urlToBuffer(options.challenge);

      const publicKeyCredentialCreationOptions: PublicKeyCredentialCreationOptions = {
        challenge: challenge,
        rp: {
          id: options.rp.id,
          name: options.rp.name
        },
        user: {
          id: userId,
          name: options.user.name,
          displayName: options.user.displayName
        },
        pubKeyCredParams: [
          { type: 'public-key', alg: -7 },   // ES256
          { type: 'public-key', alg: -257 }  // RS256
        ],
        timeout: 60000,
        attestation: 'none'
      };

      // Only add optional properties if they have values
      if (options.excludeCredentials && options.excludeCredentials.length > 0) {
        publicKeyCredentialCreationOptions.excludeCredentials = options.excludeCredentials.map(
          (cred: { id: string; type: string; transports?: string[] }) => ({
            id: base64urlToBuffer(cred.id),
            type: 'public-key' as PublicKeyCredentialType,
            transports: cred.transports as AuthenticatorTransport[] | undefined
          })
        );
      }

      // Add authenticatorSelection with explicit values
      if (options.authenticatorSelection) {
        publicKeyCredentialCreationOptions.authenticatorSelection = {
          userVerification: 'preferred',
          residentKey: 'preferred',
          requireResidentKey: false
        };
      }

      // Fix broken WebAuthn API (some password manager extensions break PublicKeyCredential.prototype)
      if (typeof PublicKeyCredential !== 'undefined' && PublicKeyCredential.prototype === undefined) {
        console.log('Detected broken PublicKeyCredential.prototype, attempting to patch...');

        // Create a minimal prototype that satisfies Object.setPrototypeOf
        const minimalPrototype = Object.create(Object.prototype, {
          constructor: { value: PublicKeyCredential, writable: true, configurable: true },
          [Symbol.toStringTag]: { value: 'PublicKeyCredential', configurable: true }
        });

        // Add common methods that might be expected
        minimalPrototype.getClientExtensionResults = function() { return {}; };

        // Patch the broken prototype
        Object.defineProperty(PublicKeyCredential, 'prototype', {
          value: minimalPrototype,
          writable: true,
          configurable: true
        });

        console.log('Patched PublicKeyCredential.prototype:', PublicKeyCredential.prototype);
      }

      // Call native WebAuthn API
      const credential = await navigator.credentials.create({
        publicKey: publicKeyCredentialCreationOptions
      }) as PublicKeyCredential;

      if (!credential) {
        throw new Error('Registration was cancelled or failed');
      }

      const response = credential.response as AuthenticatorAttestationResponse;

      // Get transports if available
      let transports: string[] | undefined;
      if (typeof response.getTransports === 'function') {
        transports = response.getTransports();
      }

      // Convert response to JSON format for server
      const credentialJSON = {
        id: credential.id,
        rawId: bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          clientDataJSON: bufferToBase64url(response.clientDataJSON),
          attestationObject: bufferToBase64url(response.attestationObject)
        }
      };

      const result = await passkeysApi.register(
        token,
        credentialJSON,
        challengeToken,
        name,
        transports
      );

      return result.data;
    },

    async authenticateWithPasskey(email: string) {
      // Get authentication options from server
      const options = await passkeysApi.authenticateOptions(email);
      const { challengeToken } = options;

      if (!options.allowCredentials || options.allowCredentials.length === 0) {
        throw new Error('No passkeys registered for this email');
      }

      // Convert to native WebAuthn format
      const publicKeyCredentialRequestOptions: PublicKeyCredentialRequestOptions = {
        challenge: base64urlToBuffer(options.challenge),
        timeout: options.timeout,
        rpId: options.rpId,
        allowCredentials: options.allowCredentials.map((cred: { id: string; type: string; transports?: string[] }) => ({
          id: base64urlToBuffer(cred.id),
          type: cred.type as PublicKeyCredentialType,
          transports: cred.transports as AuthenticatorTransport[]
        })),
        userVerification: options.userVerification as UserVerificationRequirement
      };

      // Call native WebAuthn API
      const credential = await navigator.credentials.get({
        publicKey: publicKeyCredentialRequestOptions
      }) as PublicKeyCredential;

      if (!credential) {
        throw new Error('Authentication was cancelled or failed');
      }

      const response = credential.response as AuthenticatorAssertionResponse;

      // Convert response to JSON format for server
      const credentialJSON = {
        id: credential.id,
        rawId: bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          clientDataJSON: bufferToBase64url(response.clientDataJSON),
          authenticatorData: bufferToBase64url(response.authenticatorData),
          signature: bufferToBase64url(response.signature),
          userHandle: response.userHandle ? bufferToBase64url(response.userHandle) : undefined
        }
      };

      // Send credential to server for verification
      const result = await passkeysApi.authenticate(credentialJSON, challengeToken);

      // Save token and user
      if (browser) localStorage.setItem(TOKEN_KEY, result.token);
      setSharedCookie(result.token);
      set({ token: result.token, user: result.user, loading: false });

      return result;
    },

    // For testing - reset store to initial state
    _reset() {
      if (browser) localStorage.removeItem(TOKEN_KEY);
      set({ token: null, user: null, loading: true });
    }
  };
}

export const authStore = createAuthStore();

export const isAuthenticated = derived(authStore, ($auth) => !!$auth.user);
export const currentUser = derived(authStore, ($auth) => $auth.user);
export const isLoading = derived(authStore, ($auth) => $auth.loading);
export const isAdmin = derived(authStore, ($auth) => $auth.user?.is_admin ?? false);
export const needsOnboarding = derived(authStore, ($auth) => !!$auth.user && $auth.user.onboarding_completed === false);

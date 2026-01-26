import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { auth, recipes, tags, passkeys, ApiError } from './client';

// Mock fetch globally
const mockFetch = vi.fn();
globalThis.fetch = mockFetch;

describe('API Client', () => {
  beforeEach(() => {
    mockFetch.mockReset();
  });

  describe('auth', () => {
    describe('requestMagicLink', () => {
      it('sends email to magic link endpoint', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ message: 'Check your email' })
        });

        const result = await auth.requestMagicLink('test@example.com');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/magic-link'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ email: 'test@example.com' })
          })
        );
        expect(result.message).toBe('Check your email');
      });
    });

    describe('verifyMagicLink', () => {
      it('verifies token and returns JWT', async () => {
        const mockResponse = {
          token: 'jwt-token',
          user: { id: '123', email: 'test@example.com' }
        };
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve(mockResponse)
        });

        const result = await auth.verifyMagicLink('magic-token');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/magic-link/verify'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ token: 'magic-token' })
          })
        );
        expect(result.token).toBe('jwt-token');
        expect(result.user.email).toBe('test@example.com');
      });
    });

    describe('me', () => {
      it('fetches current user with auth header', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () =>
            Promise.resolve({
              user: { id: '123', email: 'test@example.com', inserted_at: '2024-01-01' }
            })
        });

        const result = await auth.me('jwt-token');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/me'),
          expect.objectContaining({
            headers: expect.objectContaining({
              Authorization: 'Bearer jwt-token'
            })
          })
        );
        expect(result.user.email).toBe('test@example.com');
      });
    });

    describe('logout', () => {
      it('calls logout endpoint', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ message: 'Logged out' })
        });

        await auth.logout('jwt-token');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/logout'),
          expect.objectContaining({
            method: 'POST',
            headers: expect.objectContaining({
              Authorization: 'Bearer jwt-token'
            })
          })
        );
      });
    });
  });

  describe('recipes', () => {
    const token = 'test-token';

    describe('list', () => {
      it('fetches recipes list', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: [] })
        });

        await recipes.list(token);

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes'),
          expect.objectContaining({
            headers: expect.objectContaining({
              Authorization: 'Bearer test-token'
            })
          })
        );
      });

      it('includes search params when provided', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: [] })
        });

        await recipes.list(token, { q: 'pasta', tag: 'dinner', limit: 10 });

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringMatching(/q=pasta.*tag=dinner.*limit=10/),
          expect.any(Object)
        );
      });
    });

    describe('get', () => {
      it('fetches a single recipe', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: { id: '123', title: 'Test' } })
        });

        const result = await recipes.get(token, '123');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes/123'),
          expect.any(Object)
        );
        expect(result.data.id).toBe('123');
      });
    });

    describe('create', () => {
      it('creates a new recipe', async () => {
        const newRecipe = { title: 'New Recipe' };
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: { id: '123', ...newRecipe } })
        });

        const result = await recipes.create(token, newRecipe);

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ recipe: newRecipe })
          })
        );
        expect(result.data.title).toBe('New Recipe');
      });
    });

    describe('update', () => {
      it('updates an existing recipe', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: { id: '123', title: 'Updated' } })
        });

        await recipes.update(token, '123', { title: 'Updated' });

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes/123'),
          expect.objectContaining({
            method: 'PUT',
            body: JSON.stringify({ recipe: { title: 'Updated' } })
          })
        );
      });
    });

    describe('delete', () => {
      it('deletes a recipe', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          status: 204,
          json: () => Promise.resolve(null)
        });

        await recipes.delete(token, '123');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes/123'),
          expect.objectContaining({
            method: 'DELETE'
          })
        );
      });
    });

    describe('parse', () => {
      it('parses a recipe from URL', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: { title: 'Parsed Recipe' } })
        });

        const result = await recipes.parse(token, 'https://example.com/recipe');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/recipes/parse'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ url: 'https://example.com/recipe' })
          })
        );
        expect(result.data.title).toBe('Parsed Recipe');
      });
    });
  });

  describe('tags', () => {
    const token = 'test-token';

    describe('list', () => {
      it('fetches tags list', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: [{ id: '1', name: 'dinner' }] })
        });

        const result = await tags.list(token);

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/tags'),
          expect.any(Object)
        );
        expect(result.data).toHaveLength(1);
      });
    });

    describe('create', () => {
      it('creates a new tag', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve({ data: { id: '1', name: 'breakfast' } })
        });

        const result = await tags.create(token, 'breakfast');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/tags'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ tag: { name: 'breakfast' } })
          })
        );
        expect(result.data.name).toBe('breakfast');
      });
    });

    describe('delete', () => {
      it('deletes a tag', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          status: 204,
          json: () => Promise.resolve(null)
        });

        await tags.delete(token, '123');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/tags/123'),
          expect.objectContaining({
            method: 'DELETE'
          })
        );
      });
    });
  });

  describe('passkeys', () => {
    const token = 'test-token';

    describe('registerOptions', () => {
      it('fetches registration options', async () => {
        const mockOptions = {
          challenge: 'test-challenge',
          rp: { name: 'Test', id: 'localhost' },
          user: { id: 'user-id', name: 'test@example.com', displayName: 'test@example.com' },
          pubKeyCredParams: [{ alg: -7, type: 'public-key' }],
          timeout: 60000,
          attestation: 'none',
          excludeCredentials: [],
          authenticatorSelection: { residentKey: 'preferred', userVerification: 'preferred' },
          challengeToken: 'challenge-token'
        };

        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve(mockOptions)
        });

        const result = await passkeys.registerOptions(token);

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys/register/options'),
          expect.objectContaining({
            method: 'POST',
            headers: expect.objectContaining({
              Authorization: 'Bearer test-token'
            })
          })
        );
        expect(result.challenge).toBe('test-challenge');
        expect(result.challengeToken).toBe('challenge-token');
      });
    });

    describe('register', () => {
      it('sends registration credential to server', async () => {
        const mockCredential = {
          id: 'credential-id',
          rawId: 'raw-id',
          response: {
            clientDataJSON: 'client-data',
            attestationObject: 'attestation'
          },
          type: 'public-key'
        };

        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () =>
            Promise.resolve({
              data: { id: 'passkey-id', name: 'My Passkey', transports: ['internal'] }
            })
        });

        const result = await passkeys.register(
          token,
          mockCredential,
          'challenge-token',
          'My Passkey',
          ['internal']
        );

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys/register'),
          expect.objectContaining({
            method: 'POST',
            headers: expect.objectContaining({
              Authorization: 'Bearer test-token'
            }),
            body: expect.stringContaining('challenge-token')
          })
        );
        expect(result.data.name).toBe('My Passkey');
      });
    });

    describe('authenticateOptions', () => {
      it('fetches authentication options for email', async () => {
        const mockOptions = {
          challenge: 'auth-challenge',
          timeout: 60000,
          rpId: 'localhost',
          allowCredentials: [{ id: 'cred-id', type: 'public-key', transports: ['internal'] }],
          userVerification: 'preferred',
          challengeToken: 'auth-challenge-token'
        };

        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () => Promise.resolve(mockOptions)
        });

        const result = await passkeys.authenticateOptions('test@example.com');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys/authenticate/options'),
          expect.objectContaining({
            method: 'POST',
            body: JSON.stringify({ email: 'test@example.com' })
          })
        );
        expect(result.challenge).toBe('auth-challenge');
        expect(result.allowCredentials).toHaveLength(1);
      });
    });

    describe('authenticate', () => {
      it('sends authentication credential to server', async () => {
        const mockCredential = {
          id: 'credential-id',
          rawId: 'raw-id',
          response: {
            clientDataJSON: 'client-data',
            authenticatorData: 'auth-data',
            signature: 'signature'
          },
          type: 'public-key'
        };

        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () =>
            Promise.resolve({
              token: 'jwt-token',
              user: { id: 'user-id', email: 'test@example.com' }
            })
        });

        const result = await passkeys.authenticate(mockCredential, 'challenge-token');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys/authenticate'),
          expect.objectContaining({
            method: 'POST',
            body: expect.stringContaining('challenge-token')
          })
        );
        expect(result.token).toBe('jwt-token');
        expect(result.user.email).toBe('test@example.com');
      });
    });

    describe('list', () => {
      it('fetches list of passkeys', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          json: () =>
            Promise.resolve({
              data: [
                { id: '1', name: 'MacBook', transports: ['internal'], inserted_at: '2024-01-01' },
                { id: '2', name: 'iPhone', transports: ['internal', 'hybrid'], inserted_at: '2024-01-02' }
              ]
            })
        });

        const result = await passkeys.list(token);

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys'),
          expect.objectContaining({
            headers: expect.objectContaining({
              Authorization: 'Bearer test-token'
            })
          })
        );
        expect(result.data).toHaveLength(2);
        expect(result.data[0].name).toBe('MacBook');
      });
    });

    describe('delete', () => {
      it('deletes a passkey', async () => {
        mockFetch.mockResolvedValueOnce({
          ok: true,
          status: 204,
          json: () => Promise.resolve(null)
        });

        await passkeys.delete(token, 'passkey-id');

        expect(mockFetch).toHaveBeenCalledWith(
          expect.stringContaining('/auth/passkeys/passkey-id'),
          expect.objectContaining({
            method: 'DELETE',
            headers: expect.objectContaining({
              Authorization: 'Bearer test-token'
            })
          })
        );
      });
    });
  });

  describe('error handling', () => {
    it('throws ApiError on non-ok response', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 401,
        json: () => Promise.resolve({ error: 'Unauthorized' })
      });

      await expect(auth.me('bad-token')).rejects.toThrow(ApiError);
    });

    it('ApiError contains status and data', async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 422,
        json: () => Promise.resolve({ errors: { title: ['is required'] } })
      });

      try {
        await recipes.create('token', { title: '' });
      } catch (e) {
        expect(e).toBeInstanceOf(ApiError);
        expect((e as ApiError).status).toBe(422);
        expect((e as ApiError).data).toEqual({ errors: { title: ['is required'] } });
      }
    });
  });
});

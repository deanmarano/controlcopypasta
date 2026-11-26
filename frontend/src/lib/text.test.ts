import { describe, it, expect } from 'vitest';
import { decodeEntities, truncate } from './text';

describe('decodeEntities', () => {
  it('decodes numeric, hex and named entities', () => {
    expect(decodeEntities('isn&#039;t')).toBe("isn't");
    expect(decodeEntities('caf&#xE9;')).toBe('café');
    expect(decodeEntities('salt &amp; pepper')).toBe('salt & pepper');
  });

  it('leaves unknown entities and plain ampersands alone', () => {
    expect(decodeEntities('mac & cheese')).toBe('mac & cheese');
    expect(decodeEntities('&notarealentity;')).toBe('&notarealentity;');
  });

  it('returns an empty string for missing text', () => {
    expect(decodeEntities(null)).toBe('');
    expect(decodeEntities(undefined)).toBe('');
  });
});

describe('truncate', () => {
  it('returns short text unchanged, with no ellipsis', () => {
    expect(truncate('Quick dinner.', 100)).toBe('Quick dinner.');
  });

  it('cuts on a word boundary and adds an ellipsis', () => {
    expect(truncate('A hearty vegetarian pasta sauce fortified with vegetables', 30)).toBe('A hearty vegetarian pasta…');
  });

  it('decodes entities before measuring', () => {
    expect(truncate('isn&#039;t', 100)).toBe("isn't");
  });
});

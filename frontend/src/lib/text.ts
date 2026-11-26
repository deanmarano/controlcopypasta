const NAMED: Record<string, string> = {
  amp: '&',
  lt: '<',
  gt: '>',
  quot: '"',
  apos: "'",
  nbsp: ' ',
  ndash: '–',
  mdash: '—',
  hellip: '…',
  rsquo: '’',
  lsquo: '‘',
  rdquo: '”',
  ldquo: '“',
  deg: '°',
  frac12: '½',
  frac14: '¼',
  frac34: '¾'
};

/**
 * Turns leftover HTML entities ("isn&#039;t", "salt &amp; pepper") back into
 * characters. Some source sites double-encode their recipe text, so one layer
 * survives parsing and would otherwise be shown to the reader as-is.
 */
export function decodeEntities(text: string | null | undefined): string {
  if (!text) return '';
  if (!text.includes('&')) return text;

  return text.replace(/&(#x[0-9a-f]+|#\d+|[a-z][a-z0-9]*);/gi, (match, entity: string) => {
    if (entity[0] === '#') {
      const hex = entity[1] === 'x' || entity[1] === 'X';
      const code = parseInt(entity.slice(hex ? 2 : 1), hex ? 16 : 10);
      return Number.isFinite(code) && code > 0 && code <= 0x10ffff ? String.fromCodePoint(code) : match;
    }
    return NAMED[entity.toLowerCase()] ?? match;
  });
}

/** Shortens text to roughly `max` characters on a word boundary, adding an ellipsis only when cut. */
export function truncate(text: string | null | undefined, max: number): string {
  const clean = decodeEntities(text).trim();
  if (clean.length <= max) return clean;
  const cut = clean.slice(0, max);
  const lastSpace = cut.lastIndexOf(' ');
  return (lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).replace(/[\s.,;:]+$/, '') + '…';
}

/*
 * The size a string takes on screen, measured the way recharts measures tick labels
 * (recharts/src/util/DOMUtils.ts): in a hidden span appended to <body>, with the font size and
 * letter spacing given. The axes use it to drop ticks whose labels would overlap, so measuring
 * the same way keeps the same ticks.
 */

export interface TextStyle {
  fontSize?: string
  letterSpacing?: string
}

export interface TextSize {
  width: number
  height: number
}

const SPAN_ID = 'jn_chart_measurement_span'
const SPAN_STYLE: Partial<CSSStyleDeclaration> = {
  position: 'absolute',
  top: '-20000px',
  left: '0',
  padding: '0',
  margin: '0',
  border: 'none',
  whiteSpace: 'pre',
}
const cache = new Map<string, TextSize>()
const CACHE_SIZE = 2000

function measure(text: string, style: TextStyle): TextSize {
  if (typeof document === 'undefined') return { width: 0, height: 0 }
  let span = document.getElementById(SPAN_ID)
  if (!span) {
    span = document.createElement('span')
    span.id = SPAN_ID
    span.setAttribute('aria-hidden', 'true')
    document.body.appendChild(span)
  }
  Object.assign(span.style, SPAN_STYLE, {
    fontSize: style.fontSize ?? '',
    letterSpacing: style.letterSpacing ?? '',
  })
  span.textContent = text
  const rect = span.getBoundingClientRect()
  return { width: rect.width, height: rect.height }
}

/** The width and height of `text` in the page's font, at the given size and letter spacing. */
export function getStringSize(text: unknown, style: TextStyle = {}): TextSize {
  if (text === undefined || text === null) return { width: 0, height: 0 }
  const value = String(text)
  const key = `${value}|${style.fontSize ?? ''}|${style.letterSpacing ?? ''}`
  const cached = cache.get(key)
  if (cached) return cached
  const size = measure(value, style)
  // A zero size means nothing was laid out (a detached document); don't remember it.
  if (size.width || size.height) {
    if (cache.size >= CACHE_SIZE) cache.delete(cache.keys().next().value!)
    cache.set(key, size)
  }
  return size
}

/** Forgets every measurement, for a test that changes the page's fonts. */
export function clearStringSizeCache(): void {
  cache.clear()
}

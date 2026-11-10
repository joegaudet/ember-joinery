/**
 * Whether `file` matches an `accept` list, as a file picker filters it: extensions (`.pdf`),
 * MIME types (`text/csv`) and wildcards (`image/*`), comma-separated. An empty list takes
 * every file.
 *
 *   acceptsFile(new File([], 'cv.pdf', { type: 'application/pdf' }), '.pdf,image/*') // true
 */
export function acceptsFile(file: File, accept: string | undefined): boolean {
  if (!accept?.trim()) return true
  const name = file.name.toLowerCase()
  const type = file.type.toLowerCase()
  return accept.split(',').some(raw => {
    const pattern = raw.trim().toLowerCase()
    if (!pattern) return false
    if (pattern.startsWith('.')) return name.endsWith(pattern)
    if (pattern.endsWith('/*')) return type.startsWith(pattern.slice(0, -1))
    return type === pattern
  })
}

/**
 * A file's kind, from its name's extension, in capitals: `PDF`, `PNG`… (at most four letters),
 * or `unknown` (`FILE` by default) when it has none.
 *
 *   fileKind('cv.pdf') // 'PDF'
 *   fileKind('README', 'ملف') // 'ملف'
 */
export function fileKind(name: string, unknown = 'FILE'): string {
  const dot = name.lastIndexOf('.')
  return dot > 0 && dot < name.length - 1 ? name.slice(dot + 1, dot + 5).toUpperCase() : unknown
}

const UNITS = ['byte', 'kilobyte', 'megabyte', 'gigabyte', 'terabyte'] as const

/**
 * A size in bytes as people read it, in decimal units and the locale's words: `920 bytes`,
 * `184.3 kB`, `1.2 MB`.
 *
 *   formatFileSize(1_240_000) // '1.2 MB'
 *   formatFileSize(1_240_000, 'de') // '1,2 MB'
 */
export function formatFileSize(bytes: number, locale?: string): string {
  let size = bytes
  let unit = 0
  while (size >= 1000 && unit < UNITS.length - 1) {
    size /= 1000
    unit++
  }
  return new Intl.NumberFormat(locale, {
    style: 'unit',
    unit: UNITS[unit],
    unitDisplay: unit ? 'short' : 'long',
    maximumFractionDigits: unit ? 1 : 0,
  }).format(size)
}

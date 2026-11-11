/** Words the sidebar spells in capitals. */
const ACRONYMS: Record<string, string> = {
  api: 'API',
  dom: 'DOM',
  otp: 'OTP',
  rtl: 'RTL',
  ui: 'UI',
}

/**
 * A page or section's name in the sidebar, in title case as on ui.shadcn.com:
 * `alert-dialog` → "Alert Dialog", `input-otp` → "Input OTP". A section's `index` page is its
 * "Overview".
 */
export function title(name: string): string {
  const bare = name.replace(/\.(g[jt]s\.)?md$/, '')
  if (bare === 'index') return 'Overview'
  return bare
    .split('-')
    .filter(Boolean)
    .map(word => ACRONYMS[word] ?? word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
}

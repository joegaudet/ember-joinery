// The Joinery site's behaviour. The page is static HTML styled with Joinery's own CSS, so the
// few parts that respond here do in plain JavaScript what the Ember components do in an app:
// the switches toggle (`aria-checked` and `data-state`, which joinery.css styles), the theme
// picker swaps the page's base colour and style sheets and sets its radius, the light/dark
// toggle puts `.dark` on <html> and remembers the choice, and the hero's card resets and saves.
// The <head> applies the remembered scheme before the page draws.

const root = document.documentElement
const SCHEME_KEY = 'joinery-site-scheme'

const read = key => {
  try {
    return localStorage.getItem(key)
  } catch {
    return null
  }
}

const write = (key, value) => {
  try {
    localStorage.setItem(key, value)
  } catch {
    // Storage is off: the choice lasts until the page is closed.
  }
}

// ---- switches --------------------------------------------------------------------------------

/** Sets a Switch on or off, as Joinery's does: its ARIA, and the state its thumb is styled by. */
function setSwitch(button, checked) {
  const state = checked ? 'checked' : 'unchecked'
  button.setAttribute('aria-checked', String(checked))
  button.dataset.state = state
  for (const thumb of button.querySelectorAll('[data-slot="switch-thumb"]')) {
    thumb.dataset.state = state
  }
}

for (const button of document.querySelectorAll('[data-slot="switch"]')) {
  button.addEventListener('click', () => {
    setSwitch(button, button.getAttribute('aria-checked') !== 'true')
    button.dispatchEvent(new Event('change', { bubbles: true }))
  })
}

// ---- light and dark ------------------------------------------------------------------------

const systemDark = window.matchMedia('(prefers-color-scheme: dark)')

/** Shows the page light or dark, and every control for it in step. */
function showScheme(dark) {
  root.classList.toggle('dark', dark)
  for (const toggle of document.querySelectorAll('[data-site-scheme-toggle]')) {
    toggle.setAttribute('aria-pressed', String(dark))
  }
  for (const toggle of document.querySelectorAll('[data-site-scheme-switch]')) {
    setSwitch(toggle, dark)
  }
}

function chooseScheme(dark) {
  write(SCHEME_KEY, dark ? 'dark' : 'light')
  showScheme(dark)
}

showScheme(root.classList.contains('dark'))

// Until the visitor picks one, the page follows the system's.
systemDark.addEventListener('change', event => {
  if (!read(SCHEME_KEY)) showScheme(event.matches)
})

for (const toggle of document.querySelectorAll('[data-site-scheme-toggle]')) {
  toggle.addEventListener('click', () => chooseScheme(!root.classList.contains('dark')))
}

for (const toggle of document.querySelectorAll('[data-site-scheme-switch]')) {
  toggle.addEventListener('change', () =>
    chooseScheme(toggle.getAttribute('aria-checked') === 'true'),
  )
}

// ---- the theme picker ----------------------------------------------------------------------

const DEFAULT_THEME = { style: 'nova', base: 'neutral', radius: '0.625' }
const theme = { ...DEFAULT_THEME }

/** The sheet an app imports for a style or a base colour, relative to the package. */
const styleSheet = style => (style === 'nova' ? 'joinery.css' : `styles/${style}.css`)
const baseSheet = base => (base === 'neutral' ? 'tokens.css' : `themes/${base}.css`)

/**
 * Points one of the page's Joinery style sheets at another file. The new sheet loads beside the
 * old one, which goes once it has, so the page is never unstyled in between.
 */
function swapSheet(id, href) {
  const old = document.getElementById(id)
  if (!old || old.getAttribute('href') === href) return
  const next = old.cloneNode()
  next.href = href
  next.addEventListener('load', () => old.remove(), { once: true })
  next.addEventListener('error', () => next.remove(), { once: true })
  old.after(next)
  old.removeAttribute('id')
  next.id = id
}

/** The lines an app's CSS imports would be, for the theme the page shows. */
function themeCode({ style, base, radius }) {
  const lines = [
    `import '@ember-joinery/ember/${baseSheet(base)}'`,
    `import '@ember-joinery/ember/${styleSheet(style)}'`,
  ]
  if (radius !== DEFAULT_THEME.radius) {
    lines.push('', '/* app.css */', `:root {`, `  --radius: ${radius}rem;`, `}`)
  }
  return lines.join('\n')
}

function showTheme() {
  swapSheet('jn-tokens', `joinery/${baseSheet(theme.base)}`)
  swapSheet('jn-style', `joinery/${styleSheet(theme.style)}`)
  if (theme.radius === DEFAULT_THEME.radius) root.style.removeProperty('--radius')
  else root.style.setProperty('--radius', `${theme.radius}rem`)
  const code = document.getElementById('theme-code')
  if (code) {
    code.textContent = themeCode(theme)
    window.Prism?.highlightElement(code)
  }
}

for (const select of document.querySelectorAll('[data-site-theme]')) {
  // A reload can keep a select's last choice; start from what the page shows.
  select.value = theme[select.dataset.siteTheme]
  select.addEventListener('change', () => {
    theme[select.dataset.siteTheme] = select.value
    showTheme()
  })
}

const resetTheme = document.querySelector('[data-site-theme-reset]')
resetTheme?.addEventListener('click', () => {
  Object.assign(theme, DEFAULT_THEME)
  for (const select of document.querySelectorAll('[data-site-theme]')) {
    select.value = theme[select.dataset.siteTheme]
  }
  showTheme()
})

// ---- the hero's card -----------------------------------------------------------------------

const profile = document.getElementById('hero-profile')
if (profile) {
  const save = profile.querySelector('[type="submit"]')
  const label = save.textContent
  let timer
  profile.addEventListener('submit', event => {
    event.preventDefault()
    save.textContent = 'Saved'
    clearTimeout(timer)
    timer = setTimeout(() => (save.textContent = label), 1500)
  })
  // Reset puts the inputs back by itself; the switches are buttons, so put them back too.
  profile.addEventListener('reset', () => {
    for (const button of profile.querySelectorAll('[data-slot="switch"]')) {
      setSwitch(button, button.hasAttribute('data-default-checked'))
    }
  })
}

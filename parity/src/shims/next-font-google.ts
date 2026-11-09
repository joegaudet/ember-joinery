// next/font/google for the parity app. Fonts are loaded by the app (and by scripts/parity.mjs),
// so a font loader only names its family.
type Font = { className: string; variable: string; style: { fontFamily: string } }

const font =
  (family: string) =>
  (_options?: unknown): Font => ({ className: '', variable: '', style: { fontFamily: family } })

export const Geist = font('Geist Variable')
export const Geist_Mono = font('Geist Mono Variable')
export const Noto_Sans_Arabic = font('Noto Sans Arabic Variable')
export const Noto_Sans_Hebrew = font('Noto Sans Hebrew Variable')
export const Vazirmatn = font('Vazirmatn')
export const Inter = font('Inter')

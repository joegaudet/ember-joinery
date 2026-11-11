// The module upstream-plugin.mjs generates: every upstream example the app can render.
declare module 'virtual:parity-examples' {
  export const examples: Record<
    string,
    {
      id: string
      kind: 'example' | 'chart' | 'block'
      styleName: string
      base: string
      page: string
      direction: 'ltr' | 'rtl'
      align: 'center' | 'start' | 'end'
      load: () => Promise<Record<string, unknown>>
    }
  >
}

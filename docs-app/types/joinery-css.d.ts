// Virtual modules from joinery-css.mjs, the guide's Vite plugin.
declare module 'virtual:joinery-themes' {
  /** A base colour's tokens: each custom property's value, light and dark. */
  export interface ThemeTokens {
    light: Record<string, string>
    dark: Record<string, string>
  }
  /** The styles the package ships, Nova first. */
  export const styles: string[]
  /** The base colours, Neutral first. */
  export const baseColors: Record<string, ThemeTokens>
}

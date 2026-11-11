/**
 * The destructive badge's text: upstream draws it `--destructive` on its own 10% tint, about 4:1
 * in the light themes, under the 4.5:1 WCAG AA asks of its 12px text. The Badge page's
 * Accessibility notes say so, and how an app can darken it.
 */
export default ['[data-slot="badge"][data-variant="destructive"]']

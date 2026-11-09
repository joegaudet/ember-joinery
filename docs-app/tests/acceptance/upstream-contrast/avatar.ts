/**
 * An avatar's initials and a group's count: upstream draws them `--muted-foreground` on
 * `--muted`, 4.34:1 in the default theme, under the 4.5:1 WCAG AA asks of their 14px text. The
 * Avatar page's Accessibility notes say so, and how an app can darken it.
 */
export default ['[data-slot="avatar-fallback"]', '[data-slot="avatar-group-count"]']

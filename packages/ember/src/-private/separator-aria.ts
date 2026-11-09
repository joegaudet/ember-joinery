/** Which way a part's separator runs. */
export type Orientation = 'horizontal' | 'vertical'

/** What a separator part tells assistive technology, and its `data-orientation`. */
export interface SeparatorPartAria {
  role: 'none' | 'separator'
  'aria-orientation': 'vertical' | undefined
  'data-orientation': Orientation
  [attribute: string]: string | undefined
}

/**
 * The ARIA of a separator part (ItemSeparator, ButtonGroupSeparator), as the Radix
 * `Separator` that upstream's parts render: a decorative one (the default, as upstream's) has
 * `role="none"`; one that isn't has the `separator` role, and `aria-orientation="vertical"`
 * when it is vertical (horizontal is the role's default). Both carry `data-orientation`, which
 * the `data-horizontal:` and `data-vertical:` rules read.
 */
export function separatorPartAria(
  orientation: Orientation | undefined,
  decorative: boolean | undefined,
  fallback: Orientation,
): SeparatorPartAria {
  const direction: Orientation =
    (orientation ?? fallback) === 'vertical' ? 'vertical' : 'horizontal'
  const semantic = decorative === false
  return {
    role: semantic ? 'separator' : 'none',
    'aria-orientation': semantic && direction === 'vertical' ? 'vertical' : undefined,
    'data-orientation': direction,
  }
}

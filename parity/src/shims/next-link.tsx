// next/link for the parity app: a plain anchor. The examples only render links.
import * as React from 'react'

type Props = Omit<React.ComponentProps<'a'>, 'href'> & {
  href: string | { pathname?: string }
  prefetch?: boolean
  replace?: boolean
  scroll?: boolean
}

export default function Link({ href, ...props }: Props) {
  const anchor: Record<string, unknown> = { ...props }
  for (const key of ['prefetch', 'replace', 'scroll']) delete anchor[key]
  return (
    <a
      href={typeof href === 'string' ? href : (href.pathname ?? '#')}
      {...(anchor as React.ComponentProps<'a'>)}
    />
  )
}

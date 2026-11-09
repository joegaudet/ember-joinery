// next/image for the parity app: a plain img with the same layout props.
import * as React from 'react'

type Props = Omit<React.ComponentProps<'img'>, 'src'> & {
  src: string | { src: string }
  fill?: boolean
  priority?: boolean
  quality?: number
  placeholder?: string
  unoptimized?: boolean
}

export default function Image({ src, fill, style, ...props }: Props) {
  const img: Record<string, unknown> = { ...props }
  for (const key of ['priority', 'quality', 'placeholder', 'unoptimized']) delete img[key]
  const fillStyle: React.CSSProperties = fill
    ? { position: 'absolute', inset: 0, width: '100%', height: '100%' }
    : {}
  return (
    <img
      src={typeof src === 'string' ? src : src.src}
      style={{ ...fillStyle, ...style }}
      {...(img as React.ComponentProps<'img'>)}
    />
  )
}

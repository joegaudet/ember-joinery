import { Pagination } from '@ember-joinery/ember'

// Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
// Arabic: its preview opens in Arabic, and the frame has no language picker. These are its
// strings, upstream's `t`.
const text = {
  previous: 'السابق',
  next: 'التالي',
}

function toArabicNumerals(num: number): string {
  const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩']
  return num
    .toString()
    .split('')
    .map(digit => arabicNumerals[parseInt(digit, 10)])
    .join('')
}

<template>
  {{!
    Upstream leaves the previous and next links' names in English ("Go to previous page"),
    where their text is Arabic; Joinery's are in Arabic too, and say the text they show
    ("go to the previous"), as a right-to-left page would name them and as WCAG's label in
    name asks. They're read aloud, not drawn, so the screenshot is the same.
  }}
  <Pagination as |p|>
    <p.Content>
      <p.Item>
        <p.Previous href="#" @text={{text.previous}} @label="انتقل إلى السابق" />
      </p.Item>
      <p.Item>
        <p.Link href="#">{{toArabicNumerals 1}}</p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#" @isActive={{true}}>
          {{toArabicNumerals 2}}
        </p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#">{{toArabicNumerals 3}}</p.Link>
      </p.Item>
      <p.Item>
        <p.Ellipsis />
      </p.Item>
      <p.Item>
        <p.Next href="#" @text={{text.next}} @label="انتقل إلى التالي" />
      </p.Item>
    </p.Content>
  </Pagination>
</template>

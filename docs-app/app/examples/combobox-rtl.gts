import { array, get } from '@ember/helper'
import { Combobox, Field, FieldLabel } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  label: 'الفئات',
  placeholder: 'أضف فئات',
  empty: 'لم يتم العثور على فئات.',
  technology: 'التكنولوجيا',
  design: 'التصميم',
  business: 'الأعمال',
  marketing: 'التسويق',
  education: 'التعليم',
  health: 'الصحة',
}

const categories = ['technology', 'design', 'business', 'marketing', 'education', 'health'] as const

const categoryLabels: Record<string, string> = {
  technology: t.technology,
  design: t.design,
  business: t.business,
  marketing: t.marketing,
  education: t.education,
  health: t.health,
}

const labelOf = (item: string) => categoryLabels[item] || item

const itemToStringValue = (item: unknown) => labelOf(item as string)

<template>
  {{! Upstream's useComboboxAnchor is the yielded chipsElement. }}
  <Field class="mx-auto w-full max-w-xs">
    <FieldLabel>{{t.label}}</FieldLabel>
    <Combobox
      @multiple={{true}}
      @autoHighlight={{true}}
      @items={{categories}}
      @defaultValue={{array (get categories 0)}}
      @itemToStringValue={{itemToStringValue}}
      as |c|
    >
      <c.Chips>
        <c.Value as |values|>
          {{#each values as |value|}}
            <c.Chip @value={{value}}>
              {{labelOf value}}
            </c.Chip>
          {{/each}}
          <c.ChipsInput placeholder={{t.placeholder}} />
        </c.Value>
      </c.Chips>
      <c.Content @anchor={{c.chipsElement}} dir="rtl" data-lang="ar">
        <c.Empty>{{t.empty}}</c.Empty>
        <c.List as |item|>
          <c.Item @value={{item}}>
            {{labelOf item}}
          </c.Item>
        </c.List>
      </c.Content>
    </Combobox>
  </Field>
</template>

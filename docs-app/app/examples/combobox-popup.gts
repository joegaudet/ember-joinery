import { get } from '@ember/helper'
import { Button, Combobox } from '@ember-joinery/ember'

const countries = [
  { code: '', value: '', continent: '', label: 'Select country' },
  {
    code: 'ar',
    value: 'argentina',
    label: 'Argentina',
    continent: 'South America',
  },
  { code: 'au', value: 'australia', label: 'Australia', continent: 'Oceania' },
  { code: 'br', value: 'brazil', label: 'Brazil', continent: 'South America' },
  { code: 'ca', value: 'canada', label: 'Canada', continent: 'North America' },
  { code: 'cn', value: 'china', label: 'China', continent: 'Asia' },
  {
    code: 'co',
    value: 'colombia',
    label: 'Colombia',
    continent: 'South America',
  },
  { code: 'eg', value: 'egypt', label: 'Egypt', continent: 'Africa' },
  { code: 'fr', value: 'france', label: 'France', continent: 'Europe' },
  { code: 'de', value: 'germany', label: 'Germany', continent: 'Europe' },
  { code: 'it', value: 'italy', label: 'Italy', continent: 'Europe' },
  { code: 'jp', value: 'japan', label: 'Japan', continent: 'Asia' },
  { code: 'ke', value: 'kenya', label: 'Kenya', continent: 'Africa' },
  { code: 'mx', value: 'mexico', label: 'Mexico', continent: 'North America' },
  {
    code: 'nz',
    value: 'new-zealand',
    label: 'New Zealand',
    continent: 'Oceania',
  },
  { code: 'ng', value: 'nigeria', label: 'Nigeria', continent: 'Africa' },
  {
    code: 'za',
    value: 'south-africa',
    label: 'South Africa',
    continent: 'Africa',
  },
  { code: 'kr', value: 'south-korea', label: 'South Korea', continent: 'Asia' },
  {
    code: 'gb',
    value: 'united-kingdom',
    label: 'United Kingdom',
    continent: 'Europe',
  },
  {
    code: 'us',
    value: 'united-states',
    label: 'United States',
    continent: 'North America',
  },
]

<template>
  {{!
    Upstream renders its trigger as this Button (`render`), and the trigger draws the chevron:
    a Button of your own takes the trigger modifier, and draws it with TriggerIcon. The trigger
    is a combobox, which its text doesn't name, so it is named with aria-label.
  }}
  <Combobox @items={{countries}} @defaultValue={{get countries 0}} as |c|>
    <Button
      @variant="outline"
      class="w-64 justify-between font-normal"
      aria-label="Country"
      {{c.trigger}}
    >
      <c.Value />
      <c.TriggerIcon />
    </Button>
    <c.Content>
      <c.Input @showTrigger={{false}} placeholder="Search" />
      <c.Empty>No items found.</c.Empty>
      <c.List as |item|>
        <c.Item @value={{item}}>
          {{item.label}}
        </c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>

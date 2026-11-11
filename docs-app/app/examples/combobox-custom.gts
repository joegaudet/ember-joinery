import { Combobox, Item } from '@ember-joinery/ember'

interface Country {
  code: string
  value: string
  label: string
  continent: string
}

const countries: Country[] = [
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

const items = countries.filter(country => country.code !== '')

const itemToStringValue = (country: unknown) => (country as Country).label

<template>
  <Combobox @items={{items}} @itemToStringValue={{itemToStringValue}} as |c|>
    <c.Input placeholder="Search countries..." />
    <c.Content>
      <c.Empty>No countries found.</c.Empty>
      <c.List as |country|>
        <c.Item @value={{country}}>
          <Item @size="xs" class="p-0" as |i|>
            <i.Content>
              <i.Title class="whitespace-nowrap">
                {{country.label}}
              </i.Title>
              <i.Description>
                {{country.continent}}
                ({{country.code}})
              </i.Description>
            </i.Content>
          </Item>
        </c.Item>
      </c.List>
    </c.Content>
  </Combobox>
</template>

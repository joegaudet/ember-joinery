import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Select } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  selectFruit: 'اختر فاكهة',
  fruits: 'الفواكه',
  apple: 'تفاح',
  banana: 'موز',
  blueberry: 'توت أزرق',
  grapes: 'عنب',
  pineapple: 'أناناس',
  vegetables: 'الخضروات',
  carrot: 'جزر',
  broccoli: 'بروكلي',
  spinach: 'سبانخ',
}

const fruits = [
  { label: t.apple, value: 'apple' },
  { label: t.banana, value: 'banana' },
  { label: t.blueberry, value: 'blueberry' },
  { label: t.grapes, value: 'grapes' },
  { label: t.pineapple, value: 'pineapple' },
]

const vegetables = [
  { label: t.carrot, value: 'carrot' },
  { label: t.broccoli, value: 'broccoli' },
  { label: t.spinach, value: 'spinach' },
]

export default class SelectRtl extends Component {
  @tracked selectedFruit = ''

  setSelectedFruit = (value: string) => (this.selectedFruit = value)

  <template>
    {{! Named with aria-label: a combobox isn't named by its text, and upstream's has no label. }}
    <Select @value={{this.selectedFruit}} @onValueChange={{this.setSelectedFruit}} as |s|>
      <s.Trigger class="w-32" dir="rtl" aria-label={{t.fruits}}>
        <s.Value @placeholder={{t.selectFruit}} />
      </s.Trigger>
      <s.Content dir="rtl" data-lang="ar">
        <s.Group>
          <s.Label>{{t.fruits}}</s.Label>
          {{#each fruits as |item|}}
            <s.Item @value={{item.value}}>
              {{item.label}}
            </s.Item>
          {{/each}}
        </s.Group>
        <s.Separator />
        <s.Group>
          <s.Label>{{t.vegetables}}</s.Label>
          {{#each vegetables as |item|}}
            <s.Item @value={{item.value}}>
              {{item.label}}
            </s.Item>
          {{/each}}
        </s.Group>
      </s.Content>
    </Select>
  </template>
}

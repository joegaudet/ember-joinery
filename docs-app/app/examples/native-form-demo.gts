import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { NativeForm, type NativeFormData } from '@ember-joinery/primitives/native-form'

export default class NativeFormDemo extends Component {
  @tracked data: NativeFormData = { firstName: 'Gwen' }

  update = (data: NativeFormData) => (this.data = data)

  get json(): string {
    return JSON.stringify(this.data, null, 2)
  }

  <template>
    {{!
      ember-primitives' demo: no listener on any input, only their first values. Every change
      hands over the whole form's data.
    }}
    <div class="grid w-full max-w-md grid-cols-2 gap-4 text-sm">
      <NativeForm class="flex flex-col gap-4" @onChange={{this.update}}>
        <label class="flex flex-col gap-1">
          First Name
          <input class="rounded border px-2 py-1" name="firstName" value="Gwen" />
        </label>
        <fieldset class="flex flex-col gap-2">
          <legend>Travel to a universe</legend>
          <label class="flex gap-2"><input name="universe" type="radio" value="65" /> 65</label>
          <label class="flex gap-2"><input name="universe" type="radio" value="616" /> 616</label>
        </fieldset>
      </NativeForm>
      <pre class="overflow-hidden text-xs whitespace-pre-wrap">{{this.json}}</pre>
    </div>
  </template>
}

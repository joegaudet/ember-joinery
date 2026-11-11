import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { Form, type ErrorMap } from '@ember-formwright/ember'
import { Button, Dialog, FieldGroup, asButton } from '@ember-joinery/ember'

class Profile {
  @tracked name = 'Pedro Duarte'
  @tracked username = '@peduarte'
}

const validate = (profile: Profile): ErrorMap =>
  profile.name.trim() ? {} : { name: ['Enter your name.'] }

/*
 * Upstream's dialog-demo, its fields a Formwright form: the form's harness is declared inside
 * the dialog's with `@form` (see the Test tab), which finds it in the dialog's top layer.
 */
export default class FormwrightDialog extends Component {
  model = new Profile()
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)
  save = () => (this.open = false)

  <template>
    <Dialog @name="edit-profile" @open={{this.open}} @onOpenChange={{this.setOpen}} as |d|>
      <Button @variant="outline" {{d.trigger}}>Edit Profile</Button>
      <d.Content class="sm:max-w-sm">
        <Form
          @model={{this.model}}
          @name="profile"
          @validator={{validate}}
          @onSubmit={{this.save}}
          class="grid gap-4"
          as |f|
        >
          <d.Header>
            <d.Title>Edit profile</d.Title>
            <d.Description>
              Make changes to your profile here. Click save when you're done.
            </d.Description>
          </d.Header>
          <FieldGroup>
            <f.Field @for="name" @label="Name" />
            <f.Field @for="username" @label="Username" />
          </FieldGroup>
          <d.Footer>
            <Button @variant="outline" {{d.close}}>Cancel</Button>
            <f.Submit {{asButton name="save"}}>Save changes</f.Submit>
          </d.Footer>
        </Form>
      </d.Content>
    </Dialog>
  </template>
}

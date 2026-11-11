import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { ChevronDown } from 'lucide'
import { Bubble, Button, Collapsible, Icon } from '@ember-joinery/ember'

const text = `The accessibility review found two focus states that were visually too subtle in dark mode.

I checked the dialog, menu, and drawer paths because each one renders focusable controls inside a layered surface.

The dialog and drawer are fine. The menu needs the hover and focus tokens split so keyboard focus stays visible when the pointer is not involved.

I also recommend keeping the change in the style file instead of the primitive so the other themes can choose their own focus treatment later.`

const previewLength = 180

export default class BubbleCollapsible extends Component {
  @tracked open = false

  setOpen = (open: boolean) => (this.open = open)

  isLong = text.length > previewLength
  preview = `${text.slice(0, previewLength)}...`

  get shown(): string {
    return this.open || !this.isLong ? text : this.preview
  }

  <template>
    <div class="flex w-full max-w-sm flex-col gap-8 py-12">
      <Bubble @variant="muted" as |b|>
        <b.Content>How can I help you today?</b.Content>
      </Bubble>

      <Bubble @variant="muted" @align="end" as |b|>
        {{! Upstream puts whitespace-pre-line on the bubble's content, and its JSX has no
            whitespace between the parts; Joinery's templates do, which pre-line would show as
            blank lines, so the class is on the text alone. Upstream's text is a plain div
            beside the trigger, whose aria-controls then names no element, which fails the audit
            once it is open: here the text is the collapsible's content, kept shown while closed
            (@forceMount). }}
        <b.Content>
          <Collapsible @open={{this.open}} @onOpenChange={{this.setOpen}} as |c|>
            <c.Content @forceMount={{true}}>
              <div class="whitespace-pre-line">{{this.shown}}</div>
            </c.Content>
            {{#if this.isLong}}
              <Button @variant="link" class="gap-1 p-0 text-muted-foreground" {{c.trigger}}>
                {{if this.open "Show less" "Show more"}}
                <Icon
                  @icon={{ChevronDown}}
                  data-icon="inline-end"
                  class="group-data-open/button:rotate-180"
                />
              </Button>
            {{/if}}
          </Collapsible>
        </b.Content>
      </Bubble>
    </div>
  </template>
}

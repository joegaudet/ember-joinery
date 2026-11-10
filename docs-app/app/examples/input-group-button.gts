import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import { waitForPromise } from '@ember/test-waiters'
import { Check, Copy, Info, Star } from 'lucide'
import { Icon, InputGroup, Popover } from '@ember-joinery/ember'

/** How long the copy button shows its check, as upstream's `useCopyToClipboard`. */
const COPIED_FOR = 2000

export default class InputGroupButtonExample extends Component {
  @tracked isCopied = false
  @tracked isFavorite = false

  #timer?: ReturnType<typeof setTimeout>

  /** Upstream's `useCopyToClipboard`: a refused copy leaves the button as it was. */
  copyToClipboard = (value: string): void => {
    void waitForPromise(
      Promise.resolve()
        .then(() => navigator.clipboard.writeText(value))
        .then(() => {
          if (this.isDestroying) return
          this.isCopied = true
          clearTimeout(this.#timer)
          this.#timer = setTimeout(() => {
            if (!this.isDestroying) this.isCopied = false
          }, COPIED_FOR)
        })
        .catch(() => undefined),
    )
  }

  copy = () => this.copyToClipboard('https://x.com/shadcn')

  toggleFavorite = () => (this.isFavorite = !this.isFavorite)

  <template>
    {{!
      Upstream's draws Tabler's check, copy, info-circle and star; Joinery's icons are
      lucide's. Upstream's info and star buttons and its https:// input are unnamed; these
      have aria-label, so the audit passes. The info addon is the popover's trigger, as
      upstream's PopoverTrigger asChild makes it; its block param isn't `p`, which would turn
      the content's paragraphs into calls to it.
    }}
    <div class="grid w-full max-w-sm gap-6">
      <InputGroup as |g|>
        <g.Input placeholder="https://x.com/shadcn" readonly />
        <g.Addon @align="inline-end">
          <g.Button aria-label="Copy" title="Copy" @size="icon-xs" {{on "click" this.copy}}>
            {{#if this.isCopied}}
              <Icon @icon={{Check}} />
            {{else}}
              <Icon @icon={{Copy}} />
            {{/if}}
          </g.Button>
        </g.Addon>
      </InputGroup>
      <InputGroup class="[--radius:9999px]" as |g|>
        <Popover as |popover|>
          <g.Addon {{popover.trigger}}>
            <g.Button @variant="secondary" @size="icon-xs" aria-label="Info">
              <Icon @icon={{Info}} />
            </g.Button>
          </g.Addon>
          <popover.Content @align="start" class="flex flex-col gap-1 rounded-xl text-sm">
            <p class="font-medium">Your connection is not secure.</p>
            <p>You should not enter any sensitive information on this site.</p>
          </popover.Content>
        </Popover>
        <g.Addon class="pl-1.5 text-muted-foreground">
          https://
        </g.Addon>
        <g.Input id="input-secure-19" aria-label="URL" />
        <g.Addon @align="inline-end">
          <g.Button @size="icon-xs" aria-label="Favorite" {{on "click" this.toggleFavorite}}>
            <Icon
              @icon={{Star}}
              data-favorite={{if this.isFavorite "true" "false"}}
              class="data-[favorite=true]:fill-blue-600 data-[favorite=true]:stroke-blue-600"
            />
          </g.Button>
        </g.Addon>
      </InputGroup>
      <InputGroup as |g|>
        <g.Input placeholder="Type to search..." />
        <g.Addon @align="inline-end">
          <g.Button @variant="secondary">Search</g.Button>
        </g.Addon>
      </InputGroup>
    </div>
  </template>
}

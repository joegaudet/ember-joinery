import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { on } from '@ember/modifier'
import type Owner from '@ember/owner'
import { ArrowUp, MessageCircleDashed, RotateCw } from 'lucide'
import { Button, Card, Empty, Icon, MessageScrollerProvider, Select } from '@ember-joinery/ember'
import MessageAnimated from './chat/message-animated.gts'
import { MESSAGE_ANIMATIONS, type MessageAnimationId } from './chat/message-animations.ts'
import { createChat } from './chat/scripted-chat.ts'

const chat = createChat()
  .user('Can user messages pop in like iMessage without breaking anchoring?')
  .sleep(1000)
  .assistant(
    'Yes. Animate the user row with transform and opacity, and let the assistant response stream normally below it.\n\nThat keeps the row measurement predictable while still giving the newly sent bubble a more tactile entrance.',
  )
  .user('What makes the animation feel more like iMessage?')
  .sleep(1000)
  .assistant(
    'Use a quick spring from the trailing edge: a little scale, a small upward move, and no layout animation.\n\nThe bubble feels tactile, but the measured row stays predictable, so anchoring and auto-scroll do not have to fight a changing layout.',
  )
  .user('Can I switch between presets while testing the same thread?')
  .sleep(1000)
  .assistant(
    'Yes. Keep the conversation in place while you change the preset, then send the next message to compare the new entrance against the same context.\n\nThat makes it easier to judge the difference between a subtle fade, a snappy pop, and a more dramatic 3D tilt without rebuilding the scenario each time.',
  )
const initialMessages = chat.get(0)
const animations = Object.values(MESSAGE_ANIMATIONS)

export default class MessageScrollerAnimation extends Component {
  session = chat.session({ messages: initialMessages, delayMs: 15 })
  @tracked presetId: MessageAnimationId = 'fade'

  constructor(owner: Owner, args: object) {
    super(owner, args)
    registerDestructor(this, this.session.stop)
  }

  get preset() {
    return MESSAGE_ANIMATIONS[this.presetId]
  }

  get cannotReset(): boolean {
    return this.session.messages.length === 0 || this.session.isBusy
  }

  get cannotSend(): boolean {
    return !this.session.nextMessage || this.session.isBusy
  }

  setPreset = (value: string) => {
    this.presetId = value as MessageAnimationId
  }

  reset = () => this.session.setMessages(initialMessages)

  send = () => {
    const next = this.session.nextMessage
    if (!next || this.session.isBusy) return
    this.session.sendMessage(next)
  }

  <template>
    <div class="relative flex flex-col gap-4">
      <Card class="mx-auto h-140 w-full max-w-sm gap-0" as |card|>
        <card.Header class="border-b">
          <card.Title>Animation</card.Title>
          <card.Description>
            Choose how user messages are animated when they are added to the conversation.
          </card.Description>
          <card.Action class="flex items-center gap-2">
            <Button
              type="button"
              @variant="outline"
              @size="icon"
              aria-label="Reset animated messages"
              disabled={{this.cannotReset}}
              {{on "click" this.reset}}
            >
              <Icon @icon={{RotateCw}} />
            </Button>
          </card.Action>
        </card.Header>
        <card.Content class="min-h-0 flex-1 overflow-hidden p-0">
          {{#if this.session.messages.length}}
            <MessageScrollerProvider as |s|>
              <s.Root>
                <s.Viewport>
                  <s.Content
                    aria-busy={{if this.session.isBusy "true" "false"}}
                    class="p-(--card-spacing)"
                  >
                    {{#each this.session.messages key="id" as |message|}}
                      <MessageAnimated
                        @message={{message}}
                        @animationPreset={{this.preset}}
                        @userVariant="muted"
                        @assistantVariant="ghost"
                      />
                    {{/each}}
                  </s.Content>
                </s.Viewport>
                <s.Button />
              </s.Root>
            </MessageScrollerProvider>
          {{else}}
            <Empty class="h-full" as |e|>
              <e.Header>
                <e.Media @variant="icon">
                  <Icon @icon={{MessageCircleDashed}} />
                </e.Media>
                <e.Title>No Messages Yet</e.Title>
                <e.Description>
                  Click the button below to send the first message.
                </e.Description>
              </e.Header>
            </Empty>
          {{/if}}
        </card.Content>
        <card.Footer class="border-t">
          <Select @value={{this.presetId}} @onValueChange={{this.setPreset}} as |select|>
            <select.Trigger aria-label="Animation preset">
              <select.Value>{{this.preset.name}}</select.Value>
            </select.Trigger>
            <select.Content @align="start" @side="top" @position="popper">
              <select.Group>
                {{#each animations as |animation|}}
                  <select.Item @value={{animation.id}}>{{animation.name}}</select.Item>
                {{/each}}
              </select.Group>
            </select.Content>
          </Select>
          <Button
            type="button"
            @size="icon"
            class="ml-auto"
            disabled={{this.cannotSend}}
            {{on "click" this.send}}
          >
            <Icon @icon={{ArrowUp}} />
            <span class="sr-only">Send Message</span>
          </Button>
        </card.Footer>
      </Card>
      <div class="mx-auto max-w-sm px-0.5 text-center text-xs text-balance text-muted-foreground">
        Select an animation then click send to see it in action.
      </div>
    </div>
  </template>
}

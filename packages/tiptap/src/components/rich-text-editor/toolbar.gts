import Component from '@glimmer/component'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import type { ChainedCommands, Editor } from '@tiptap/core'
import { ChevronDown } from 'lucide'
import {
  Button,
  DropdownMenu,
  Icon,
  Kbd,
  KbdGroup,
  Separator,
  ToggleGroup,
  Tooltip,
} from '@ember-joinery/ember'
import { part } from '@ember-joinery/primitives/part'
import { RovingFocus } from '@ember-joinery/primitives/roving-focus'
import {
  GROUPS,
  TOOLS,
  ariaShortcut,
  blockTypeShortcut,
  currentBlockType,
  setBlockType,
  shortcutKeys,
  type BlockType,
  type HeadingLevel,
  type RichTextLabels,
  type RichTextTool,
  type ToolSpec,
} from './tools.ts'
import { translate } from '@ember-joinery/primitives/i18n'
import { messages } from '../../messages.ts'

/** A control the toolbar shows, with what it needs to draw itself. */
interface ShownTool {
  spec: ToolSpec
  label: string
  /** Its shortcut's keys, one `<Kbd>` each. */
  keys: string[]
  /** Its shortcut, as `aria-keyshortcuts` writes it. */
  ariaKeys: string
}

/** A group of the toolbar: the text style menu, toggles, or the history buttons. */
type Group =
  | { kind: 'block-type' }
  | { kind: 'toggles'; name: string; tools: ShownTool[] }
  | { kind: 'actions'; name: string; tools: ShownTool[] }

interface BlockTypeOption {
  value: BlockType
  label: string
  keys: string
}

export interface RichTextToolbarSignature {
  Args: {
    editor: Editor
    /** Bumped on every transaction, so what the toolbar reads from the editor re-renders. */
    revision: number
    /** The controls to show. */
    tools: ReadonlySet<RichTextTool>
    headingLevels: readonly HeadingLevel[]
    labels: RichTextLabels
    /** The document's id, which the toolbar controls (`aria-controls`). */
    contentId: string
    /** Whether every control is disabled (the editor is). */
    disabled: boolean
    /** Runs a command; focus stays in the toolbar when it is there. */
    run: (command: (chain: ChainedCommands) => ChainedCommands) => void
    /** Sends focus back to the document. */
    focusDocument: () => void
  }
  Element: HTMLDivElement
}

const isToggleGroup = (group: Group): group is Extract<Group, { kind: 'toggles' }> =>
  group.kind === 'toggles'
const isActionGroup = (group: Group): group is Extract<Group, { kind: 'actions' }> =>
  group.kind === 'actions'
const isBlockTypeGroup = (group: Group): boolean => group.kind === 'block-type'

/**
 * The editor's toolbar, WAI-ARIA's toolbar pattern: one tab stop, the arrow keys (flipped right
 * to left), Home and End moving between its controls. The text style is a Dropdown Menu, marks
 * and blocks are Toggle Group items, and undo and redo are Buttons, each with a Tooltip naming
 * it and its shortcut, and Separators between the groups.
 */
export default class RichTextToolbar extends Component<RichTextToolbarSignature> {
  roving = new RovingFocus({ orientation: () => 'horizontal', loop: () => true })

  /** Whether the last close of the text style menu followed a choice. */
  #chose = false

  get groups(): Group[] {
    const { tools, labels } = this.args
    const shown = (names: readonly RichTextTool[]): ShownTool[] =>
      names
        .filter(name => name !== 'block-type' && tools.has(name))
        .map(name => {
          const spec = TOOLS[name as Exclude<RichTextTool, 'block-type'>]
          return {
            spec,
            label: labels[spec.name],
            keys: shortcutKeys(spec.shortcut),
            ariaKeys: ariaShortcut(spec.shortcut),
          }
        })
    const groups: Group[] = []
    if (tools.has('block-type')) groups.push({ kind: 'block-type' })
    const marks = shown(GROUPS.marks)
    if (marks.length) groups.push({ kind: 'toggles', name: 'marks', tools: marks })
    const blocks = shown(GROUPS.blocks)
    if (blocks.length) groups.push({ kind: 'toggles', name: 'blocks', tools: blocks })
    const history = shown(GROUPS.history)
    if (history.length) groups.push({ kind: 'actions', name: 'history', tools: history })
    return groups
  }

  /** The toggles of a group that are on at the cursor. */
  pressed = (group: { tools: ShownTool[] }, _revision: number): string[] =>
    group.tools.filter(tool => tool.spec.isActive(this.args.editor)).map(tool => tool.spec.name)

  /** A toggle group's new value: run each toggle whose state the press changed. */
  toggle = (group: { tools: ShownTool[] }, value: string[]): void => {
    const before = this.pressed(group, this.args.revision)
    const changed = group.tools.filter(
      tool => before.includes(tool.spec.name) !== value.includes(tool.spec.name),
    )
    for (const tool of changed) this.args.run(tool.spec.run)
  }

  canRun = (tool: ShownTool, _revision: number): boolean => tool.spec.can(this.args.editor)

  runAction = (tool: ShownTool): void => {
    if (this.args.disabled || !tool.spec.can(this.args.editor)) return
    this.args.run(tool.spec.run)
  }

  get blockTypes(): BlockTypeOption[] {
    const { labels, headingLevels } = this.args
    const option = (value: BlockType, label: string): BlockTypeOption => ({
      value,
      label,
      keys: shortcutKeys(blockTypeShortcut(value)).join(''),
    })
    return [
      option('paragraph', labels.paragraph),
      ...headingLevels.map(level => option(`heading-${level}`, labels.heading(level))),
    ]
  }

  /** The text style at the cursor; `''` in a code block, which has none. */
  blockType = (_revision: number): string => currentBlockType(this.args.editor) ?? ''

  /** What the menu's trigger shows: the style at the cursor, or the menu's name in a code block. */
  blockTypeText = (_revision: number): string => {
    const current = currentBlockType(this.args.editor)
    const option = this.blockTypes.find(type => type.value === current)
    return option?.label ?? (current ? this.headingLabel(current) : this.args.labels.blockType)
  }

  /** The trigger's name: what it is for, then what it shows, so its text is in its name. */
  blockTypeName = (revision: number): string => {
    const text = this.blockTypeText(revision)
    const name = this.args.labels.blockType
    return text === name ? name : translate(this, messages.blockTypeName, { name, style: text })
  }

  headingLabel(type: BlockType): string {
    if (type === 'paragraph') return this.args.labels.paragraph
    return this.args.labels.heading(Number(type.slice('heading-'.length)) as HeadingLevel)
  }

  chooseBlockType = (value: string): void => {
    this.#chose = true
    this.args.run(chain => setBlockType(chain, value as BlockType))
  }

  /** After a choice, focus goes back to the document, where the style was applied. */
  afterBlockType = (event: Event): void => {
    if (!this.#chose) return
    this.#chose = false
    event.preventDefault()
    this.args.focusDocument()
  }

  /** A press on a control keeps the document's selection: focus stays where it was. */
  keepSelection = (event: MouseEvent): void => event.preventDefault()

  /**
   * Keeps a toggle's own `data-state` (`on`, `off`) on it while its tooltip opens and closes:
   * the tooltip's trigger sets its own `data-state` on the same element, and the toggle's
   * pressed look, and Radix's toggle contract, read this one. It reads the tooltip's state, so
   * it runs after the trigger's part each time that changes, and wins. The part is the
   * tooltip's (`trigger`), whose root is around it.
   */
  pinToggle = part<HTMLElement, { pressed: boolean; tooltip: string }>(named => {
    void named.tooltip
    return {
      attributes: {
        'data-state': named.pressed ? 'on' : 'off',
        'data-test-jn-part': 'trigger',
      },
    }
  })

  <template>
    <div
      role="toolbar"
      aria-label={{@labels.toolbar}}
      aria-controls={{@contentId}}
      aria-orientation="horizontal"
      class="jn-rich-text-editor-toolbar jn-input-group-addon jn-input-group-addon-align-block-start border-b"
      data-slot="rich-text-editor-toolbar"
      data-align="block-start"
      data-test-jn-part="toolbar"
      ...attributes
      {{this.roving.group}}
    >
      {{#each this.groups as |group index|}}
        {{#if index}}
          <Separator
            @orientation="vertical"
            class="jn-rich-text-editor-separator"
            data-test-jn-part="separator"
          />
        {{/if}}
        {{#if (isBlockTypeGroup group)}}
          <DropdownMenu as |m|>
            <Button
              @variant="ghost"
              @size="sm"
              class="jn-rich-text-editor-block-type"
              aria-label={{this.blockTypeName @revision}}
              disabled={{@disabled}}
              data-test-jn-value="block-type"
              {{m.trigger}}
              {{this.roving.item tabStopId="block-type" focusable=(not @disabled)}}
            >
              {{this.blockTypeText @revision}}
              <Icon @icon={{ChevronDown}} data-icon="inline-end" />
            </Button>
            <m.Content @align="start" @onCloseAutoFocus={{this.afterBlockType}}>
              <m.RadioGroup
                @value={{this.blockType @revision}}
                @onValueChange={{this.chooseBlockType}}
                as |g|
              >
                {{#each this.blockTypes as |type|}}
                  <g.Item @value={{type.value}}>
                    {{type.label}}
                    <m.Shortcut>{{type.keys}}</m.Shortcut>
                  </g.Item>
                {{/each}}
              </m.RadioGroup>
            </m.Content>
          </DropdownMenu>
        {{else if (isToggleGroup group)}}
          <ToggleGroup
            @type="multiple"
            @size="sm"
            @spacing={{1}}
            @rovingFocus={{false}}
            @disabled={{@disabled}}
            @value={{this.pressed group @revision}}
            @onValueChange={{fn this.toggle group}}
            @name={{group.name}}
            class="jn-rich-text-editor-group"
            as |g|
          >
            {{#each group.tools as |tool|}}
              <Tooltip @name={{tool.spec.name}} as |t|>
                <button
                  type="button"
                  aria-label={{tool.label}}
                  aria-keyshortcuts={{tool.ariaKeys}}
                  {{t.trigger}}
                  {{g.item value=tool.spec.name}}
                  {{this.pinToggle pressed=(g.isPressed tool.spec.name) tooltip=t.state}}
                  {{this.roving.item tabStopId=tool.spec.name focusable=(not @disabled)}}
                  {{on "mousedown" this.keepSelection}}
                >
                  <Icon @icon={{tool.spec.icon}} />
                </button>
                <t.Content>
                  {{tool.label}}
                  <KbdGroup>
                    {{#each tool.keys as |key|}}<Kbd>{{key}}</Kbd>{{/each}}
                  </KbdGroup>
                </t.Content>
              </Tooltip>
            {{/each}}
          </ToggleGroup>
        {{else if (isActionGroup group)}}
          <div
            role="group"
            class="jn-rich-text-editor-group"
            data-slot="rich-text-editor-group"
            data-test-jn-part="group"
            data-test-jn-value={{group.name}}
          >
            {{#each group.tools as |tool|}}
              <Tooltip @name={{tool.spec.name}} as |t|>
                <Button
                  @variant="ghost"
                  @size="icon-sm"
                  aria-label={{tool.label}}
                  aria-keyshortcuts={{tool.ariaKeys}}
                  aria-disabled={{unless (this.canRun tool @revision) "true"}}
                  disabled={{@disabled}}
                  data-test-jn-value={{tool.spec.name}}
                  {{t.trigger}}
                  {{this.roving.item tabStopId=tool.spec.name focusable=(not @disabled)}}
                  {{on "mousedown" this.keepSelection}}
                  {{on "click" (fn this.runAction tool)}}
                >
                  <Icon @icon={{tool.spec.icon}} />
                </Button>
                <t.Content>
                  {{tool.label}}
                  <KbdGroup>
                    {{#each tool.keys as |key|}}<Kbd>{{key}}</Kbd>{{/each}}
                  </KbdGroup>
                </t.Content>
              </Tooltip>
            {{/each}}
          </div>
        {{/if}}
      {{/each}}
    </div>
  </template>
}

function not(value: unknown): boolean {
  return !value
}

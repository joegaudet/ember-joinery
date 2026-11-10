import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import type { WithBoundArgs } from '@glint/template'
import { Check, Search } from 'lucide'
import type { TagName } from '@ember-joinery/primitives/as'
import {
  Command as CommandPrimitive,
  hotkey,
  type CommandArgs,
  type CommandGroupArgs,
  type CommandItemArgs,
  type CommandYield as CommandPrimitiveYield,
} from '@ember-joinery/primitives/command'
import { controllable, type ControllableArgs } from '@ember-joinery/primitives/controllable-state'
import type { PartModifier } from '@ember-joinery/primitives/part'
import { visuallyHidden } from '@ember-joinery/primitives/visually-hidden'
import Dialog from './dialog.gts'
import Icon, { type IconNode } from './icon.gts'

/** A press on the search icon's addon focuses the input, as upstream's InputGroupAddon does. */
function focusInput(event: MouseEvent): void {
  if ((event.target as Element | null)?.closest('button')) return
  const addon = event.currentTarget as HTMLElement
  addon.parentElement?.querySelector('input')?.focus()
}

export interface CommandInputSignature {
  Args: {
    /** The search icon: one from `lucide`. Default lucide's `search` (`SearchIcon`). */
    searchIcon?: IconNode
    /** @internal The headless input, bound by `<Command>`. */
    base: CommandPrimitiveYield['Input']
  }
  /** A native `<input type="text">`: give it a `placeholder`. */
  Element: HTMLInputElement
}

/**
 * The search box, with its icon, in upstream's InputGroup: a wrapper, the group, the input and
 * an addon at its start that holds the icon. It renders InputGroup's markup and classes rather
 * than `<InputGroup>`, whose `data-test-jn="input-group"` root would make the input that
 * group's part, not the command's, so `CommandHarness` couldn't reach it.
 */
const CommandInput: TOC<CommandInputSignature> = <template>
  <div class="jn-command-input-wrapper" data-slot="command-input-wrapper">
    <div
      class="jn-input-group jn-command-input-group group/input-group"
      data-slot="input-group"
      role="group"
    >
      <@base class="jn-command-input" data-slot="command-input" ...attributes />
      <div
        class="jn-input-group-addon jn-input-group-addon-align-inline-start"
        role="group"
        data-slot="input-group-addon"
        data-align="inline-start"
        {{on "click" focusInput}}
      >
        <Icon @icon={{if @searchIcon @searchIcon Search}} class="jn-command-input-icon" />
      </div>
    </div>
  </div>
</template>

export interface CommandListSignature {
  Args: {
    /** Its name for screen readers. Default `Suggestions`. */
    label?: string
    /** The tag to render. Default `div`. */
    as?: TagName
    /** @internal Bound by `<Command>`. */
    base: CommandPrimitiveYield['List']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** The list the items show in, scrolling past `max-h-72`. */
const CommandList: TOC<CommandListSignature> = <template>
  <@base
    @label={{@label}}
    @as={{@as}}
    class="jn-command-list"
    data-slot="command-list"
    ...attributes
  >{{yield}}</@base>
</template>

export interface CommandEmptySignature {
  Args: {
    /** @internal Bound by `<Command>`. */
    base: CommandPrimitiveYield['Empty']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** What shows when nothing matches the search. */
const CommandEmpty: TOC<CommandEmptySignature> = <template>
  <@base class="jn-command-empty" data-slot="command-empty" ...attributes>{{yield}}</@base>
</template>

export interface CommandGroupSignature {
  Args: CommandGroupArgs & {
    /** @internal Bound by `<Command>`. */
    base: CommandPrimitiveYield['Group']
  }
  Blocks: { default: [] }
  Element: HTMLDivElement
}

/** Items under a heading, hidden while the search leaves it nothing. */
const CommandGroup: TOC<CommandGroupSignature> = <template>
  <@base
    @heading={{@heading}}
    @value={{@value}}
    @forceMount={{@forceMount}}
    class="jn-command-group"
    data-slot="command-group"
    ...attributes
  >{{yield}}</@base>
</template>

export interface CommandSeparatorSignature {
  Args: {
    /** Show it during a search too. Default: only while there is none. */
    alwaysRender?: boolean
    /** @internal Bound by `<Command>`. */
    base: CommandPrimitiveYield['Separator']
  }
  Element: HTMLDivElement
}

/** A line between groups, shown while there is no search. */
const CommandSeparator: TOC<CommandSeparatorSignature> = <template>
  <@base
    @alwaysRender={{@alwaysRender}}
    class="jn-command-separator"
    data-slot="command-separator"
    ...attributes
  />
</template>

export interface CommandItemSignature {
  Args: CommandItemArgs & {
    /** The tag to render. Default `div`; `a` (with an `href`) for an item that is a link. */
    as?: TagName
    /**
     * The check at its end, which shows when the item has `data-checked="true"` (and hides
     * when it has a Shortcut): one from `lucide`. Default lucide's `check` (`CheckIcon`).
     */
    checkIcon?: IconNode
    /** @internal Bound by `<Command>`. */
    base: CommandPrimitiveYield['Item']
  }
  Blocks: { default: [] }
  /** A `<div>`, or the tag `@as` names: an `<a>` for a link. */
  Element: HTMLDivElement | HTMLAnchorElement
}

/** An option: its icon and text, a Shortcut if it has one, and a check at its end. */
const CommandItem: TOC<CommandItemSignature> = <template>
  <@base
    @value={{@value}}
    @keywords={{@keywords}}
    @disabled={{@disabled}}
    @onSelect={{@onSelect}}
    @forceMount={{@forceMount}}
    @as={{@as}}
    class="jn-command-item group/command-item"
    data-slot="command-item"
    ...attributes
  >
    {{yield}}
    <Icon @icon={{if @checkIcon @checkIcon Check}} class="jn-command-item-indicator" />
  </@base>
</template>

export interface CommandShortcutSignature {
  Blocks: { default: [] }
  Element: HTMLSpanElement
}

/** A keyboard shortcut shown at the end of an item: `⌘P`. It is text, not a key binding. */
const CommandShortcut: TOC<CommandShortcutSignature> = <template>
  <span
    class="jn-command-shortcut"
    data-slot="command-shortcut"
    data-test-jn-part="shortcut"
    ...attributes
  >{{yield}}</span>
</template>

/** What `<Command>` yields. */
export interface CommandYield {
  /** The search box, with its icon. */
  Input: WithBoundArgs<typeof CommandInput, 'base'>
  /** The list of items. */
  List: WithBoundArgs<typeof CommandList, 'base'>
  /** What shows when nothing matches. */
  Empty: WithBoundArgs<typeof CommandEmpty, 'base'>
  /** Items under a heading: `<c.Group @heading="Suggestions">`. */
  Group: WithBoundArgs<typeof CommandGroup, 'base'>
  /** An item: `<c.Item @onSelect={{this.run}}>Calendar</c.Item>`. */
  Item: WithBoundArgs<typeof CommandItem, 'base'>
  /** A line between groups. */
  Separator: WithBoundArgs<typeof CommandSeparator, 'base'>
  /** A shortcut at the end of an item. */
  Shortcut: typeof CommandShortcut
  /** Makes an `<input>` of your own the search box: `<input {{c.input}} />`. */
  input: PartModifier<HTMLInputElement>
  /** The input's text. */
  search: string
  /** Puts text in the input. */
  setSearch: (search: string) => void
  /** The selected item's value, or `''`. */
  value: string
  /** Selects an item by its value. */
  setValue: (value: string) => void
  /** How many items the search shows. */
  count: number
}

export interface CommandSignature {
  Args: CommandArgs & {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [CommandYield] }
  Element: HTMLDivElement
}

/**
 * A command menu for search and quick actions: shadcn's Command, on the primitives' `Command`
 * (cmdk's behaviour). Typing filters and ranks the items; the arrows move the selection and
 * Enter chooses it.
 *
 *   <Command class="max-w-sm rounded-lg border" as |c|>
 *     <c.Input placeholder="Type a command or search..." />
 *     <c.List>
 *       <c.Empty>No results found.</c.Empty>
 *       <c.Group @heading="Suggestions">
 *         <c.Item>Calendar</c.Item>
 *         <c.Item>Search Emoji</c.Item>
 *       </c.Group>
 *       <c.Separator />
 *       <c.Group @heading="Settings">
 *         <c.Item>Profile <c.Shortcut>⌘P</c.Shortcut></c.Item>
 *       </c.Group>
 *     </c.List>
 *   </Command>
 */
const Command: TOC<CommandSignature> = <template>
  <CommandPrimitive
    @label={{@label}}
    @value={{@value}}
    @defaultValue={{@defaultValue}}
    @onValueChange={{@onValueChange}}
    @search={{@search}}
    @defaultSearch={{@defaultSearch}}
    @onSearchChange={{@onSearchChange}}
    @filter={{@filter}}
    @shouldFilter={{@shouldFilter}}
    @loop={{@loop}}
    @disablePointerSelection={{@disablePointerSelection}}
    @vimBindings={{@vimBindings}}
    @onSelect={{@onSelect}}
    @resultsText={{@resultsText}}
    @hotkey={{@hotkey}}
    @onOpen={{@onOpen}}
    @name={{@name}}
    @as={{@as}}
    class="jn-command"
    data-slot="command"
    ...attributes
    as |c|
  >
    {{yield
      (hash
        Input=(component CommandInput base=c.Input)
        List=(component CommandList base=c.List)
        Empty=(component CommandEmpty base=c.Empty)
        Group=(component CommandGroup base=c.Group)
        Item=(component CommandItem base=c.Item)
        Separator=(component CommandSeparator base=c.Separator)
        Shortcut=CommandShortcut
        input=c.input
        search=c.search
        setSearch=c.setSearch
        value=c.value
        setValue=c.setValue
        count=c.count
      )
    }}
  </CommandPrimitive>
</template>

export default Command

// ----- CommandDialog -------------------------------------------------------------------------

/** What `<CommandDialog>` takes. */
export type CommandDialogArgs = ControllableArgs<'open', boolean> & {
  /** Its name for screen readers, visually hidden. Default `Command Palette`. */
  title?: string
  /** Its description, visually hidden. Default `Search for a command to run...`. */
  description?: string
  /** Show the dialog's close button in its corner. Default `false`. */
  showCloseButton?: boolean
  /** That button's name for screen readers. Default `Close`. */
  closeLabel?: string
  /** That button's icon: one from `lucide`. Default lucide's `x`. */
  closeIcon?: IconNode
  /** Whether it is modal. Default `true`. */
  modal?: boolean
  /** A key combination that opens and closes it from anywhere on the page: `"mod+k"`. */
  hotkey?: string
  /** Its name, for `CommandDialogHarness` (`data-test-jn-name`). */
  name?: string
}

/** What `<CommandDialog>` yields, to open and close it from inside. */
export interface CommandDialogYield {
  isOpen: boolean
  open: () => void
  toggle: () => void
  setOpen: (open: boolean) => void
}

export interface CommandDialogSignature {
  Args: CommandDialogArgs
  Blocks: { default: [CommandDialogYield] }
  /** The dialog's content. */
  Element: HTMLDivElement
}

/**
 * A command menu in a dialog: shadcn's CommandDialog, on Joinery's Dialog, with its title and
 * description visually hidden and no close button. Put a `<Command>` in it:
 *
 *   <Button @variant="outline" {{on "click" (fn this.setOpen true)}}>Open Menu</Button>
 *   <CommandDialog @open={{this.open}} @onOpenChange={{this.setOpen}}>
 *     <Command as |c|>…</Command>
 *   </CommandDialog>
 *
 * `@hotkey="mod+k"` opens and closes it from anywhere on the page.
 */
export class CommandDialog extends Component<CommandDialogSignature> {
  openState = controllable(this, 'open', false)

  setOpen = (open: boolean): void => this.openState.set(open)
  toggle = (): void => this.openState.set(open => !open)

  get showCloseButton(): boolean {
    return this.args.showCloseButton ?? false
  }

  <template>
    <Dialog
      @open={{this.openState.value}}
      @onOpenChange={{this.setOpen}}
      @modal={{@modal}}
      @name={{@name}}
      data-test-jn="command-dialog"
      {{hotkey @hotkey this.toggle}}
      as |d|
    >
      <d.Content
        @showCloseButton={{this.showCloseButton}}
        @closeLabel={{@closeLabel}}
        @closeIcon={{@closeIcon}}
        class="jn-command-dialog"
        ...attributes
      >
        <d.Header {{visuallyHidden}}>
          <d.Title>{{if @title @title "Command Palette"}}</d.Title>
          <d.Description>{{if
              @description
              @description
              "Search for a command to run..."
            }}</d.Description>
        </d.Header>
        {{yield (hash isOpen=d.isOpen open=d.open toggle=this.toggle setOpen=this.setOpen)}}
      </d.Content>
    </Dialog>
  </template>
}

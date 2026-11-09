import Component from '@glimmer/component'
import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import { modifier } from 'ember-modifier'
import { As, type TagName } from '../as.gts'
import type { Direction } from '../direction.gts'
import { Consume, Provide } from '../dom-context.gts'
import {
  ResizableGroup,
  ResizablePanelApi,
  type ResizableHandleOptions,
  type ResizableLayoutMap,
  type ResizableLayoutMeta,
  type ResizableOrientation,
  type ResizablePanelOptions,
  type ResizablePanelSize,
} from './state.ts'
import type { PanelSize } from './layout.ts'

/**
 * The box inside a panel that holds its content, as react-resizable-panels' does: it fills the
 * panel and scrolls what doesn't fit, so a panel smaller than its content still lays out. Its
 * style is set through the CSSOM, which a strict Content Security Policy allows.
 */
const panelContent = modifier(
  (element: HTMLElement, [orientation, collapsed]: [ResizableOrientation, boolean]) => {
    element.style.setProperty('flex-grow', '1')
    element.style.setProperty('max-width', '100%')
    element.style.setProperty('max-height', '100%')
    // A collapsed panel shows nothing, so nothing in it scrolls (or takes focus as a scroller).
    element.style.setProperty('overflow', collapsed ? 'hidden' : 'auto')
    element.style.setProperty('touch-action', orientation === 'horizontal' ? 'pan-y' : 'pan-x')
  },
)

export interface ResizablePanelSignature {
  Args: Omit<ResizablePanelOptions, 'api'> & {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: {
    /** The content, given the panel's size and API (`panel.size`, `panel.collapse()`). */
    default: [panel: ResizablePanelApi]
  }
  Element: HTMLElement
}

/**
 * A panel of a `<Resizable>` group (react-resizable-panels' `Panel`): give it its sizes in
 * percent (`@defaultSize="30%"`) or with a unit (`"200px"`, `"10rem"`). It must be a child of
 * the group's element, and it finds its group there. It yields its size and its API:
 *
 *   <ResizablePanel @defaultSize="25%" @collapsible={{true}} @minSize="15%" as |panel|>
 *     <button type="button" {{on "click" panel.collapse}}>Hide</button>
 *   </ResizablePanel>
 */
export class ResizablePanel extends Component<ResizablePanelSignature> {
  api = new ResizablePanelApi()

  <template>
    <Consume @key={{ResizableGroup}} as |context|>
      <As
        @as={{@as}}
        @tag="div"
        id={{@id}}
        data-slot="resizable-panel"
        data-test-jn-part="panel"
        data-test-jn-value={{@id}}
        ...attributes
        {{context.data.panel
          id=@id
          defaultSize=@defaultSize
          minSize=@minSize
          maxSize=@maxSize
          collapsible=@collapsible
          collapsedSize=@collapsedSize
          collapsedThreshold=@collapsedThreshold
          disabled=@disabled
          groupResizeBehavior=@groupResizeBehavior
          onResize=@onResize
          api=this.api
        }}
      >
        <div {{panelContent context.data.orientation this.api.isCollapsed}}>{{yield this.api}}</div>
      </As>
    </Consume>
  </template>
}

export interface ResizableHandleSignature {
  Args: ResizableHandleOptions & {
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The handle between two panels of a `<Resizable>` group (react-resizable-panels'
 * `Separator`): a `role="separator"` that a pointer drags and the arrow keys move, as in APG's
 * window splitter. It resizes the panels either side of it. Name it for what it resizes
 * (`aria-label="Resize the sidebar"`).
 */
export const ResizableHandle: TOC<ResizableHandleSignature> = <template>
  <Consume @key={{ResizableGroup}} as |context|>
    <As
      @as={{@as}}
      @tag="div"
      role="separator"
      tabindex="0"
      data-slot="resizable-handle"
      data-test-jn-part="handle"
      ...attributes
      {{context.data.handle disabled=@disabled disableDoubleClick=@disableDoubleClick}}
    >{{yield}}</As>
  </Consume>
</template>

/** What `<Resizable>` yields. */
export interface ResizableYield {
  /** A panel: `<r.Panel @defaultSize="30%">`, the same as `<ResizablePanel>`. */
  Panel: typeof ResizablePanel
  /** A handle: `<r.Handle />`, the same as `<ResizableHandle>`. */
  Handle: typeof ResizableHandle
  /** A panel, as a modifier on your own element: `<section {{r.panel defaultSize="30%"}}>`. */
  panel: ResizableGroup['panel']
  /** A handle, as a modifier on your own element: `<div {{r.handle}}>`. */
  handle: ResizableGroup['handle']
  /** The panels' sizes in percent, in order. */
  layout: readonly number[]
  /** The sizes by panel id. */
  getLayout: () => ResizableLayoutMap
  /** Sets the sizes, in order or by panel id; constraints still apply. */
  setLayout: (layout: readonly number[] | ResizableLayoutMap) => ResizableLayoutMap
}

export interface ResizableSignature {
  Args: {
    /** Panels side by side (`horizontal`, the default) or stacked (`vertical`). */
    orientation?: ResizableOrientation
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** Whether nothing in the group can be resized. */
    disabled?: boolean
    /** Whether to leave the cursor alone, instead of showing a resize cursor. */
    disableCursor?: boolean
    /** The first sizes in percent: one per panel in order, or by panel `@id`. For a saved layout. */
    defaultLayout?: readonly number[] | ResizableLayoutMap
    /** Called while the layout changes (on every pointer move), with the sizes in order and by id. */
    onLayoutChange?: (sizes: number[], layout: ResizableLayoutMap) => void
    /** Called once a change is over (the pointer released), with the sizes as above. To save them. */
    onLayoutChanged?: (
      sizes: number[],
      layout: ResizableLayoutMap,
      meta: ResizableLayoutMeta,
    ) => void
    /** The tag to render. Default `div`. */
    as?: TagName
    /** Its name, for `ResizableHarness` (`data-test-jn-name`). */
    name?: string
  }
  Blocks: { default: [group: ResizableYield] }
  Element: HTMLElement
}

/**
 * A group of resizable panels with handles between them, as react-resizable-panels' `Group`
 * and ember-primitives' `Resizable`. Panels and handles are its children; a panel can hold
 * another group, for a nested layout.
 *
 *   <Resizable @orientation="horizontal" as |r|>
 *     <r.Panel @defaultSize="25%" @minSize="15%">Sidebar</r.Panel>
 *     <r.Handle aria-label="Resize the sidebar" />
 *     <r.Panel>Content</r.Panel>
 *   </Resizable>
 *
 * `ResizablePanel` and `ResizableHandle` are the same components, to import on their own.
 */
export class Resizable extends Component<ResizableSignature> {
  group = new ResizableGroup({
    orientation: () => this.args.orientation,
    dir: () => this.args.dir,
    disabled: () => this.args.disabled,
    disableCursor: () => this.args.disableCursor,
    defaultLayout: () => this.args.defaultLayout,
    onLayoutChange: () => this.args.onLayoutChange,
    onLayoutChanged: () => this.args.onLayoutChanged,
  })

  <template>
    <As
      @as={{@as}}
      @tag="div"
      data-slot="resizable"
      data-orientation={{this.group.orientation}}
      data-test-jn="resizable"
      data-test-jn-name={{@name}}
      ...attributes
      {{this.group.group orientation=@orientation disabled=@disabled}}
    >
      <Provide @data={{this.group}} @key={{ResizableGroup}} @element={{false}}>
        {{yield
          (hash
            Panel=ResizablePanel
            Handle=ResizableHandle
            panel=this.group.panel
            handle=this.group.handle
            layout=this.group.layout
            getLayout=this.group.getLayout
            setLayout=this.group.setLayout
          )
        }}
      </Provide>
    </As>
  </template>
}

export type { PanelSize, ResizablePanelSize }

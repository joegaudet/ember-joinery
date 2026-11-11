import type { TOC } from '@ember/component/template-only'
import { hash } from '@ember/helper'
import type { TagName } from '@ember-joinery/primitives/as'
import type { Direction } from '@ember-joinery/primitives/direction'
import {
  Resizable,
  ResizableHandle as PrimitiveHandle,
  ResizablePanel as PrimitivePanel,
  type ResizableGroup,
  type ResizableLayoutMap,
  type ResizableLayoutMeta,
  type ResizableOrientation,
  type ResizablePanelApi,
  type ResizablePanelSignature as PrimitivePanelSignature,
} from '@ember-joinery/primitives/resizable'

export interface ResizablePanelSignature {
  Args: PrimitivePanelSignature['Args']
  Blocks: {
    /** The content, given the panel's size and API (`panel.size`, `panel.collapse()`). */
    default: [panel: ResizablePanelApi]
  }
  Element: HTMLElement
}

/**
 * A panel of a `<ResizablePanelGroup>`, as shadcn's `ResizablePanel` (react-resizable-panels'
 * `Panel`). Sizes are percentages (`@defaultSize="50%"`, or `"50"`), other units (`"200px"`,
 * `"10rem"`), or a number of pixels. It yields its size and its API.
 */
export const ResizablePanel: TOC<ResizablePanelSignature> = <template>
  <PrimitivePanel
    @id={{@id}}
    @defaultSize={{@defaultSize}}
    @minSize={{@minSize}}
    @maxSize={{@maxSize}}
    @collapsible={{@collapsible}}
    @collapsedSize={{@collapsedSize}}
    @collapsedThreshold={{@collapsedThreshold}}
    @disabled={{@disabled}}
    @groupResizeBehavior={{@groupResizeBehavior}}
    @onResize={{@onResize}}
    @as={{@as}}
    data-slot="resizable-panel"
    ...attributes
    as |panel|
  >{{yield panel}}</PrimitivePanel>
</template>

export interface ResizableHandleSignature {
  Args: {
    /** Show a grip on the handle, as upstream's `withHandle`. */
    withHandle?: boolean
    /** Whether it can't be moved. */
    disabled?: boolean
    /** Whether a double-click leaves its panel alone, instead of restoring its default size. */
    disableDoubleClick?: boolean
    /** The tag to render. Default `div`. */
    as?: TagName
  }
  Blocks: { default: [] }
  Element: HTMLElement
}

/**
 * The handle between two panels, as shadcn's `ResizableHandle`: a line a pointer drags and the
 * arrow keys move (APG's window splitter), with a grip when `@withHandle`. Name it for what it
 * resizes (`aria-label="Resize the sidebar"`); upstream's has no name.
 */
export const ResizableHandle: TOC<ResizableHandleSignature> = <template>
  <PrimitiveHandle
    @disabled={{@disabled}}
    @disableDoubleClick={{@disableDoubleClick}}
    @as={{@as}}
    class="jn-resizable-handle"
    data-slot="resizable-handle"
    ...attributes
  >
    {{#if @withHandle}}
      <div class="jn-resizable-handle-icon"></div>
    {{/if}}
    {{yield}}
  </PrimitiveHandle>
</template>

/** What `<ResizablePanelGroup>` yields. */
export interface ResizablePanelGroupYield {
  /** A panel: `<g.Panel @defaultSize="30%">`, the same as `<ResizablePanel>`. */
  Panel: typeof ResizablePanel
  /** A handle: `<g.Handle @withHandle={{true}} />`, the same as `<ResizableHandle>`. */
  Handle: typeof ResizableHandle
  /** A panel, as a modifier on your own element: `<section {{g.panel defaultSize="30%"}}>`. */
  panel: ResizableGroup['panel']
  /** A handle, as a modifier on your own element: `<div {{g.handle}}>`. */
  handle: ResizableGroup['handle']
  /** The panels' sizes in percent, in order. */
  layout: readonly number[]
  /** The sizes by panel id. */
  getLayout: () => ResizableLayoutMap
  /** Sets the sizes, in order or by panel id; constraints still apply. */
  setLayout: (layout: readonly number[] | ResizableLayoutMap) => ResizableLayoutMap
}

export interface ResizablePanelGroupSignature {
  Args: {
    /** Panels side by side (`horizontal`, the default) or stacked (`vertical`). */
    orientation?: ResizableOrientation
    /** The text direction; by default the document's, from the nearest `dir`. */
    dir?: Direction
    /** Whether nothing in the group can be resized. */
    disabled?: boolean
    /** Whether to leave the cursor alone, instead of showing a resize cursor. */
    disableCursor?: boolean
    /** The first sizes in percent, in order or by panel `@id`: for a layout you saved. */
    defaultLayout?: readonly number[] | ResizableLayoutMap
    /** Called while the layout changes (on every pointer move). */
    onLayoutChange?: (sizes: number[], layout: ResizableLayoutMap) => void
    /** Called once a change is over (the pointer released): to save the layout. */
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
  Blocks: { default: [group: ResizablePanelGroupYield] }
  Element: HTMLElement
}

/**
 * Accessible resizable panel groups and layouts with keyboard support: shadcn's Resizable, on
 * Joinery's own `Resizable` primitive (react-resizable-panels' API, which upstream wraps).
 *
 *   <ResizablePanelGroup @orientation="horizontal">
 *     <ResizablePanel @defaultSize="25%">Sidebar</ResizablePanel>
 *     <ResizableHandle @withHandle={{true}} aria-label="Resize the sidebar" />
 *     <ResizablePanel>Content</ResizablePanel>
 *   </ResizablePanelGroup>
 *
 * A panel can hold another group, for a nested layout.
 */
export const ResizablePanelGroup: TOC<ResizablePanelGroupSignature> = <template>
  <Resizable
    @orientation={{@orientation}}
    @dir={{@dir}}
    @disabled={{@disabled}}
    @disableCursor={{@disableCursor}}
    @defaultLayout={{@defaultLayout}}
    @onLayoutChange={{@onLayoutChange}}
    @onLayoutChanged={{@onLayoutChanged}}
    @as={{@as}}
    @name={{@name}}
    class="jn-resizable-panel-group"
    data-slot="resizable-panel-group"
    ...attributes
    as |group|
  >
    {{yield
      (hash
        Panel=ResizablePanel
        Handle=ResizableHandle
        panel=group.panel
        handle=group.handle
        layout=group.layout
        getLayout=group.getLayout
        setLayout=group.setLayout
      )
    }}
  </Resizable>
</template>

# @ember-joinery/test-support

## 1.1.0

No changes in this release.

## 1.0.0

### Major Changes

- a73065d: The first release of Joinery's core packages: `@ember-joinery/primitives` (headless behaviour
  and utilities), `@ember-joinery/ember` (the styled components and their compiled CSS) and
  `@ember-joinery/test-support` (a harness for each of them).

### Minor Changes

- a73065d: `Accordion` is shadcn's Accordion, and `@ember-joinery/primitives/accordion` the headless one
  under it, Radix's, covering ember-primitives' too: `@type="single"` (optionally `@collapsible`) or
  `"multiple"`, controlled (`@value`, `@onValueChange`) or not (`@defaultValue`), disabled items or
  a disabled accordion, each item a heading with a trigger (`aria-expanded`, `aria-controls`) and a
  content region labelled by it, and the arrow keys, Home and End between triggers, by
  `@orientation` and direction. The styled trigger draws upstream's chevrons (`@icon` and
  `@openIcon` replace them), and the content animates from its measured height.
  `AccordionState` and `AccordionItemState` hold the behaviour for components built on it.
  `@ember-joinery/test-support` adds `AccordionHarness`.
- a73065d: `AlertDialog` is shadcn's Alert Dialog: Trigger, Content (`@size`: `default` or `sm`), Header,
  Footer, Media, Title, Description, and Action and Cancel Buttons; Cancel has focus when it
  opens, and a press outside doesn't close it. `@ember-joinery/test-support` adds
  `AlertDialogHarness`.
- a73065d: `Alert` is shadcn's callout, with the `alert` role and a typed `@variant` (`default` or
  `destructive`). It yields its parts, `Title`, `Description` and `Action`, each taking `@as`,
  and a modifier for each (`<h3 {{a.title}}>`) to make your own element that part.
  `@ember-joinery/test-support` adds `AlertHarness`.
- a73065d: `@ember-joinery/primitives/aspect-ratio` is Radix's AspectRatio: content held to `@ratio`,
  with only the styles that hold it, set through the CSSOM. `AspectRatio` in
  `@ember-joinery/ember` is shadcn's, on it. `@ember-joinery/test-support` adds
  `AspectRatioHarness`.
- a73065d: `Attachment` is shadcn's Attachment: a file or image in a chat composer, a message thread or an
  upload list, with `@state` (`idle`, `uploading`, `processing`, `error`, `done`), `@size`
  (`default`, `sm`, `xs`), `@orientation` (`horizontal`, `vertical`), `@as`, and its parts,
  yielded as components and modifiers (`Media` with `@variant`, `Content`, `Title`,
  `Description`, `Actions`, `Action`, a ghost `icon-xs` Button by default, and `Trigger`, a button
  or link over the whole card below the actions). `AttachmentGroup` lays attachments out in a row
  that scrolls across and snaps. `@ember-joinery/test-support` adds `AttachmentHarness` and
  `AttachmentGroupHarness`.
- a73065d: `Avatar` is shadcn's Avatar, with `@size` and its `Image`, `Fallback` and `Badge` parts, and
  `AvatarGroup` with its `Count`. It is built on `@ember-joinery/primitives/avatar`, ember-primitives'
  and Radix's headless Avatar: the image renders once it has loaded, the fallback shows until
  then (after `@delayMs`) and if it fails, the URL goes on the image or the avatar, and the
  avatar yields where its image is; `ImageLoader` loads an image off the page, and tests wait for
  it. `@ember-joinery/test-support` adds `AvatarHarness` and `AvatarGroupHarness`.
- a73065d: `Badge` is shadcn's Badge, with a typed `@variant` (`default`, `secondary`, `destructive`,
  `outline`, `ghost` or `link`), `@as` for another tag, and an `asBadge` modifier for your own
  elements and components (`<LinkTo {{asBadge}}>`); `badgeClasses()` and `badgeAttributes()`
  return what both render. `@ember-joinery/test-support` adds `BadgeHarness`.
- a73065d: `@ember-joinery/primitives/breadcrumb` is ember-primitives' Breadcrumb: a named `nav` around an
  ordered list, yielding a `Separator` that assistive technology skips
  (`breadcrumbSeparatorAria()`). `Breadcrumb` in `@ember-joinery/ember` is shadcn's, yielding
  `List`, `Item`, `Link`, `Page`, `Separator` (lucide's chevron, mirrored right to left, or your
  block or `@icon`) and `Ellipsis`, each also a modifier (`<LinkTo {{b.link}}>`).
  `@ember-joinery/test-support` adds `BreadcrumbHarness`, which drives both.
- a73065d: `Bubble` is shadcn's Bubble: a message's surface, with its seven `@variant`s, `@align`, `@as`,
  and its parts, yielded as components and modifiers: `Content` (`@as="button"` or `"a"`, or the
  `content` modifier on a `LinkTo`, makes the bubble a button or a link) and `Reactions`
  (`@side`, `@align`). `BubbleGroup` stacks consecutive bubbles from one sender.
  `@ember-joinery/test-support` adds `BubbleHarness` and `BubbleGroupHarness`.
- a73065d: `ButtonGroup` is shadcn's Button Group: buttons joined into one control, in a row or a column
  (`@orientation`), with its `Separator` (its ARIA the primitives' `separatorAria()`) and `Text`
  parts; `buttonGroupClasses()` returns what it renders. `@ember-joinery/test-support` adds `ButtonGroupHarness`.
- a73065d: `Button` is shadcn's Button, with typed `@variant` and `@size`, `@as` for another tag, and a
  `asButton` modifier for your own elements and components (`<LinkTo {{asButton}}>`);
  `buttonClasses()` and `buttonAttributes()` return what both render. `@ember-joinery/test-support`
  adds `ButtonHarness`.
- a73065d: `Calendar` is shadcn's Calendar, with Joinery's own date picking in place of React DayPicker
  and no date library: `@mode` `single`, `multiple` or `range` (`@value`, `@defaultValue` and
  `@onValueChange`, a `Date`, `Date[]` or `{ from, to }`), month and year dropdowns
  (`@captionLayout`), several months, `@disabled`, `@hidden` and `@modifiers` matchers, week
  numbers, outside days, fixed weeks, and the date grid's keys, right to left too. Names,
  numbers and the week's first day come from Intl in `@locale`; `@calendar` and `@numerals` show
  any calendar Intl knows, such as the Persian one. A `<:day>` block draws what each day shows.
  `@ember-joinery/primitives/calendar` is the headless one, with `CalendarState` and its date
  helpers, and `@ember-joinery/test-support` adds `CalendarHarness`.
- a73065d: `Card` is shadcn's card, with `@size` (`default` or `sm`) and the `--card-spacing` variable for
  its spacing. It yields its parts, `Header`, `Title`, `Description`, `Action`, `Content` and
  `Footer`, each taking `@as`, and a modifier for each (`<LinkTo {{c.title}}>`).
  `@ember-joinery/test-support` adds `CardHarness`.
- a73065d: `Checkbox` is shadcn's Checkbox, on Radix's: `@checked`, `@defaultChecked` and
  `@onCheckedChange` (controlled or not), the `'indeterminate'` state (`aria-checked="mixed"`),
  `@disabled`, `@required`, and `@icon` and `@indeterminateIcon` to replace its marks. In a form, a
  hidden native checkbox beside it submits its `name` and `value`, and a reset restores it.
  `@ember-joinery/primitives/checkbox` is the headless one, with its `Indicator`, and
  `@ember-joinery/test-support` adds `CheckboxHarness`.
- a73065d: `Collapsible` is shadcn's Collapsible, and `@ember-joinery/primitives/collapsible` the headless
  one under it, Radix's: a trigger (`aria-expanded`, `aria-controls`) that shows and hides content,
  controlled (`@open`, `@onOpenChange`) or not (`@defaultOpen`), with a yielded `trigger` modifier
  for your own element (`<Button {{c.trigger}}>`). The content stays in the document, `hidden`
  while closed, animates out through `Presence`, and is measured into
  `--radix-collapsible-content-height` and `-width`; `CollapsibleState` holds the behaviour for
  components built on it. Joinery's base keeps a part that is `hidden` hidden whatever `display`
  a class gives it, as Tailwind's preflight does, so content laid out with `flex` stays out of the
  way while closed. `Presence` now also yields `isExiting`. `@ember-joinery/test-support` adds
  `CollapsibleHarness`.
- a73065d: `Combobox` is shadcn's Combobox, on Base UI's: `<Combobox @items={{…}} as |c|>` yields Input
  (in its input group, with `@showTrigger`, `@showClear`, `@groupClass` for the group, and
  an `Addon` it yields for an icon beside the input),
  Trigger, TriggerIcon, Clear, Value, Content, List, Item, Group, Label, Collection, Empty,
  Separator, Chips, Chip and ChipsInput. Typing filters `@items` (an `Intl.Collator` match anywhere in the label, or your
  own `@filter`, or `@filter={{null}}` for results filtered elsewhere) and the arrow keys
  highlight an item while focus stays in the input; `@multiple` shows the chosen items as chips,
  `@autoHighlight` highlights the first match, and the input can sit inside the popup behind a
  trigger of your own. `@ember-joinery/primitives/combobox` is the headless one, and
  `@ember-joinery/test-support` adds `ComboboxHarness`.
- a73065d: `ContextMenu` is shadcn's Context Menu, on Radix's: a right click on `<c.Trigger>` (or a long
  press by touch or pen) opens its content at the pointer, in place of the browser's own menu. Its
  content, items, checkbox and radio items, labels, separators, shortcuts and submenus are the
  Dropdown Menu's, with `context-menu` in their classes and slots, and `{{c.trigger}}` makes your
  own element the trigger, styled as `<c.Trigger>` is. `@onOpenChange` tells you when
  it opens and closes. `@ember-joinery/primitives/context-menu` is the headless one, and
  `@ember-joinery/test-support` adds `ContextMenuHarness`, with `open(point)` for a right click and
  `longPress()`.
- a73065d: `DatePickerHarness` drives a date picker, shadcn's composition of a `Popover` and a `Calendar`
  (there is no date picker component of its own): a `PopoverHarness` with the `calendar` in its
  content and the trigger's `text`, and `pick(day)`, `pickRange(from, to)` and `showMonth(day)`,
  which open the popover, go to the day's month (by the month and year dropdowns where the
  calendar has them, else the previous and next buttons) and press the day. `pickRange()` picks
  just that range whatever range the calendar holds, pressing `from` until the range starts and
  ends there before it presses `to`, and throws when the calendar won't take the range.
  The guide's Date Picker page ports every upstream example: the demo, basic, a range over two
  months, a date of birth, an input, a time picker, natural language and right to left.

  An Input Group addon's margin for a button directly in it (each style's `has-[>button]` rule)
  now also reaches a button inside a Popover's, Tooltip's, Hover Card's, Dialog's, Sheet's,
  Drawer's, Select's or menu's root, which renders an element (display: contents) where Radix's
  renders none: a date picker's calendar button, or a tooltip's or dropdown's button in an addon,
  sits where upstream's does. `build-css.mjs` declares a `style-<name>` variant for each style,
  which a component's hand-written rule uses to restate a sheet's per-style utilities.

- a73065d: `Dialog` is shadcn's Dialog: Trigger, Content (with its overlay and a close button,
  `@showCloseButton`, `@closeLabel` and `@closeIcon`), Header, Footer (`@showCloseButton`), Title,
  Description and Close, with the `trigger` and `close` modifiers for your own elements.
  `@ember-joinery/test-support` adds `DialogHarness`, which follows the content into the top layer.
- a73065d: `Drawer` is shadcn's Drawer, on the headless one in `@ember-joinery/primitives/drawer`: a panel
  from any edge of the screen (`@direction`), with upstream's handle, header, footer, title and
  description, and vaul's snap points, nested drawers and scaled background. `joinery.css` (and
  every style) ships vaul 1.1.2's CSS, which slides it in and out, with twins for right to left.
  `@ember-joinery/test-support` adds `DrawerHarness`, a `DialogHarness` that drags the drawer
  (`drag()`, `swipe()`, `tapHandle()`) and reads its `direction`, `side`, `activeSnapPoint`,
  `offset` and `isDragging`.
- a73065d: `DropdownMenu` is shadcn's Dropdown Menu, on Radix's: `<DropdownMenu as |m|>` yields Trigger,
  Content, Group, Label, Item (`@variant`, `@inset`, `@onSelect`), LinkItem, CheckboxItem,
  RadioGroup, Separator, Shortcut, Sub (its Trigger and Content) and Portal, a `trigger` modifier
  for your own Button (`<Button {{m.trigger}}>`), and `item` and `checkboxItem` modifiers that
  style your own element as an item (a radio group's `item` and a submenu's `trigger` do the same
  for theirs). The content is a menu in the top layer, below its trigger and
  lined up with its start: the arrow keys, Home, End and typing move between its items, Enter or a
  click selects one, Escape or a press outside closes it, and focus goes back to the trigger.
  Submenus open on hover or the arrow pointing into them, and stay open while the pointer crosses
  other items on its way there; as Radix's, a submenu closes (`@onOpenChange(false)`) when the
  menu it is in closes or it goes away. Every part but LinkItem (always an `<a>`) takes `@as`.
  Modal by default, it keeps focus and the pointer in the menu and makes the page inert. Its
  state is `@open`/`@defaultOpen`/`@onOpenChange`, and it takes ember-primitives' Menu's
  positioning arguments too: `<DropdownMenu @placement="top-end">` places its content, alignment
  and all.
  `@ember-joinery/primitives/dropdown-menu` is the headless one, covering ember-primitives' Menu
  (also exported as `Menu`), and `@ember-joinery/test-support` adds `DropdownMenuHarness`, which
  finds items by their text and opens submenus with `sub()`.
- a73065d: `Empty` is shadcn's empty state. It yields its parts, `Header`, `Media` (with `@variant`,
  `default` or `icon`), `Title`, `Description` and `Content`, each taking `@as`, and a modifier
  for each (`<img {{e.media}}>`). `@ember-joinery/test-support` adds `EmptyHarness`.
- a73065d: `Field` is shadcn's Field family: `Field` (`@orientation` `vertical`, `horizontal` or
  `responsive`, `@invalid`, `@disabled`), `FieldSet`, `FieldLegend` (`@variant`), `FieldGroup`,
  `FieldContent`, `FieldLabel`, `FieldTitle`, `FieldDescription`, `FieldSeparator` and
  `FieldError` (its block, or `@errors`: one message, or a list of distinct ones), with an `as…`
  modifier for each part that has nothing of its own to render. `@ember-joinery/test-support`
  adds `FieldHarness`, `FieldSetHarness` and `FieldGroupHarness`. A radio group's items now name
  their group's `id` (the caller's own, when they give one) in `data-test-jn-owner`, so
  `RadioGroupHarness` finds them inside a Field or a label around them, and the checkable
  harnesses count a control in a disabled `<fieldset>` as disabled.
- a73065d: `FileDrop` and `DocumentFileDrop` are ember-primitives': a zone to drop files on or press to pick
  them, and a way to take files dropped anywhere on the page, filtered by `@accept` as the file
  picker filters them. `@ember-joinery/primitives/file-drop` has the headless ones (with
  `@disabled`, and `accepts`, `filesFrom`, `hasFiles` and `DragState` for a target of your own);
  `@ember-joinery/ember`'s FileDrop is a dashed drop zone, and its DocumentFileDrop covers the page
  with an overlay while files are dragged over it. `@ember-joinery/test-support` adds
  `FileDropHarness`, `DocumentFileDropHarness`, and `dragFilesOver`, `dragFilesAway` and
  `dropFiles`.
- a73065d: `HoverCard` is shadcn's Hover Card, on Radix's: it opens once the pointer has rested on its
  trigger for `@openDelay` (or the trigger has focus), below it, centred and 4px off, and closes
  `@closeDelay` after the pointer leaves both, staying open while text in it is selected; a touch
  doesn't open it. `@ember-joinery/primitives/hover-card` is the headless one, and
  `@ember-joinery/test-support` adds `HoverCardHarness`.
- 17c5b5c: Joinery's built-in strings can be translated. `@ember-joinery/primitives/i18n` declares the msgid
  contract's `Message` and `Translator`, with `format()` (English: a `plural` by `values.count`, and
  `{name}` placeholders), `translate(context, message, values?)`, which uses the app's
  `translator:main` when it registers one and English otherwise, and `t`, the same for a
  template. Every string the primitives show is a message in `@ember-joinery/primitives/messages`
  (`joinery.<component>.<name>`) and goes through the translator; an argument still wins. Joined
  strings are one message each (`Value {index} of {count}`, `Today, {date}, selected`, `Notifications
{hotkey}`), so a translation orders the words. A calendar's and a combobox's `@locale` default to
  the translator's. `defaultSliderThumbLabel` takes an optional context, and `CalendarState` an
  optional third argument, the component, for the same. `@ember-joinery/test-support` adds
  `setupTranslator(hooks, translator)` and `pseudoTranslator`, a pseudo-locale that wraps every
  string it translates.
- a73065d: `Icon` draws `lucide` icons, imported one at a time (`<Icon @icon={{ArrowUp}} />`), decorative
  unless given `@label`. `@ember-joinery/test-support` adds `IconHarness`.
- a73065d: `InputGroup` is shadcn's Input Group: one input or textarea with addons beside, above or below
  it, drawn as one field. It yields its `Input`, `Textarea`, `Addon` (`@align`), `Button` (`@size`,
  `@variant`) and `Text`, each also a modifier for an element of your own, and `g.control` marks
  a control of your own as the group's. `@ember-joinery/test-support` adds `InputGroupHarness`.
- a73065d: `InputOTP` is shadcn's Input OTP, yielding its `Group`, `Slot` and `Separator`, on a new
  `@ember-joinery/primitives/input-otp`: the `input-otp` library's one invisible native input under
  slots you render, which also covers ember-primitives' `OTP`. Its code is controlled or not
  (`@value`, `@defaultValue`, `@onValueChange`), `@pattern` (`REGEXP_ONLY_DIGITS` and the rest)
  refuses what it doesn't match, every paste goes through `@pasteTransformer`, `@onComplete` hears
  a complete code, `@autoSubmit` submits its form, and a browser's autofill of a code it was sent
  fills it at once. Right to left, its arrow keys follow the slots, which run from the right.
  `@ember-joinery/test-support` adds `InputOTPHarness`, which types, deletes, moves the caret,
  clicks, pastes and autofills as a browser does, and ember-primitives' `fillOTP`.
- a73065d: `Input` is shadcn's Input: a native `<input>` with `@value`, `@defaultValue` and
  `@onValueChange`, and an `asInput` modifier for an input of your own; `inputClasses()` and
  `inputAttributes()` return what both render. `@ember-joinery/test-support` adds `InputHarness`.
- a73065d: `Item` is shadcn's Item, with typed `@variant` and `@size`, `@as`, an `asItem` modifier for your
  own elements and components (`<LinkTo {{asItem}}>`), and its parts, yielded and exported
  (`ItemMedia`, `ItemContent`, `ItemTitle`, `ItemDescription`, `ItemActions`, `ItemHeader`,
  `ItemFooter`); `itemClasses()` and `itemAttributes()` return what it renders. `ItemGroup` is a
  list of items, with a `Separator`, also exported as `ItemSeparator`, whose ARIA is the
  primitives' `separatorAria()`. `@ember-joinery/test-support` adds `ItemHarness` and
  `ItemGroupHarness`.
- a73065d: `Kbd` and `KbdGroup` are shadcn's keyboard keys: a styled `<kbd>`, and a `<kbd>` of them for a
  shortcut, each with `@as`. `@ember-joinery/test-support` adds `KbdHarness` and
  `KbdGroupHarness`.
- a73065d: `@ember-joinery/primitives/label` is Radix's Label: a native `<label>` whose text a double
  click doesn't select (`preventLabelSelection`, for an element of your own). `Label` in
  `@ember-joinery/ember` is shadcn's, on it, with an `asLabel` modifier, and dims beside a
  disabled `peer` control. `@ember-joinery/test-support` adds `LabelHarness`.
- a73065d: `Marker` is shadcn's Marker: an inline status, note, bordered row or labelled separator in a
  conversation, with `@variant`, `@as`, an `asMarker` modifier for your own elements and components
  (`<LinkTo {{asMarker}}>`), and its parts, yielded and exported (`MarkerIcon`, which is hidden
  from assistive technology, and `MarkerContent`); `markerClasses()` and `markerAttributes()`
  return what it renders, as upstream's `markerVariants`. `@ember-joinery/test-support` adds
  `MarkerHarness`.
- a73065d: `Menubar` is shadcn's Menubar, on Radix's: `<Menubar as |bar|><bar.Menu as |m|>` yields a
  Trigger and a Content placed as upstream's (below the trigger, at its start, 4px before it and
  8px off), with the Dropdown Menu's items, checkbox and radio items, labels, separators,
  shortcuts and submenus in the menubar's classes and slots, and `trigger`, `item` and
  `checkboxItem` modifiers for your own elements. Its triggers share one tab stop: the arrow keys
  move between them, Enter, Space or ArrowDown open a menu on its first item, and while one is
  open ArrowLeft and ArrowRight (flipped right to left) and the pointer move to the others. Which
  menu is open is `@value`/`@defaultValue`/`@onValueChange`. `@ember-joinery/primitives/menubar`
  is the headless one, and `@ember-joinery/test-support` adds `MenubarHarness`, whose `menu(label)`
  has a Dropdown Menu harness's members for each menu.
- a73065d: `MessageScrollerProvider` is shadcn's Message Scroller: a chat transcript's scroll container that
  opens a saved transcript at the start, the end or the last anchored turn (`@defaultScrollPosition`,
  hidden until it gets there), settles a new `@scrollAnchor` turn near the top with a peek of the
  one before (`@scrollPreviousItemPeek`), follows a streamed reply at the end with `@autoScroll`
  until the reader scrolls away, keeps the reader's row in place when history is prepended, and
  jumps to any row. It yields its styled parts (`Root`, `Viewport`, `Content`, `Item`, `Button`,
  `Visibility`), the commands (`scrollToMessage`, `scrollToEnd`, `scrollToStart`) and the scroll
  state (`scrollable`); the parts are exported on their own too (`MessageScroller`,
  `MessageScrollerItem`…). `@ember-joinery/primitives/message-scroller` is the headless scroller,
  `@shadcn/react`'s, with `MessageScrollerConsumer` and the `messageScrollerButton` modifier. Its
  button, as upstream's, keeps a `tabindex` of your own while it is active, and a click listener of
  yours runs first and can stop the scroll with `preventDefault()`; the styled one takes `@as`.
  `@ember-joinery/test-support` adds `MessageScrollerHarness`.
- a73065d: `Message` is shadcn's Message: one row of a conversation, with `@align` (`start` or `end`),
  `@as`, and its parts, yielded as components and modifiers (`Avatar`, `Content`, `Header`,
  `Footer`). `MessageGroup` stacks consecutive messages from one sender.
  `@ember-joinery/test-support` adds `MessageHarness` and `MessageGroupHarness`.
- a73065d: `NativeForm` is ember-primitives' Form, renamed so it can't clash with Formwright's `<Form>`: a
  native `<form>` whose `@onChange` hears its data as an object on every input and on submit.
  `dataFromEvent` reads the same object out of any form's event, converting numbers, dates,
  checkboxes, radios, selects and files as form-data-utils does, and takes Joinery's button
  controls in through their hidden inputs. `@ember-joinery/test-support` adds
  `NativeFormHarness`, whose `pressEnter` submits the form from a field as the browser does.
- a73065d: `NativeSelect` is shadcn's Native Select: the browser's own `<select>` with a chevron (`@icon`),
  typed `@size`, `@value`, `@defaultValue` and `@onValueChange`, yielding its `Option` and
  `OptGroup` parts. `@ember-joinery/test-support` adds `NativeSelectHarness`.
- a73065d: `NavigationMenu` is shadcn's Navigation Menu, on Radix's: a `<nav>` whose `n.List` holds
  `n.Item`s, each a `n.Link` or an `item.Trigger` and its `item.Content`. A trigger opens its
  content on a click, or when the pointer rests on it (at once while another was just open); the
  contents show in a viewport below the list that takes the open one's size and slides each in
  from its trigger's side (`data-motion`), or below their own triggers with `@viewport={{false}}`.
  Tab goes from an open trigger into its links and on, and the arrow keys, Home and End move
  between triggers and links, for a trigger of your own (`{{item.trigger}}`) as for `item.Trigger`.
  `n.Indicator` follows the open trigger, `n.Viewport` places the viewport yourself with
  `@viewport={{false}}`, and `navigationMenuTriggerStyle()` gives a link the trigger's look, its
  padding over the link's, as upstream's tailwind-merge gives it. Its state is
  `@value`/`@defaultValue`/`@onValueChange`. `@ember-joinery/primitives/navigation-menu` is the
  headless one, with `List`, `Item`, `Link`, `Indicator` and `Viewport`, and
  `@ember-joinery/test-support` adds `NavigationMenuHarness`.
- a73065d: `Pagination` is shadcn's: a named `nav` yielding `Content`, `Item`, `Link` (`@isActive`,
  `@size`), `Previous` and `Next` (`@text`, `@label`, `@icon`) and `Ellipsis`. Its links are
  Buttons, ghost or, for the current page, outline with `aria-current="page"`; the `link`,
  `previous` and `next` modifiers make a router's link one, and `paginationLinkClasses()` and
  `paginationLinkAttributes()` return what they render. `@ember-joinery/test-support` adds
  `PaginationHarness`.
- a73065d: `Popover` is shadcn's Popover, on Radix's: `<Popover as |p|>` yields Trigger, Anchor, Content,
  Header, Title, Description, Close and Arrow, and a `trigger` modifier for your own Button
  (`<Button {{p.trigger}}>`). The content is in the top layer while open, placed against its
  trigger (centred, 4px off, flipping to stay in view), closed by Escape or a press outside, with
  focus moving in and back; `@modal` keeps focus and the pointer inside, and hides the rest of
  the page from assistive technology and stops it scrolling. Its state is
  `@open`/`@defaultOpen`/`@onOpenChange`. `@ember-joinery/primitives/popover` is the headless
  one, covering ember-primitives' Popover (`@placement`, `@offsetOptions`, `@flipOptions`,
  `@shiftOptions`, `@middleware`, `@strategy`, and the `reference`, `setReference`, `arrow` and
  `data` yields), and `@ember-joinery/test-support` adds `PopoverHarness`.
- a73065d: `@ember-joinery/primitives/command` adds `Command`, cmdk's command menu, headless: typing filters
  the items with cmdk's command score (or `@filter`) and shows the best first, groups and
  separators hide with nothing to show, Empty shows when nothing matches, and the arrows, Home and
  End, Ctrl+N/J/P/K and Alt+arrow move the selection while focus stays in the input; Enter clicks
  the selected item. It covers ember-primitives' CommandPalette too: `@search` and
  `@onSearchChange`, `@onSelect`, `@hotkey` and `@onOpen`, link items, and a `role="status"` that
  announces the result count (`@resultsText`). `CommandDialog` puts a Command in a modal dialog,
  with a `@hotkey` that opens and closes it. `@ember-joinery/test-support` adds `CommandHarness`
  and `CommandDialogHarness`.
- a73065d: ember-primitives' components that shadcn has no counterpart for, one subpath export each:
  `scroller` (`Scroller`, which yields `scrollToTop`, `scrollToBottom`, `scrollToLeft`,
  `scrollToRight`, `scrollToStart` and `scrollToEnd`), `zoetrope` (`Zoetrope`: a row that scrolls a
  page at a time, instantly for reduced motion, right to left too, and without trapping Tab),
  `hero` (`Hero`), `sticky-footer` (`StickyFooter`), `link` (`Link`, active-aware, with
  `aria-current` and `data-active`), `external-link` (`ExternalLink`), `heading` (`Heading`, whose
  level comes from the sections around it, and `getSectionHeadingLevel`), `incremental-each`
  (`IncrementalEach`, which renders a long list a batch at a time) and `shadowed` (`Shadowed`, a
  shadow root, with `@includeStyles`). The layouts bring their own rules, in `@layer joinery`, with
  nothing to import; an app with CSS layers of its own names `joinery` ahead of them, as
  joinery.css and the Tailwind setup do, for its layers to win. `@ember-joinery/test-support` adds `ScrollerHarness`, `ZoetropeHarness`,
  `HeroHarness`, `StickyFooterHarness`, `LinkHarness`, `ExternalLinkHarness`, `HeadingHarness` and
  `ShadowedHarness`, ember-primitives' shadow DOM helpers (`findInShadow`, `findShadow`,
  `findInFirstShadow`, `hasShadowRoot`), and `data-test-jn-wrapper`: a component that wraps your
  content marks its root with it, and the parts inside belong to the component around it.
- a73065d: Focus, one subpath export each, ported from Radix and covering what ember-primitives gets from
  tabster, with nothing to set up: `focus-scope` (`FocusScope`, `{{focusScope}}` and
  `createFocusScope`: focus moves in, can be trapped or loop, and returns when the scope goes;
  scopes stack, and trapped ones add focus guards), `roving-focus` (`RovingFocusGroup` and
  `RovingFocus`: one tab stop, the arrow keys, Home and End, right to left, loop, a remembered and
  an active item, a controlled tab stop), `typeahead` (`{{typeahead}}`, `Typeahead`,
  `getNextMatch`) and `focus` (`focusable` queries, `focusFirst`, `focusElement`, and
  `{{restoreFocus}}`, which keeps focus from falling to `<body>` when its element is removed).
  `@ember-joinery/test-support` adds `tab()`, `tabOrder()`, `pressKey()`, `typeKeys()` and
  `RovingFocusGroupHarness`.
- a73065d: The primitives' foundations, one subpath export each: `controllable-state` (Radix's
  controlled-or-uncontrolled pattern, as `controllable(this, 'open', false)`), `id` (`idFor`, the
  ids a component's parts share; one-off ids use Ember's own `uniqueId`), `direction`
  (`DirectionProvider` and `getDirection`), `as` and `part` (the `@as` tag swap and the part
  modifiers that let any element, `LinkTo` included, be a part), `presence` (keeps a part mounted
  through its exit animation), `visually-hidden` (`VisuallyHidden` and `{{visuallyHidden}}`),
  `keys` (`Key` and `KeyCombo`), `color-scheme` (system, light or dark, saved, synced across tabs,
  applied to `<html>`; replaces next-themes) and `service` (one instance per owner, for app-wide
  state that tests must not share). `@ember-joinery/test-support` adds `KeyHarness`,
  `KeyComboHarness` and `setupColorScheme`.
- a73065d: Layering, anchoring, portals and dismissal, one subpath export each. `layer`: `{{topLayer}}`
  puts an element in the browser's top layer with the Popover API (`popover="manual"`, or `auto`
  for the browser's light dismiss), nested layers always above their parents. `anchor`:
  `anchorTo`, `FloatingUI` and `anchor()` place an element against another with CSS anchor
  positioning where the browser has it and Floating UI (offset, flip, shift, size, arrow, hide)
  otherwise or when `globalThis.JOINERY_ANCHOR_FALLBACK` is set, taking both Radix's Popper
  arguments and ember-primitives' floating-ui ones, setting `data-side`, `data-align` and the
  `--jn-anchor-*` custom properties; with ember-primitives' `exposeMetadata` and `flipTo`
  middleware. `dismiss`: the dismiss stack (`{{dismissable}}`, `{{dismissableBranch}}`,
  `registerDismissable`), as Radix's `DismissableLayer`: Escape closes only the top layer, and
  pointers and focus outside close the layers they leave, nested layers counting as inside their
  parents. `portal`: ember-primitives' `Portal`, `PortalTargets`, `PortalTarget` and `wormhole`,
  with `<body>` as Radix's default target. `@ember-joinery/test-support` adds `press`,
  `pressOutside`, `pressEscape`, `isInTopLayer`, `placementOf` and `setupAnchorFallback`.
- a73065d: ember-primitives' app utilities, one subpath export each: `store` (`createStore`, one instance
  per context, owner or none, with `findOwner` and `isOwner`), `service` (now also `(service "router")` for a
  registered service, and `asyncService` for one loaded on demand), `head` (`InHead`),
  `body-class` (`{{bodyClass}}`), `iframe` (`inIframe`, `notInIframe`), `load` (a component that
  loads another), `qp` (`qp`, `withQP`, `castToBoolean`), `link-helper` (the `link` helper:
  external, active, and a routed click, with `isExternalLink`, `isActiveLink` and
  `dynamicSegments`), `proper-links` (`@properLinks`, `setupProperLinks`,
  `shouldHandle`), `viewport` (`viewport()` and `InViewport`), `on-resize` (`{{onResize}}`),
  `resize-observer` (`resizeObserver()` and `ignoreROError`), `dom-context` (`Provide` and `Consume`) and `narrowing` (`isString`,
  `isElement`, `isNewable`, `isNonNullableObject`, `Newable`). `@ember-joinery/test-support` adds `setupRouting` and
  `getRouter`, and `waitForObservers` and `scrollIntoView` for what the observers report.
- a73065d: `@ember-joinery/primitives/progress` is ember-primitives' and Radix's Progress: a
  `progressbar` with its value, max and `@getValueLabel` text in ARIA and data attributes,
  indeterminate without a value, clamping out-of-range values, and yielding an `Indicator` and
  the value, percent and state; `resolveProgress()` returns what it renders. `Progress` in
  `@ember-joinery/ember` is shadcn's, on it, and announces its value, which upstream's leaves off.
  `@ember-joinery/test-support` adds `ProgressHarness`.
- a73065d: `Questionnaire` is shadcn's Questionnaire: a multi-step native form of single-choice,
  multiple-choice, freeform and skippable questions, with progress, validation (its own, or yours
  through `@invalid` and `@message`), navigation buttons that show where they apply, letter or
  number shortcuts, the keyboard of upstream's (arrows between answers and items, flipped right to
  left; `Enter` and `Meta+Enter` to confirm), a controlled or uncontrolled active item
  (`@item`, `@defaultItem`, `@onItemChange`; an item that no longer applies gives way to the
  first, and `@onItemChange` hears it), controlled or default answers (a freeform `Input` takes
  `@value` and `@onValueChange`), a reset that puts them back, development warnings where `@items`
  and the rendered items part, `@as` on every part, and the navigation buttons as modifiers
  (`{{q.next}}`). Its behaviour is `@ember-joinery/primitives/questionnaire`, @shadcn/react's headless
  Questionnaire, whose state classes put their parts on any element, so a card's or a dialog's
  title can be the question (`{{i.title}}`). `@ember-joinery/test-support` adds
  `QuestionnaireHarness`.
- a73065d: `RadioGroup` is shadcn's Radio Group, on Radix's: it yields its `Item`s, which share one tab
  stop, and an arrow key moves focus and the choice, going round (`@loop`) and flipping right to
  left. `@value`, `@defaultValue` and `@onValueChange`, `@disabled` on the group or an item,
  `@required`, `@orientation`, and `@formName` for the hidden native radios it submits in a form.
  `@ember-joinery/primitives/radio-group` is the headless one, and `@ember-joinery/test-support`
  adds `RadioGroupHarness`.
- a73065d: `Rating` is ember-primitives' Rating: a `<fieldset role="radiogroup">` of native radios,
  controlled or not (`@value`, `@defaultValue`, `@onValueChange`), with `@max`, half ratings
  through `@step`, `@readonly`, a display-only mode (`@interactive={{false}}`) that summarises
  itself, and its strings as arguments (`@itemLabel`, `@summary`).
  `@ember-joinery/primitives/rating` is the headless one, whose block lays it out with `Stars`,
  `Item` and `Range`; `@ember-joinery/ember`'s draws lucide's Star in shadcn's terms, in three
  sizes, with half stars. `@ember-joinery/test-support` adds `RatingHarness`, which reads each
  item's state (`stars`) and its icon's text (`starTexts`), and picks a value between the items on
  a range or number input.
- a73065d: `ResizablePanelGroup`, `ResizablePanel` and `ResizableHandle` are shadcn's Resizable: panel
  groups side by side or stacked, nested, with handles a pointer drags and the keyboard moves (APG's
  window splitter), sizes in percent, pixels or font units, collapsible panels, and a layout to save
  (`@defaultLayout`, `@onLayoutChanged`). They sit on `Resizable`, `ResizablePanel` and
  `ResizableHandle` from `@ember-joinery/primitives/resizable`, which follow react-resizable-panels'
  API and cover ember-primitives' `Resizable`. `@ember-joinery/test-support` adds
  `ResizableHarness`, and `sendPointer()` for real pointer events.
- a73065d: `ScrollArea` and `ScrollBar` are shadcn's Scroll Area: native scrolling with scrollbars of the
  style's drawing, which show while the pointer is over the area (`@type` for `scroll`, `auto` or
  `always`). They sit on `ScrollArea` from `@ember-joinery/primitives/scroll-area`, Radix's, with
  its viewport, scrollbars, thumbs and corner as parts. `@ember-joinery/test-support` adds
  `ScrollAreaHarness`.
- a73065d: `Select` is shadcn's Select, on Radix's: `<Select as |s|>` yields Trigger (`@size`), Value
  (`@placeholder`), Content, Group, Label, Item, Separator and Arrow, and a `trigger` modifier.
  The list opens over its trigger with the chosen option on the value (`item-aligned`, the
  default) or below it (`@position="popper"`), with scroll buttons while it scrolls, typeahead on
  the closed trigger and in the list, focus kept inside and the rest of the page inert while it
  is open, a hidden native `<select>` named `@formName` in a form, and a trigger a Field sizes
  as it does upstream's. Its state is
  `@value`/`@defaultValue`/`@onValueChange` and `@open`/`@defaultOpen`/`@onOpenChange`.
  `@ember-joinery/primitives/select` is the headless one, and `@ember-joinery/test-support`
  adds `SelectHarness`.
- a73065d: `@ember-joinery/primitives/separator` is ember-primitives' and Radix's Separator: an `<hr>` by
  default or any tag with `@as`, `@orientation`, and `@decorative` (`role="none"` and
  `aria-hidden`); `separatorAria()` returns its ARIA. `Separator` in `@ember-joinery/ember` is
  shadcn's, on it (a decorative `div` unless told otherwise), with an `asSeparator` modifier.
  `@ember-joinery/test-support` adds `SeparatorHarness`.
- a73065d: `Sheet` is shadcn's Sheet: a Dialog whose Content comes in from an edge of the screen (`@side`:
  `top`, `right`, `bottom` or `left`). `@ember-joinery/test-support` adds `SheetHarness`.
- a73065d: `SidebarProvider` is shadcn's Sidebar: `<SidebarProvider as |sidebar|>` yields the `Sidebar`
  (`@side`, `@variant` of `sidebar`, `floating` or `inset`, and `@collapsible` of `offcanvas`,
  `icon` or `none`), its Header, Content, Footer, Group (Label, Action, Content), Menu (Item,
  Button, Action, Badge, Skeleton, Sub, SubItem, SubButton), Input, Separator, Rail, Inset and
  Trigger, a modifier for each part (`<LinkTo {{sidebar.menuButton isActive=true}}>`), and what
  upstream's `useSidebar()` returns (`state`, `open`, `setOpen`, `openMobile`, `setOpenMobile`,
  `isMobile`, `toggleSidebar`). Its state is its own (`@defaultOpen`) or yours (`@open`,
  `@onOpenChange`); the trigger, the rail and ⌘B/Ctrl+B (`@keyboardShortcut`) toggle it; each
  change is kept in upstream's `sidebar_state` cookie, which `sidebarStateFromCookie()` reads back;
  and below 768px wide (`@mobileBreakpoint`, measured in the window it renders in) it is a Sheet
  with its own open state. A menu button's `@tooltip` names it while the sidebar is collapsed to
  its icons. The trigger adds `aria-expanded`, which upstream's lacks, and keeps a ghost Button's
  resting look while the sidebar is open. Slid off the screen (`offcanvas`), the sidebar hides
  its items from the Tab key and screen readers, which upstream's leaves focusable off the
  screen, and focus inside it goes to the trigger as it closes. `<UseSidebar as |sidebar|>` yields
  the same from the nearest provider around it, as upstream's `useSidebar()` does, so a routed
  page reaches the sidebar without its block params.
  `@ember-joinery/test-support` adds `SidebarHarness`, `SidebarMenuButtonHarness` and
  `SidebarMenuSubButtonHarness`. A floating part's content now also sees Radix Popper's own
  custom properties (`--radix-popper-anchor-width` and the rest), which upstream's sidebar
  examples size their menus by.
- a73065d: `Skeleton` is shadcn's loading placeholder: a pulsing, rounded block in `--muted`, sized with
  classes or CSS of your own, with `@as`. `@ember-joinery/test-support` adds `SkeletonHarness`.
- a73065d: `Slider` is shadcn's Slider, on a new headless `Slider` in `@ember-joinery/primitives/slider`
  (Radix's, covering ember-primitives' too): one `role="slider"` thumb per value, ranges and
  multiple thumbs that pass each other (`@minStepsBetweenThumbs` keeps them apart), a `@step`
  array that snaps to its values, vertical and inverted sliders, right to left through logical
  edges, the APG keys, the pointer, `@onValueCommit`, `@getThumbLabel`, and hidden form inputs
  with `@fieldName`. `@ember-joinery/test-support` adds `SliderHarness`.
- a73065d: `Spinner` is shadcn's loading indicator: lucide's `loader-circle`, turning, with the `status`
  role, `@label` (`Loading` by default) and `@icon` to turn another icon.
  `@ember-joinery/test-support` adds `SpinnerHarness`.
- a73065d: `Switch` is shadcn's Switch, on Radix's, in its `default` and `sm` sizes: `@checked`,
  `@defaultChecked` and `@onCheckedChange`, `@disabled` and `@required`, and a block that renders
  inside the thumb (an icon, say). In a form, a hidden native checkbox beside it submits its
  `name` and `value`. `@ember-joinery/primitives/switch` is the headless one, covering
  ember-primitives' `Switch`, with a `Thumb` you render yourself, and
  `@ember-joinery/test-support` adds `SwitchHarness`.
- a73065d: `Table` is shadcn's responsive table: a native `<table>` in a container that scrolls it
  sideways, yielding `Header`, `Body`, `Footer`, `Row`, `Head`, `Cell` and `Caption`, each also a
  modifier for an element of your own (`<tr {{t.row}}>`), each taking `@as`. While the table is
  wider than its container and has nothing to focus, the container joins the tab order, so the
  keyboard can scroll it. `@ember-joinery/test-support` adds `TableHarness`.
- a73065d: `Tabs` is shadcn's Tabs (`t.List` with `@variant="default"` or `"line"`, `t.Trigger`,
  `t.Content`, and `@orientation="vertical"`), on a new headless `Tabs` and `TabsState` in
  `@ember-joinery/primitives/tabs`, which covers ember-primitives' Tabs too: controlled or not
  (`@value`, `@defaultValue`, and `@onValueChange`, which also hears the value before), the first
  tab selected when no value is given, automatic or manual activation, one tab stop with the arrow
  keys along the orientation (flipped right to left, wrapping unless `@loop={{false}}`), link tabs
  on `<a href>` or `LinkTo` that focus never selects, and the `t.list`, `t.trigger` and
  `t.content` modifiers for your own elements. `@ember-joinery/test-support` adds `TabsHarness`.
- a73065d: The harness base: `Harness` finds a component by `data-test-jn` and `data-test-jn-name` on
  every read, reaches its parts through `data-test-jn-part` (following `data-test-jn-owner` into
  the top layer and portals), and fails clearly when pointed at another component. `@child`
  declares child harnesses, created once and kept, with legacy or standard decorators; `find()`
  and `findAll()` make one-off lookups; and `selectors` and `attributes` cover the
  `data-test-jn-*` attributes.
- a73065d: `Textarea` is shadcn's Textarea: a native `<textarea>` that grows with its text, with `@value`,
  `@defaultValue` and `@onValueChange`, and an `asTextarea` modifier for a textarea of your own.
  `@ember-joinery/test-support` adds `TextareaHarness`.
- a73065d: Toasts, as shadcn's Sonner: sonner 2.0.7 ported. `@ember-joinery/primitives/toast` has
  `toast()` with sonner's methods (`success`, `info`, `warning`, `error`, `loading`, `message`,
  `custom`, `promise`, `dismiss`, `getHistory`, `getToasts`), kept per owner in a `Toasts`
  service so each app and each test has its own (`toastsFor(this)`), and a headless `Toaster`
  with sonner's arguments, markup and data attributes: positions, the stack (three visible,
  expanding on hover, keyboard focus or Alt+T), timers that pause, swipe to dismiss, rich colours,
  close, action and cancel buttons. A new toast reaches the Toasters a microtask later, as
  sonner's does, so `toast()` can be called while a page renders, and `toast.dismiss()` takes
  what `toast.promise()` returns (`{ id, unwrap }`) as well as an id. Its lists are in the top
  layer, so toasts show above dialogs, and are dismissable branches. `@ember-joinery/ember` adds
  `Toaster`, upstream's: lucide's icons, the popover tokens and the theme's radius, a theme that
  follows `.dark`, and sonner's CSS in `joinery.css`; it exports `toast` and `toastsFor` too.
  `@ember-joinery/test-support` adds `ToasterHarness`, `ToastHarness` and `setupToaster(hooks)`.
  sonner's MIT notice is in `NOTICE` and in the built JavaScript and CSS that carry its code.
- a73065d: `ToggleGroup` is shadcn's Toggle Group (`@type="single"` or `"multiple"`, `@variant`, `@size`,
  `@spacing` and `@orientation` for every item), on a new headless `ToggleGroup` and
  `ToggleGroupState` in `@ember-joinery/primitives/toggle-group`: one tab stop with the arrow keys
  moving between items, radios in a single group and toggle buttons in a multiple one, and an
  item modifier, `g.item`, for your own elements. `@ember-joinery/test-support` adds
  `ToggleGroupHarness`.
- a73065d: `Toggle` is shadcn's Toggle, with typed `@variant` and `@size`, on a new headless `Toggle` in
  `@ember-joinery/primitives/toggle` (`aria-pressed` and `data-state`, controlled with `@pressed`
  or not with `@defaultPressed`); the `asToggle` modifier makes your own element a toggle, and
  `toggleClasses()` and `toggleAttributes()` return its look. `@ember-joinery/test-support` adds
  `ToggleHarness`.
- a73065d: `Tooltip` and `TooltipProvider` are shadcn's, on Radix's: a tooltip opens when the pointer
  rests on its trigger (at once by default, as in shadcn's provider) or on focus, describes the
  trigger through `aria-describedby`, lets the pointer cross onto it, and closes on blur, a
  press, Escape or the pointer leaving; it draws its arrow. A provider's tooltips share its
  `@delayDuration`, and the next opens at once just after one closed; tooltips need no provider.
  `@ember-joinery/primitives/tooltip` is the headless pair, and `@ember-joinery/test-support`
  adds `TooltipHarness` and the `hover()` and `unhover()` pointer helpers.
- a73065d: `Trace` is shadcn's Trace, the building block for reasoning, tool calls and sources: a list of
  `TraceLine`s (an icon, a title, a description, and `@status` `running`, `error` or `pending`,
  which colours, dims or shimmers it), whose parts are yielded and exported (`TraceIcon`,
  `TraceTitle`, `TraceDescription`), and `TraceCollapsible`, a row that expands, with its trigger
  (a chevron after the line that turns as it opens, which `@icon` replaces) and its content,
  controlled (`@open`, `@onOpenChange`) or not (`@defaultOpen`). A trace styles any link or
  trigger that wraps a line, a Dialog's, Sheet's, Drawer's, Popover's or menu's trigger included
  (through the root those render, which upstream's Radix roots don't). `@ember-joinery/test-support`
  adds `TraceHarness`, `TraceLineHarness` and `TraceCollapsibleHarness`.

### Patch Changes

- a73065d: `CollapsibleHarness` finds content that sits inside another component, as upstream's settings
  panel puts its `CollapsibleContent` inside a `FieldGroup`: when the content isn't among its own
  parts, `content` (and with it `isShown`, `text` and `controlsContent`) is the element the
  trigger's `aria-controls` names.
- a73065d: Every package's tarball carries Joinery's `LICENSE.md` and `NOTICE`, with the licences and
  notices of what it ports (shadcn/ui, ember-primitives, sonner, recharts and the rest), copied in
  from the repository's root by the package's `prepack`.

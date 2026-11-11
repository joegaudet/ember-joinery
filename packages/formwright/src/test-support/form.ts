import type { FormHarness } from '@ember-formwright/test-support'
import type { Harness } from '@ember-joinery/test-support'

/** A Formwright form harness class, as `@form` and `findForm()` take it. */
export type FormHarnessClass<T extends FormHarness> = (new (
  name?: string,
  parent?: FormHarness,
) => T) & { formName?: string }

/**
 * The element's parent in Joinery's component tree: a portalled or top-layer part names its
 * root in `data-test-jn-owner`, so a form inside a dialog's content is inside the dialog.
 */
function logicalParent(element: Element): Element | null {
  const owner = element.getAttribute('data-test-jn-owner')
  if (owner) {
    const root = element.ownerDocument.getElementById(owner)
    if (root && root !== element) return root
  }
  return element.parentElement
}

function isWithin(element: Element, scope: Element): boolean {
  const seen = new Set<Element>([element])
  for (let current = logicalParent(element); current; current = logicalParent(current)) {
    if (current === scope) return true
    if (seen.has(current)) return false
    seen.add(current)
  }
  return false
}

/** The first element matching `selector` inside a Joinery harness's component, in document order. */
function findWithin(harness: Harness, selector: string): Element | null {
  const scope = harness.element
  return (
    [...scope.ownerDocument.querySelectorAll(selector)].find(element => isWithin(element, scope)) ??
    null
  )
}

/**
 * A Formwright form inside a Joinery component, as a harness of `Type`: the form named `name`
 * (its `@name`), else `Type`'s `static formName`, else the first form inside the component.
 * The lookup is live and follows the component's portalled and top-layer parts, so it finds
 * a form in a dialog's or a sheet's content. Each call makes a new harness; `@form` keeps one.
 *
 *   const profile = findForm(dialog, ProfileForm)
 */
export function findForm<T extends FormHarness>(
  harness: Harness,
  Type: FormHarnessClass<T>,
  name?: string,
): T {
  // A FormHarness finds a nested form with `parent.element.querySelector(…)`; this parent
  // answers that query from the Joinery component's tree.
  const parent = {
    get element() {
      return { querySelector: (selector: string) => findWithin(harness, selector) }
    },
  }
  return new Type(name ?? Type.formName, parent as unknown as FormHarness)
}

const forms = new WeakMap<Harness, Map<string, FormHarness>>()

/** The form harness `@form` declares, created once per harness, property and class. */
function formOf<T extends FormHarness>(
  harness: Harness,
  key: string,
  Type: FormHarnessClass<T>,
  name: string | undefined,
): T {
  let byKey = forms.get(harness)
  if (!byKey) forms.set(harness, (byKey = new Map()))
  let form = byKey.get(key)
  if (!(form instanceof Type)) byKey.set(key, (form = findForm(harness, Type, name)))
  return form as T
}

/**
 * A decorator that works with both decorator implementations in use: the legacy ones Ember
 * apps compile with (`@form(ProfileForm) declare profile: ProfileForm`) and standard ones
 * (`@form(ProfileForm) accessor profile!: ProfileForm`).
 */
export interface FormDecorator<T> {
  <This extends Harness>(
    target: ClassAccessorDecoratorTarget<This, T>,
    context: ClassAccessorDecoratorContext<This, T>,
  ): ClassAccessorDecoratorResult<This, T>
  // Legacy: Babel passes the field's descriptor and defines the one this returns.
  (prototype: Harness, key: string | symbol, descriptor?: PropertyDescriptor): void
}

/**
 * Declares a Formwright form inside a Joinery harness, as `@child` declares a component: a
 * dialog's, a sheet's or a card's form, as a Formwright `FormHarness` subclass.
 *
 *   class EditProfile extends DialogHarness {
 *     static named = 'edit-profile'
 *     @child(ButtonHarness, 'save') declare save: ButtonHarness
 *     @form(ProfileForm) declare profile: ProfileForm
 *   }
 *
 *   await dialog.open()
 *   await dialog.profile.name.fillIn('Ada')
 *
 * The form is the one named `name` (its `@name`), else the class's `static formName`, else the
 * first form inside the component. The harness is created the first time you read it and kept;
 * its lookup is live and follows the component's portalled and top-layer parts. To nest one
 * Formwright form in another, use Formwright's own `@form` on the `FormHarness`.
 */
export function form<T extends FormHarness>(
  Type: FormHarnessClass<T>,
  name?: string,
): FormDecorator<T> {
  return ((_target: unknown, contextOrKey: string | symbol | ClassAccessorDecoratorContext) => {
    const key = String(typeof contextOrKey === 'object' ? contextOrKey.name : contextOrKey)
    function get(this: Harness): T {
      return formOf(this, key, Type, name)
    }
    return typeof contextOrKey === 'object'
      ? { get }
      : { configurable: true, enumerable: true, get }
  }) as FormDecorator<T>
}

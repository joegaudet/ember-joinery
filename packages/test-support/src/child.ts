import type { ChildOptions, Harness, HarnessClass } from './harness.ts'

/**
 * A decorator that works with both decorator implementations in use: the legacy ones Ember
 * apps compile with (`@child(ButtonHarness) declare save: ButtonHarness`, or a bare field in
 * JavaScript) and standard decorators (`@child(ButtonHarness) accessor save!: ButtonHarness`).
 */
export interface HarnessDecorator<T> {
  <This extends Harness>(
    target: ClassAccessorDecoratorTarget<This, T>,
    context: ClassAccessorDecoratorContext<This, T>,
  ): ClassAccessorDecoratorResult<This, T>
  // Legacy: Babel passes the field's descriptor and defines the one this returns; TypeScript
  // types the result as void.
  (prototype: Harness, key: string | symbol, descriptor?: PropertyDescriptor): void
}

/**
 * Declares a component inside this one. Reading the property gives its harness, created the
 * first time and kept, so it is the same object for the life of the parent. The lookup behind
 * it is live, and scoped to the parent: its root, and every part the parent owns wherever that
 * is rendered (`data-test-jn-owner`).
 *
 *   class EditProfile extends DialogHarness {
 *     static named = 'edit-profile'
 *     @child(ButtonHarness, 'save') declare save: ButtonHarness   // <Button @name="save">
 *     @child(InputHarness) declare email: InputHarness            // the first input
 *     @child(ButtonHarness, { index: 1 }) declare second: ButtonHarness
 *   }
 *
 * @param Type the child's harness class
 * @param options the child's `@name`, or `{ name, index }`. Without a name, the class's
 *   `static named`, or else the first instance inside the parent.
 */
export function child<T extends Harness>(
  Type: HarnessClass<T>,
  options?: ChildOptions,
): HarnessDecorator<T> {
  return ((_target: unknown, contextOrKey: string | symbol | ClassAccessorDecoratorContext) => {
    function get(this: Harness): T {
      return this.child(Type, options)
    }
    // A standard decorator gets a context object; a legacy one, the property key.
    return typeof contextOrKey === 'object'
      ? { get }
      : { configurable: true, enumerable: true, get }
  }) as HarnessDecorator<T>
}

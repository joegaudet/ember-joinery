import type { TOC } from '@ember/component/template-only'
import {
  Button,
  Card,
  Field,
  FieldDescription,
  FieldGroup,
  FieldLabel,
  Input,
} from '@ember-joinery/ember'

// Upstream's LoginForm spreads its props on the outer div, after its own classes: here a
// caller's attributes, with ...attributes.
const LoginForm: TOC<{ Element: HTMLDivElement }> = <template>
  <div class="flex flex-col gap-6" ...attributes>
    <Card as |c|>
      <c.Header>
        <c.Title>Login to your account</c.Title>
        <c.Description>
          Enter your email below to login to your account
        </c.Description>
      </c.Header>
      <c.Content>
        <form>
          <FieldGroup>
            <Field>
              <FieldLabel for="email">Email</FieldLabel>
              <Input id="email" type="email" placeholder="m@example.com" required />
            </Field>
            <Field>
              <div class="flex items-center">
                <FieldLabel for="password">Password</FieldLabel>
                <a href="#" class="ml-auto inline-block text-sm underline-offset-4 hover:underline">
                  Forgot your password?
                </a>
              </div>
              <Input id="password" type="password" required />
            </Field>
            <Field>
              <Button type="submit">Login</Button>
              <Button @variant="outline" type="button">
                Login with Google
              </Button>
              <FieldDescription class="text-center">
                Don't have an account?
                <a href="#">Sign up</a>
              </FieldDescription>
            </Field>
          </FieldGroup>
        </form>
      </c.Content>
    </Card>
  </div>
</template>

export default LoginForm

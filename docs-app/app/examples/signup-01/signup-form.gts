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

// Upstream's SignupForm spreads its props on the Card: here a caller's attributes.
const SignupForm: TOC<{ Element: HTMLElement }> = <template>
  <Card ...attributes as |c|>
    <c.Header>
      <c.Title>Create an account</c.Title>
      <c.Description>
        Enter your information below to create your account
      </c.Description>
    </c.Header>
    <c.Content>
      <form>
        <FieldGroup>
          <Field>
            <FieldLabel for="name">Full Name</FieldLabel>
            <Input id="name" type="text" placeholder="John Doe" required />
          </Field>
          <Field>
            <FieldLabel for="email">Email</FieldLabel>
            <Input id="email" type="email" placeholder="m@example.com" required />
            <FieldDescription>
              We'll use this to contact you. We will not share your email with anyone else.
            </FieldDescription>
          </Field>
          <Field>
            <FieldLabel for="password">Password</FieldLabel>
            <Input id="password" type="password" required />
            <FieldDescription>
              Must be at least 8 characters long.
            </FieldDescription>
          </Field>
          <Field>
            <FieldLabel for="confirm-password">
              Confirm Password
            </FieldLabel>
            <Input id="confirm-password" type="password" required />
            <FieldDescription>Please confirm your password.</FieldDescription>
          </Field>
          <FieldGroup>
            <Field>
              <Button type="submit">Create Account</Button>
              <Button @variant="outline" type="button">
                Sign up with Google
              </Button>
              <FieldDescription class="px-6 text-center">
                Already have an account?
                <a href="#">Sign in</a>
              </FieldDescription>
            </Field>
          </FieldGroup>
        </FieldGroup>
      </form>
    </c.Content>
  </Card>
</template>

export default SignupForm

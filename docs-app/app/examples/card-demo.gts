import { Button, Card, Input, Label } from '@ember-joinery/ember'

<template>
  <Card class="w-full max-w-sm" as |c|>
    <c.Header>
      <c.Title>Login to your account</c.Title>
      <c.Description>
        Enter your email below to login to your account
      </c.Description>
      <c.Action>
        <Button @variant="link">Sign Up</Button>
      </c.Action>
    </c.Header>
    <c.Content>
      <form>
        <div class="flex flex-col gap-6">
          <div class="grid gap-2">
            <Label for="email">Email</Label>
            <Input id="email" type="email" placeholder="m@example.com" required />
          </div>
          <div class="grid gap-2">
            <div class="flex items-center">
              <Label for="password">Password</Label>
              <a href="#" class="ml-auto inline-block text-sm underline-offset-4 hover:underline">
                Forgot your password?
              </a>
            </div>
            <Input id="password" type="password" required />
          </div>
        </div>
      </form>
    </c.Content>
    <c.Footer class="flex-col gap-2">
      <Button type="submit" class="w-full">
        Login
      </Button>
      <Button @variant="outline" class="w-full">
        Login with Google
      </Button>
    </c.Footer>
  </Card>
</template>

import { Button, Card, Input, Label } from '@ember-joinery/ember'

// Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
// Arabic: its preview opens in Arabic, and the frame has no language picker. These are its
// strings, upstream's `t`. Upstream puts dir on the card from its language picker; Joinery's
// components take their direction from the nearest dir, so the card needs none of its own.
const t = {
  title: 'تسجيل الدخول إلى حسابك',
  description: 'أدخل بريدك الإلكتروني أدناه لتسجيل الدخول إلى حسابك',
  signUp: 'إنشاء حساب',
  email: 'البريد الإلكتروني',
  emailPlaceholder: 'm@example.com',
  password: 'كلمة المرور',
  forgotPassword: 'نسيت كلمة المرور؟',
  login: 'تسجيل الدخول',
  loginWithGoogle: 'تسجيل الدخول باستخدام Google',
}

<template>
  <Card class="w-full max-w-sm" as |c|>
    <c.Header>
      <c.Title>{{t.title}}</c.Title>
      <c.Description>{{t.description}}</c.Description>
      <c.Action>
        <Button @variant="link">{{t.signUp}}</Button>
      </c.Action>
    </c.Header>
    <c.Content>
      <form>
        <div class="flex flex-col gap-6">
          <div class="grid gap-2">
            <Label for="email-rtl">{{t.email}}</Label>
            <Input id="email-rtl" type="email" placeholder={{t.emailPlaceholder}} required />
          </div>
          <div class="grid gap-2">
            <div class="flex items-center">
              <Label for="password-rtl">{{t.password}}</Label>
              <a href="#" class="ms-auto inline-block text-sm underline-offset-4 hover:underline">
                {{t.forgotPassword}}
              </a>
            </div>
            <Input id="password-rtl" type="password" required />
          </div>
        </div>
      </form>
    </c.Content>
    <c.Footer class="flex-col gap-2">
      <Button type="submit" class="w-full">
        {{t.login}}
      </Button>
      <Button @variant="outline" class="w-full">
        {{t.loginWithGoogle}}
      </Button>
    </c.Footer>
  </Card>
</template>

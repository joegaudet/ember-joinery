import { Button, DirectionProvider } from '@ember-joinery/ember'

<template>
  {{!
    Joinery's own example. Upstream's (card-rtl) is a login Card, which comes with Card, Input
    and Label; until they land, this is its text, and its buttons, right to left. The title is
    a div, as Card's title is.
  }}
  <DirectionProvider @direction="rtl">
    <div class="flex w-full max-w-sm flex-col gap-6 rounded-xl border p-6">
      <div class="flex items-start gap-2">
        <div class="flex flex-col gap-1">
          <div class="leading-none font-semibold">تسجيل الدخول إلى حسابك</div>
          <p class="text-sm text-muted-foreground">
            أدخل بريدك الإلكتروني أدناه لتسجيل الدخول إلى حسابك
          </p>
        </div>
        <Button @variant="link" class="ms-auto">إنشاء حساب</Button>
      </div>
      <div class="flex flex-col gap-2">
        <Button type="submit" class="w-full">تسجيل الدخول</Button>
        <Button @variant="outline" class="w-full">تسجيل الدخول باستخدام Google</Button>
      </div>
    </div>
  </DirectionProvider>
</template>

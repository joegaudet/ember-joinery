import { RefreshCw } from 'lucide'
import {
  Button,
  Card,
  Field,
  FieldDescription,
  FieldLabel,
  Icon,
  InputOTP,
} from '@ember-joinery/ember'

<template>
  {{!
    Upstream's InputOTPSeparator spreads its props after its own className, so this example's
    className="mx-2" replaces "cn-input-otp-separator flex items-center": on ui.shadcn.com the
    separator is a plain block with lucide's default 24px icon. Joinery's separator adds a class
    to its own instead, so block and [&_svg]:size-6 show it as upstream's shows.
  }}
  <Card class="mx-auto max-w-md" as |card|>
    <card.Header>
      <card.Title>Verify your login</card.Title>
      <card.Description>
        Enter the verification code we sent to your email address:
        <span class="font-medium">m@example.com</span>.
      </card.Description>
    </card.Header>
    <card.Content>
      <Field>
        <div class="flex items-center justify-between">
          <FieldLabel for="otp-verification">
            Verification code
          </FieldLabel>
          <Button @variant="outline" @size="xs">
            <Icon @icon={{RefreshCw}} />
            Resend Code
          </Button>
        </div>
        <InputOTP @maxLength={{6}} id="otp-verification" required as |otp|>
          <otp.Group
            class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl"
          >
            <otp.Slot @index={{0}} />
            <otp.Slot @index={{1}} />
            <otp.Slot @index={{2}} />
          </otp.Group>
          <otp.Separator class="mx-2 block [&_svg]:size-6" />
          <otp.Group
            class="*:data-[slot=input-otp-slot]:h-12 *:data-[slot=input-otp-slot]:w-11 *:data-[slot=input-otp-slot]:text-xl"
          >
            <otp.Slot @index={{3}} />
            <otp.Slot @index={{4}} />
            <otp.Slot @index={{5}} />
          </otp.Group>
        </InputOTP>
        <FieldDescription>
          <a href="#">I no longer have access to this email address.</a>
        </FieldDescription>
      </Field>
    </card.Content>
    <card.Footer>
      <Field>
        <Button type="submit" class="w-full">
          Verify
        </Button>
        <div class="text-sm text-muted-foreground">
          Having trouble signing in?
          <a href="#" class="underline underline-offset-4 transition-colors hover:text-primary">
            Contact support
          </a>
        </div>
      </Field>
    </card.Footer>
  </Card>
</template>

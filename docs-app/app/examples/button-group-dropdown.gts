import {
  AlertTriangle,
  Check,
  ChevronDown,
  Copy,
  Share,
  Trash,
  UserRoundX,
  VolumeOff,
} from 'lucide'
import { Button, ButtonGroup, DropdownMenu, Icon } from '@ember-joinery/ember'

<template>
  {{! Upstream's icon-only trigger has no name; an icon-only button needs one, so this one is named. }}
  <ButtonGroup>
    <Button @variant="outline">Follow</Button>
    <DropdownMenu as |m|>
      <Button @variant="outline" class="pl-2!" aria-label="More" {{m.trigger}}>
        <Icon @icon={{ChevronDown}} />
      </Button>
      <m.Content @align="end" class="w-44">
        <m.Group>
          <m.Item>
            <Icon @icon={{VolumeOff}} />
            Mute Conversation
          </m.Item>
          <m.Item>
            <Icon @icon={{Check}} />
            Mark as Read
          </m.Item>
          <m.Item>
            <Icon @icon={{AlertTriangle}} />
            Report Conversation
          </m.Item>
          <m.Item>
            <Icon @icon={{UserRoundX}} />
            Block User
          </m.Item>
          <m.Item>
            <Icon @icon={{Share}} />
            Share Conversation
          </m.Item>
          <m.Item>
            <Icon @icon={{Copy}} />
            Copy Conversation
          </m.Item>
        </m.Group>
        <m.Separator />
        <m.Group>
          <m.Item @variant="destructive">
            <Icon @icon={{Trash}} />
            Delete Conversation
          </m.Item>
        </m.Group>
      </m.Content>
    </DropdownMenu>
  </ButtonGroup>
</template>

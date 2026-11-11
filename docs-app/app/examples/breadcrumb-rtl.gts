import { ChevronDown, Dot } from 'lucide'
import { Breadcrumb, DropdownMenu, Icon } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  home: 'الرئيسية',
  components: 'المكونات',
  documentation: 'التوثيق',
  themes: 'السمات',
  github: 'جيت هاب',
  breadcrumb: 'مسار التنقل',
}

<template>
  {{! Upstream's links are Next's <Link> (asChild); b.Link renders the same <a>. }}
  <Breadcrumb dir="rtl" as |b|>
    <b.List>
      <b.Item>
        <b.Link href="/">{{t.home}}</b.Link>
      </b.Item>
      <b.Separator>
        <Icon @icon={{Dot}} />
      </b.Separator>
      <b.Item>
        <DropdownMenu as |m|>
          <button type="button" class="flex items-center gap-1" {{m.trigger}}>
            {{t.components}}
            <Icon @icon={{ChevronDown}} class="size-3.5" />
          </button>
          <m.Content>
            <m.Group>
              <m.Item>{{t.documentation}}</m.Item>
              <m.Item>{{t.themes}}</m.Item>
              <m.Item>{{t.github}}</m.Item>
            </m.Group>
          </m.Content>
        </DropdownMenu>
      </b.Item>
      <b.Separator>
        <Icon @icon={{Dot}} />
      </b.Separator>
      <b.Item>
        <b.Page>{{t.breadcrumb}}</b.Page>
      </b.Item>
    </b.List>
  </Breadcrumb>
</template>

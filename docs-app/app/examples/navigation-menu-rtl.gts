import type { TOC } from '@ember/component/template-only'
import { NavigationMenu, navigationMenuTriggerStyle } from '@ember-joinery/ember'
import type { NavigationMenuBlockParams } from '@ember-joinery/ember'

// Upstream's Arabic, the language its preview opens in (it also offers Hebrew and English).
const t = {
  gettingStarted: 'البدء',
  introduction: 'مقدمة',
  introductionDesc: 'مكونات قابلة لإعادة الاستخدام مبنية باستخدام Tailwind CSS.',
  installation: 'التثبيت',
  installationDesc: 'كيفية تثبيت التبعيات وتنظيم تطبيقك.',
  typography: 'الطباعة',
  typographyDesc: 'أنماط للعناوين والفقرات والقوائم...إلخ',
  components: 'المكونات',
  docs: 'الوثائق',
}

const components = [
  {
    title: 'حوار التنبيه',
    description: 'حوار نافذة يقطع المستخدم بمحتوى مهم ويتوقع استجابة.',
    href: '/docs/primitives/alert-dialog',
  },
  {
    title: 'بطاقة التحويم',
    description: 'للمستخدمين المبصرين لمعاينة المحتوى المتاح خلف الرابط.',
    href: '/docs/primitives/hover-card',
  },
  {
    title: 'التقدم',
    description: 'يعرض مؤشرًا يوضح تقدم إتمام المهمة، عادةً يتم عرضه كشريط تقدم.',
    href: '/docs/primitives/progress',
  },
  {
    title: 'منطقة التمرير',
    description: 'يفصل المحتوى بصريًا أو دلاليًا.',
    href: '/docs/primitives/scroll-area',
  },
  {
    title: 'التبويبات',
    description:
      'مجموعة من أقسام المحتوى المتعددة الطبقات—المعروفة بألواح التبويب—التي يتم عرضها واحدة في كل مرة.',
    href: '/docs/primitives/tabs',
  },
  {
    title: 'تلميح',
    description:
      'نافذة منبثقة تعرض معلومات متعلقة بعنصر عندما يتلقى العنصر التركيز على لوحة المفاتيح أو عند تحويم الماوس فوقه.',
    href: '/docs/primitives/tooltip',
  },
]

/** Upstream's `ListItem`: a link with a title and a line or two of description. */
const ListItem: TOC<{
  Args: { Link: NavigationMenuBlockParams['Link']; href: string; title: string }
  Blocks: { default: [] }
  Element: HTMLLIElement
}> = <template>
  <li ...attributes>
    <@Link href={{@href}}>
      <div class="flex flex-col gap-1 text-sm">
        <div class="leading-none font-medium">{{@title}}</div>
        <div class="line-clamp-2 text-muted-foreground">{{yield}}</div>
      </div>
    </@Link>
  </li>
</template>

<template>
  <NavigationMenu as |n|>
    <n.List>
      <n.Item as |item|>
        <item.Trigger>{{t.gettingStarted}}</item.Trigger>
        <item.Content>
          <ul class="w-96">
            <ListItem @Link={{n.Link}} @href="/docs" @title={{t.introduction}}>
              {{t.introductionDesc}}
            </ListItem>
            <ListItem @Link={{n.Link}} @href="/docs/installation" @title={{t.installation}}>
              {{t.installationDesc}}
            </ListItem>
            <ListItem @Link={{n.Link}} @href="/docs/primitives/typography" @title={{t.typography}}>
              {{t.typographyDesc}}
            </ListItem>
          </ul>
        </item.Content>
      </n.Item>
      <n.Item class="hidden md:flex" as |item|>
        <item.Trigger>{{t.components}}</item.Trigger>
        <item.Content>
          <ul class="grid w-[400px] gap-2 md:w-[500px] md:grid-cols-2 lg:w-[600px]">
            {{#each components as |entry|}}
              <ListItem @Link={{n.Link}} @title={{entry.title}} @href={{entry.href}}>
                {{entry.description}}
              </ListItem>
            {{/each}}
          </ul>
        </item.Content>
      </n.Item>
      <n.Item>
        <n.Link href="/docs" class={{(navigationMenuTriggerStyle)}}>{{t.docs}}</n.Link>
      </n.Item>
    </n.List>
  </NavigationMenu>
</template>

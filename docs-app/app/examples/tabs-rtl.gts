import { Card, Tabs } from '@ember-joinery/ember'

// Shown right to left (the frame's RTL switch, or dir="rtl" on any ancestor), in upstream's
// Arabic: its preview opens in Arabic, and the frame has no language picker. These are its
// strings, upstream's `t`, so the tabs' block param is `tabs`. Upstream puts dir on the tabs,
// the list and each card from its language picker; Joinery's components take their direction
// from the nearest dir, so they need none of their own.
const t = {
  overview: 'نظرة عامة',
  analytics: 'التحليلات',
  reports: 'التقارير',
  settings: 'الإعدادات',
  overviewTitle: 'نظرة عامة',
  overviewDesc: 'عرض مقاييسك الرئيسية وأنشطة المشروع الأخيرة. تتبع التقدم عبر جميع مشاريعك النشطة.',
  overviewContent: 'لديك ١٢ مشروعًا نشطًا و٣ مهام معلقة.',
  analyticsTitle: 'التحليلات',
  analyticsDesc: 'تتبع مقاييس الأداء ومشاركة المستخدمين. راقب الاتجاهات وحدد فرص النمو.',
  analyticsContent: 'زادت مشاهدات الصفحة بنسبة ٢٥٪ مقارنة بالشهر الماضي.',
  reportsTitle: 'التقارير',
  reportsDesc: 'إنشاء وتنزيل تقاريرك التفصيلية. تصدير البيانات بتنسيقات متعددة للتحليل.',
  reportsContent: 'لديك ٥ تقارير جاهزة ومتاحة للتصدير.',
  settingsTitle: 'الإعدادات',
  settingsDesc: 'إدارة تفضيلات حسابك وخياراته. تخصيص تجربتك لتناسب احتياجاتك.',
  settingsContent: 'تكوين الإشعارات والأمان والسمات.',
}

<template>
  <Tabs @defaultValue="overview" class="w-full max-w-sm" as |tabs|>
    <tabs.List>
      <tabs.Trigger @value="overview">{{t.overview}}</tabs.Trigger>
      <tabs.Trigger @value="analytics">{{t.analytics}}</tabs.Trigger>
      <tabs.Trigger @value="reports">{{t.reports}}</tabs.Trigger>
      <tabs.Trigger @value="settings">{{t.settings}}</tabs.Trigger>
    </tabs.List>
    <tabs.Content @value="overview">
      <Card as |card|>
        <card.Header>
          <card.Title>{{t.overviewTitle}}</card.Title>
          <card.Description>{{t.overviewDesc}}</card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          {{t.overviewContent}}
        </card.Content>
      </Card>
    </tabs.Content>
    <tabs.Content @value="analytics">
      <Card as |card|>
        <card.Header>
          <card.Title>{{t.analyticsTitle}}</card.Title>
          <card.Description>{{t.analyticsDesc}}</card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          {{t.analyticsContent}}
        </card.Content>
      </Card>
    </tabs.Content>
    <tabs.Content @value="reports">
      <Card as |card|>
        <card.Header>
          <card.Title>{{t.reportsTitle}}</card.Title>
          <card.Description>{{t.reportsDesc}}</card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          {{t.reportsContent}}
        </card.Content>
      </Card>
    </tabs.Content>
    <tabs.Content @value="settings">
      <Card as |card|>
        <card.Header>
          <card.Title>{{t.settingsTitle}}</card.Title>
          <card.Description>{{t.settingsDesc}}</card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          {{t.settingsContent}}
        </card.Content>
      </Card>
    </tabs.Content>
  </Tabs>
</template>

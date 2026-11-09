import { Card, Tabs } from '@ember-joinery/ember'

<template>
  <Tabs @defaultValue="overview" class="w-[400px]" as |t|>
    <t.List>
      <t.Trigger @value="overview">Overview</t.Trigger>
      <t.Trigger @value="analytics">Analytics</t.Trigger>
      <t.Trigger @value="reports">Reports</t.Trigger>
      <t.Trigger @value="settings">Settings</t.Trigger>
    </t.List>
    <t.Content @value="overview">
      <Card as |card|>
        <card.Header>
          <card.Title>Overview</card.Title>
          <card.Description>
            View your key metrics and recent project activity. Track progress across all your active
            projects.
          </card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          You have 12 active projects and 3 pending tasks.
        </card.Content>
      </Card>
    </t.Content>
    <t.Content @value="analytics">
      <Card as |card|>
        <card.Header>
          <card.Title>Analytics</card.Title>
          <card.Description>
            Track performance and user engagement metrics. Monitor trends and identify growth
            opportunities.
          </card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          Page views are up 25% compared to last month.
        </card.Content>
      </Card>
    </t.Content>
    <t.Content @value="reports">
      <Card as |card|>
        <card.Header>
          <card.Title>Reports</card.Title>
          <card.Description>
            Generate and download your detailed reports. Export data in multiple formats for
            analysis.
          </card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          You have 5 reports ready and available to export.
        </card.Content>
      </Card>
    </t.Content>
    <t.Content @value="settings">
      <Card as |card|>
        <card.Header>
          <card.Title>Settings</card.Title>
          <card.Description>
            Manage your account preferences and options. Customize your experience to fit your
            needs.
          </card.Description>
        </card.Header>
        <card.Content class="text-sm text-muted-foreground">
          Configure notifications, security, and themes.
        </card.Content>
      </Card>
    </t.Content>
  </Tabs>
</template>

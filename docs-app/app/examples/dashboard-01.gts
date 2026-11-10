import { htmlSafe } from '@ember/template'
import { SidebarProvider } from '@ember-joinery/ember'
import AppSidebar from './dashboard-01/app-sidebar.gts'
import ChartAreaInteractive from './dashboard-01/chart-area-interactive.gts'
import DataTable from './dashboard-01/data-table.gts'
import SectionCards from './dashboard-01/section-cards.gts'
import SiteHeader from './dashboard-01/site-header.gts'
import data from './dashboard-01/data.ts'

const style = htmlSafe(
  '--sidebar-width: calc(var(--spacing) * 72); --header-height: calc(var(--spacing) * 12)',
)

<template>
  <SidebarProvider style={{style}} as |sidebar|>
    <AppSidebar @sidebar={{sidebar}} @variant="inset" />
    <sidebar.Inset>
      <SiteHeader @sidebar={{sidebar}} />
      <div class="flex flex-1 flex-col">
        <div class="@container/main flex flex-1 flex-col gap-2">
          <div class="flex flex-col gap-4 py-4 md:gap-6 md:py-6">
            <SectionCards />
            <div class="px-4 lg:px-6">
              <ChartAreaInteractive />
            </div>
            <DataTable @data={{data}} />
          </div>
        </div>
      </div>
    </sidebar.Inset>
  </SidebarProvider>
</template>

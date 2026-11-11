import { htmlSafe } from '@ember/template'
import { SidebarProvider, Toaster } from '@ember-joinery/ember'
import AppSidebar from '../components/demo/dashboard/app-sidebar.gts'
import ChartAreaInteractive from '../components/demo/dashboard/chart-area-interactive.gts'
import DataTable from '../components/demo/dashboard/data-table.gts'
import SectionCards from '../components/demo/dashboard/section-cards.gts'
import SiteHeader from '../components/demo/dashboard/site-header.gts'
import data from '../components/demo/dashboard/data.ts'

const style = htmlSafe(
  '--sidebar-width: calc(var(--spacing) * 72); --header-height: calc(var(--spacing) * 12)',
)

/**
 * The live demo: the guide's dashboard block (dashboard-01), as an app copies it in, with the
 * settings block (sidebar-13) over it at /settings, through the outlet. Their layout is
 * Tailwind's utilities, compiled for this root alone (styles/demo.css).
 */
<template>
  <div data-jn-demo>
    <SidebarProvider style={{style}} @name="demo" as |sidebar|>
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
    {{outlet}}
    <Toaster />
  </div>
</template>

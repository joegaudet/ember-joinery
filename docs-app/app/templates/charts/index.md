# Charts

`@ember-joinery/chart` draws shadcn's charts as declarative Glimmer SVG on `d3-scale` and
`d3-shape`, with an API shaped like recharts: area, bar, line, pie, radar and radial charts, with
a tooltip, a legend and a config that maps each series to a `--chart-N` colour. It is an add-on,
so apps that draw no charts don't install d3.

<SectionList @section="charts" />

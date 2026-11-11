import { Select } from '@ember-joinery/ember'

<template>
  {{! Named with aria-label: a combobox isn't named by its text, and upstream's has no label. }}
  <Select as |s|>
    <s.Trigger class="w-full max-w-64" aria-label="Timezone">
      <s.Value @placeholder="Select a timezone" />
    </s.Trigger>
    <s.Content>
      <s.Group>
        <s.Label>North America</s.Label>
        <s.Item @value="est">Eastern Standard Time</s.Item>
        <s.Item @value="cst">Central Standard Time</s.Item>
        <s.Item @value="mst">Mountain Standard Time</s.Item>
        <s.Item @value="pst">Pacific Standard Time</s.Item>
        <s.Item @value="akst">Alaska Standard Time</s.Item>
        <s.Item @value="hst">Hawaii Standard Time</s.Item>
      </s.Group>
      <s.Group>
        <s.Label>Europe & Africa</s.Label>
        <s.Item @value="gmt">Greenwich Mean Time</s.Item>
        <s.Item @value="cet">Central European Time</s.Item>
        <s.Item @value="eet">Eastern European Time</s.Item>
        <s.Item @value="west">Western European Summer Time</s.Item>
        <s.Item @value="cat">Central Africa Time</s.Item>
        <s.Item @value="eat">East Africa Time</s.Item>
      </s.Group>
      <s.Group>
        <s.Label>Asia</s.Label>
        <s.Item @value="msk">Moscow Time</s.Item>
        <s.Item @value="ist">India Standard Time</s.Item>
        <s.Item @value="cst_china">China Standard Time</s.Item>
        <s.Item @value="jst">Japan Standard Time</s.Item>
        <s.Item @value="kst">Korea Standard Time</s.Item>
        <s.Item @value="ist_indonesia">
          Indonesia Central Standard Time
        </s.Item>
      </s.Group>
      <s.Group>
        <s.Label>Australia & Pacific</s.Label>
        <s.Item @value="awst">Australian Western Standard Time</s.Item>
        <s.Item @value="acst">Australian Central Standard Time</s.Item>
        <s.Item @value="aest">Australian Eastern Standard Time</s.Item>
        <s.Item @value="nzst">New Zealand Standard Time</s.Item>
        <s.Item @value="fjt">Fiji Time</s.Item>
      </s.Group>
      <s.Group>
        <s.Label>South America</s.Label>
        <s.Item @value="art">Argentina Time</s.Item>
        <s.Item @value="bot">Bolivia Time</s.Item>
        <s.Item @value="brt">Brasilia Time</s.Item>
        <s.Item @value="clt">Chile Standard Time</s.Item>
      </s.Group>
    </s.Content>
  </Select>
</template>

import { Pagination } from '@ember-joinery/ember'

<template>
  <Pagination as |p|>
    <p.Content>
      <p.Item>
        <p.Link href="#">1</p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#" @isActive={{true}}>
          2
        </p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#">3</p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#">4</p.Link>
      </p.Item>
      <p.Item>
        <p.Link href="#">5</p.Link>
      </p.Item>
    </p.Content>
  </Pagination>
</template>

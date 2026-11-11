import type { TOC } from '@ember/component/template-only'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { RotateCw, X } from 'lucide'
import Button from '@ember-joinery/ember/components/button'
import Icon from '@ember-joinery/ember/components/icon'
import Item, { ItemGroup } from '@ember-joinery/ember/components/item'
import Progress from '@ember-joinery/ember/components/progress'
import { fileIcon } from './labels.ts'
import type { FileUploadContext } from './context.ts'

export interface FileUploadQueueSignature {
  Args: {
    /** The `<FileUpload>` it belongs to; `u.Queue` comes with it. */
    upload: FileUploadContext
  }
  /**
   * An `ItemGroup` (`role="list"`), rendered only while a file is uploading or has failed, and
   * `aria-busy` while one uploads.
   */
  Element: HTMLElement
}

const call = <A, R>(fn: (arg: A) => R, arg: A): R => fn(arg)
const isError = (state: string): boolean => state === 'error'

/**
 * The files `@upload` is sending, one shadcn Item each, like the file list's: a preview or an
 * icon, the name, its kind and size, and a Progress bar across the row's foot that follows
 * ember-file-upload's `progress`. A failed upload shows its error, with buttons that retry it and
 * remove it (none while the `<FileUpload>` is disabled). A file leaves the queue for the list once
 * its upload resolves.
 */
const FileUploadQueue: TOC<FileUploadQueueSignature> = <template>
  {{#if @upload.state.uploads.length}}
    <ItemGroup
      class="jn-file-upload-queue"
      aria-busy={{if @upload.state.isUploading "true"}}
      data-test-jn-part="queue"
      ...attributes
    >
      {{#each @upload.state.uploads as |upload|}}
        <Item
          @variant="outline"
          @size="sm"
          @name={{upload.name}}
          role="listitem"
          class="jn-file-upload-file"
          data-state={{upload.state}}
          as |i|
        >
          <i.Media @variant="image" class="jn-file-upload-file-media">
            {{#let (call @upload.state.previewOf upload.file) as |preview|}}
              {{#if preview}}
                <img src={{preview}} alt="" />
              {{else}}
                <Icon @icon={{fileIcon upload.name upload.file.type}} />
              {{/if}}
            {{/let}}
          </i.Media>
          <i.Content class="jn-file-upload-file-content">
            <i.Title class="jn-file-upload-file-title">
              <span class="jn-file-upload-file-name">{{upload.name}}</span>
            </i.Title>
            <i.Description class="jn-file-upload-file-description">
              {{#if (isError upload.state)}}
                {{upload.error}}
              {{else}}
                {{call @upload.state.kindOf upload.name}}
                ·
                {{call @upload.state.sizeOf upload.file}}
              {{/if}}
            </i.Description>
          </i.Content>
          {{#if (isError upload.state)}}
            {{#unless @upload.state.disabled}}
              <i.Actions>
                <Button
                  @variant="ghost"
                  @size="icon-sm"
                  @name="retry"
                  class="jn-file-upload-retry"
                  aria-label={{call @upload.labels.retryLabel upload.name}}
                  {{on "click" (fn @upload.state.retry upload)}}
                >
                  <Icon @icon={{RotateCw}} />
                </Button>
                <Button
                  @variant="ghost"
                  @size="icon-sm"
                  @name="remove"
                  class="jn-file-upload-remove"
                  aria-label={{call @upload.labels.removeLabel upload.name}}
                  {{on "click" (fn @upload.state.dismiss upload)}}
                >
                  <Icon @icon={{X}} />
                </Button>
              </i.Actions>
            {{/unless}}
          {{else}}
            <i.Footer>
              <Progress
                @value={{upload.progress}}
                class="jn-file-upload-progress"
                aria-label={{call @upload.labels.progressLabel upload.name}}
              />
            </i.Footer>
          {{/if}}
        </Item>
      {{/each}}
    </ItemGroup>
  {{/if}}
</template>

export default FileUploadQueue

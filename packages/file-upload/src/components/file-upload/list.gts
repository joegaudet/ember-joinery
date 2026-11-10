import type { TOC } from '@ember/component/template-only'
import { fn } from '@ember/helper'
import { on } from '@ember/modifier'
import { X } from 'lucide'
import Button from '@ember-joinery/ember/components/button'
import Icon from '@ember-joinery/ember/components/icon'
import Item, { ItemGroup } from '@ember-joinery/ember/components/item'
import { fileIcon } from './labels.ts'
import type { FileUploadContext } from './context.ts'

export interface FileUploadListSignature {
  Args: {
    /** The `<FileUpload>` it belongs to; `u.List` comes with it. */
    upload: FileUploadContext
  }
  /** An `ItemGroup` (`role="list"`), rendered only while the value holds a file. */
  Element: HTMLElement
}

const call = <A, R>(fn: (arg: A) => R, arg: A): R => fn(arg)

/**
 * The files the value holds, one shadcn Item each (`role="listitem"`, outlined and small, in an
 * `ItemGroup`): a preview of an image, or an icon for its kind, its name, its kind and size, and
 * a button that removes it. A disabled `<FileUpload>` shows no remove buttons.
 */
const FileUploadList: TOC<FileUploadListSignature> = <template>
  {{#if @upload.state.files.length}}
    <ItemGroup class="jn-file-upload-list" data-test-jn-part="list" ...attributes>
      {{! Keyed on the value, so a row (and the focus on its button) stays when others change. }}
      {{#each @upload.state.files key="value" as |entry|}}
        <Item
          @variant="outline"
          @size="sm"
          @name={{entry.name}}
          role="listitem"
          class="jn-file-upload-file"
          data-state="done"
          as |i|
        >
          <i.Media @variant="image" class="jn-file-upload-file-media">
            {{#if entry.preview}}
              <img src={{entry.preview}} alt="" />
            {{else}}
              <Icon @icon={{fileIcon entry.name entry.value.type}} />
            {{/if}}
          </i.Media>
          <i.Content class="jn-file-upload-file-content">
            <i.Title class="jn-file-upload-file-title">
              <span class="jn-file-upload-file-name">{{entry.name}}</span>
            </i.Title>
            <i.Description>
              {{entry.kind}}{{#if entry.size}} · {{entry.size}}{{/if}}
            </i.Description>
          </i.Content>
          {{#unless @upload.state.disabled}}
            <i.Actions>
              <Button
                @variant="ghost"
                @size="icon-sm"
                @name="remove"
                class="jn-file-upload-remove"
                aria-label={{call @upload.labels.removeLabel entry.name}}
                {{on "click" (fn @upload.state.remove entry.value)}}
              >
                <Icon @icon={{X}} />
              </Button>
            </i.Actions>
          {{/unless}}
        </Item>
      {{/each}}
    </ItemGroup>
  {{/if}}
</template>

export default FileUploadList

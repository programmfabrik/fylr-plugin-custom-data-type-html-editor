# fylr-plugin-custom-data-type-html-editor

Adds the custom data type **HTML Editor** to fylr. A field of this type stores HTML, and
editors write it in a WYSIWYG editor instead of typing markup: headings, bold and italic,
lists, links, text and background colours, alignment and images.

The editor is [TinyMCE 5](https://www.tiny.cloud/docs/tinymce/5/), bundled with the plugin —
no account, no API key and no request to tiny.cloud at runtime.

The text content of the field is indexed, so records are found by the fulltext search and by
the field's own filters in the expert search.

## Installation

Install it in the Plugin Manager, either from the release ZIP or, so the instance picks up
new versions on its own, from the URL:

```
https://github.com/programmfabrik/fylr-plugin-custom-data-type-html-editor/releases/latest/download/fylr-plugin-custom-data-type-html-editor.zip
```

Enable the plugin afterwards. Nothing else has to be set up: no server-side component, no
license feature and no exec server.

## Setup

**Data model.** Add a field and pick the data type **HTML Editor** under "Additional data
types". The field needs no further settings.

**Mask.** In the mask, switch the field on for **Edit** (so it can be written) and for
**Detail** (so the rendered HTML shows in the detail view). The two filters in the expert
search come with **Advanced search**.

**Base configuration** (group *CSS*, section *HTML Editor*):

| Setting | Meaning |
| --- | --- |
| `custom_css_url` | URL of a stylesheet, loaded into the editor, into the detail view and into the preview window. Use it to render the content with your own fonts, colours and spacing. Has to start with `http://` or `https://`. |

Without a custom stylesheet the content is rendered with the plugin's own base style, which
follows the fylr typography.

## Usage

**Editing.** The field shows the editor inline in the record editor. For long texts,
*Open the HTML Editor in a new window* gives the editor the whole screen; the record cannot
be saved while that window is open, and its content is taken over with *Apply*.

Images can be pasted, dropped onto the editor or added by URL. A pasted or dropped image is
stored inside the HTML as a data URI, so it travels with the record and is not a fylr asset —
keep an eye on the size of what is pasted.

**Reading.** The detail view renders the HTML and grows to the height of its content.
*Open the content in a new window* shows it on its own, which is handy for long texts.

**Searching.** The text of the field is part of the fulltext search. In the expert search the
field has its own input plus the two toggles that search for records where it has data and for records where it is empty.

**Exporting.** The field is available for printing and for the PDF Creator.

## Development

Built with [fylr-build-plugin](https://github.com/programmfabrik/fylr-build-plugin):

```sh
make build   # assemble build/custom-data-type-html-editor/, loadable via plugin.paths
make zip     # build the release zip
make loca    # pull the loca CSV from its Google Sheets master
```

A release is cut by publishing a GitHub release; the workflow builds the zip and attaches it.

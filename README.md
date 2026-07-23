# custom-data-type-html-editor

A fylr plugin that adds the custom data type "HTML Editor". With this data type editors can create and store HTML content directly in a field. The content is edited in a WYSIWYG editor, so formatted text can be maintained without writing markup by hand.

The editor is based on [TinyMCE](https://www.tiny.cloud/).

In the record editor the field shows an embedded editor. The editor can also be opened in a separate window. The detail view renders the stored HTML. The rendered content can also be opened in a separate window. The text content of the field is indexed, so records can be found with the fulltext search.

## Configuration

### Data model

Add a field of type "HTML Editor" to an object type. No further field settings are needed.

### Base configuration

The plugin settings are found in the base configuration in the section "HTML Editor".

* **Custom CSS URL**: an optional URL of a stylesheet. The stylesheet is loaded in the editor and in the rendered output. Use it to style the HTML content, for example with your own fonts and colors. The URL must start with `http://` or `https://`.

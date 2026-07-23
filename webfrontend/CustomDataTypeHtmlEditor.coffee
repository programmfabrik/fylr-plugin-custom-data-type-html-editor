class CustomDataTypeHtmlEditor extends CustomDataType

	getCustomDataTypeName: ->
		"custom:base.custom-data-type-html-editor.html_editor"

	getCustomDataTypeNameLocalized: ->
		$$("custom.data.type.html-editor.name")

	getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
		return []

	renderFieldAsGroup: ->
		return false

	supportsStandard: ->
		return false

	supportsPrinting: ->
		true

	renderSearchInput: (data, opts={}) ->
		return new SearchToken(
			column: @
			data: data
			fields: opts.fields
		).getInput().DOM

	getFieldNamesForSearch: ->
		@__getFieldNames()

	getFieldNamesForSuggest: ->
		@__getFieldNames()

	getQueryFieldBadge: (data) =>
		if data["#{@name()}:unset"]
			value = $$("text.column.badge.without")
		else
			value = data[@name()]

		badge =
			name: @nameLocalized()
			value: value
		return badge

	getSearchFilter: (data, key=@name()) ->
		filter = super(data, key)
		if filter
			return filter

		if CUI.util.isEmpty(data[key])
			return

		val = data[key]
		[str, phrase] = Search.getPhrase(val)

		switch data[key+":type"]
			when "token", "fulltext", undefined
				filter =
					type: "match"
					mode: data[key+":mode"]
					fields: @getFieldNamesForSearch()
					string: str
					phrase: phrase
			when "field"
				filter =
					type: "in"
					fields: @getFieldNamesForSearch()
					in: [ str ]
		filter

	__getFieldNames: ->
		fieldNames = [
			"#{@fullName()}.search_value"
		]
		return fieldNames

	renderEditorInput: (data, topLevelData, opts) ->
		initData = @__initData(data)

		resultObject = opts.editor?.object # The editor will not be present in the preview editor (datamodel -> masks)
		standard = resultObject?.getStandard() or ""

		baseCssURL = @__getBaseCSSURL()
		customCSSURL = ez5.session.getBaseConfig("plugin", "custom-data-type-html-editor").html_editor?.custom_css_url
		editorToolbar = "undo redo | image | styleselect | bold italic forecolor backcolor | alignleft aligncenter alignright alignjustify | outdent indent numlist bullist"
		inputEditor = null

		inputElement = CUI.dom.element("input")
		inputElement.value = initData.value
		CUI.dom.addClass(inputElement, "ez5-custom-data-type-html-editor-fixed-height")
		CUI.dom.setStyle(inputElement, visibility: "hidden")

		CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
			CUI.dom.waitForDOMInsert(node: inputElement).done(->
				tinymce.init(
					menubar:false
					toolbar: editorToolbar
					toolbar_mode: 'sliding'
					target: inputElement
					content_css: [baseCssURL, customCSSURL]
					plugins: "image paste lists"
					paste_data_images: true
					setup: ((inputText) ->
						CUI.dom.setStyle(inputElement, visibility: "")
						inputEditor = inputText
						inputText.on('change', ->
							initData.value = inputText.getContent()

							CUI.Events.trigger
								node: editorContent
								type: "editor-changed"
						)
					)
				)
			)
		)

		placeholderLabel = new CUI.Label
			text: $$("custom.data.type.html-editor.editor.editing-placeholder")
			class: "ez5-custom-data-type-html-editor-description"
			multiline: true
			appearance: "secondary"
		CUI.dom.hideElement(placeholderLabel)

		openEditorButton = new LocaButton
			loca_key: "custom.data.type.html-editor.editor.window.open-button"
			appearance: "link"
			size: "mini"
			onClick: =>
				saveChanges = false
				manualClose = false

				initData._editorWindowOpen = true # Avoid saving data when the window is open.
				openEditorButton.disable()
				CUI.dom.hideElement(inputEditor.getContainer())
				CUI.dom.showElement(placeholderLabel)

				features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=#{window.innerWidth},height=#{window.innerHeight}"
				win = window.open("", "_blank", features)

				win.document.title = $$("custom.data.type.html-editor.editor.window.title",
					standard: ez5.loca.getBestDatabaseValue(standard?["1"]?.text) or ""
					fieldName: @ColumnSchema._name_localized
				)

				# Add fylr css
				ez5CSSLinkElement = CUI.dom.element("link",
					href: ez5.getAbsoluteURL(ez5.cssLoader.getActiveCSS().url)
					rel: "stylesheet"
					type: "text/css"
				)
				win.document.head.appendChild(ez5CSSLinkElement)

				# Add plugin css
				plugin = ez5.pluginManager.getPlugin("custom-data-type-html-editor")
				pluginCSSLinkElement = CUI.dom.element("link",
					href: ez5.getAbsoluteURL(plugin.getBareBaseURL() + plugin.getWebfrontend().css)
					rel: "stylesheet"
					type: "text/css"
				)
				win.document.head.appendChild(pluginCSSLinkElement)

				windowInputElement = CUI.dom.element("input")
				windowInputElement.value = initData.value

				verticalLayout = new CUI.VerticalLayout
					class: "ez5-custom-data-type-html-editor-window"
					center:
						content: windowInputElement
					bottom:
						content: new CUI.HorizontalLayout
							right:
								content: new CUI.Buttonbar
									buttons:[
										text: $$("custom.data.type.html-editor.editor.window.button.cancel")
										onClick: =>
											confirmationChoice = new CUI.ConfirmationChoice
												text: $$("custom.data.type.html-editor.editor.window.cancel-confirmation")
												title: $$("custom.data.type.html-editor.editor.window.button.cancel")
												choices: [
													text: $$("base.cancel")
												,
													text: $$("base.ok")
													onClick: =>
														manualClose = true
														win.close()
												]
											confirmationChoice.open()
											CUI.dom.append(win.document.body, confirmationChoice.getLayerRoot())
											return
									,
										primary: true
										text: $$("custom.data.type.html-editor.editor.window.button.apply")
										onClick: =>
											saveChanges = true
											manualClose = true
											win.close()
									]

				win.document.body.appendChild(verticalLayout.DOM)

				windowInputEditor = null
				CustomDataTypeHtmlEditor.loadLibraryPromise.done(->
					tinymce.init(
						menubar:false
						toolbar: editorToolbar
						target: windowInputElement
						toolbar_mode: 'sliding'
						height: "100%"
						content_css: [baseCssURL, customCSSURL]
						plugins: "image paste lists"
						setup: ((inputText) ->
							windowInputEditor = inputText
						)
					)
				)

				win.addEventListener('beforeunload', (e) ->
					if not manualClose
						return e.returnValue = null
					return
				)

				win.addEventListener('unload', ->
					openEditorButton.enable()
					CUI.dom.hideElement(placeholderLabel)
					CUI.dom.showElement(inputEditor.getContainer())
					delete initData._editorWindowOpen

					if saveChanges
						initData.value = windowInputEditor.getContent()
						inputEditor.setContent(initData.value)

						CUI.Events.trigger
							node: editorContent
							type: "editor-changed"
					return
				)

		editorContent = new CUI.VerticalLayout
			top: content: placeholderLabel
			center: content: inputElement
			bottom: content: openEditorButton

		return editorContent

	__getCustomCSSElement: ->
		customCssURL = ez5.session.getBaseConfig("plugin", "custom-data-type-html-editor").html_editor?.custom_css_url
		if not customCssURL
			return
		linkElement = CUI.dom.element("link",
			href: customCssURL
			rel: "stylesheet"
			type: "text/css"
		)
		return linkElement

	__getBaseCSSURL: ->
		plugin = ez5.pluginManager.getPlugin("custom-data-type-html-editor")
		return ez5.getAbsoluteURL(plugin.getBaseURL() + "/base.css")

	__getBaseCSSElement: ->
		linkElement = CUI.dom.element("link",
			href: @__getBaseCSSURL()
			rel: "stylesheet"
			type: "text/css"
		)
		return linkElement

	renderDetailOutput: (data, topLevelData, opts) ->
		initData = @__initData(data)
		bodyContent = CUI.dom.htmlToNodes(initData.value)
		if opts.for_print
			div = CUI.dom.div()
			CUI.dom.append(div, bodyContent)
			return div

		iframe = CUI.dom.$element("iframe", "ez5-custom-data-type-html-editor-iframe")

		html = CUI.dom.element("html")
		head = CUI.dom.element("head")
		body = CUI.dom.element("body")

		CUI.dom.append(html, head)
		CUI.dom.append(html, body)
		CUI.dom.setStyle(body, "margin": "0px") # Remove the default margin of the HTML.

		CUI.dom.append(body, bodyContent)
		# append base style CSS
		baseLinkElement = @__getBaseCSSElement()
		if baseLinkElement
			CUI.dom.append(head, baseLinkElement)

		# append custom style CSS
		customLinkElement = @__getCustomCSSElement()
		if customLinkElement
			CUI.dom.append(head, customLinkElement)

		iframe.addEventListener("load", =>
			iframeContent = iframe.contentDocument.documentElement
			iframeContent.innerHTML = html.innerHTML

			# Resize iframe to its actual content
			# todo: something is still off with the height
			# todo: can we make this dynamic, so the iframe changes when the outside changes (sidebar)
			doc = iframe.contentDocument || iframe.contentWindow.document

			# Pick the larger of body/document heights to be safe
			height = Math.max(
				doc.body.scrollHeight,
				doc.documentElement.scrollHeight
			)

			iframe.style.height = height + 'px';
		)

		resultObject = opts.detail?.object
		if not resultObject and topLevelData # When it is inside a nested it has no topLevelData.
			resultObject = new ResultObject().setData(topLevelData)

		standard = resultObject?.getStandard()
		standardTitle = ez5.loca.getBestDatabaseValue(standard?["1"]?.text) or ""

		openButton = new LocaButton
			loca_key: "custom.data.type.html-editor.detail.window.open-button"
			appearance: "link"
			size: "mini"
			onClick: =>
				openButton.disable()

				features = "toolbar=no,status=no,menubar=no,scrollbars=yes,width=#{window.innerWidth},height=#{window.innerHeight}"
				win = window.open("", "_blank", features)

				newInputElement = CUI.dom.element("input")
				newInputElement.value = initData.value
				win.document.title = $$("custom.data.type.html-editor.detail.window.title",
					standard: standardTitle
					fieldName: @ColumnSchema._name_localized
				)
				
				# add custom stylesheet to preview
				if baseLinkElement
					win.document.head.appendChild(baseLinkElement)			
				
				if customLinkElement
					win.document.head.appendChild(customLinkElement)

				win.document.body.innerHTML = initData.value
				win.addEventListener('beforeunload', ->
					openButton.enable()
				)
				return

		detailContent = new CUI.VerticalLayout
			center:
				content: iframe
			bottom:
				content: openButton
		return detailContent

	getTemplateValue: (data) ->
		return data?._template?[@name()]

	getSaveData: (data, save_data) ->
		fieldData = data[@name()]
		if CUI.util.isEmpty(fieldData) or CUI.util.isEmpty(fieldData.value)
			fieldData = @getTemplateValue(data)
			if CUI.util.isEmpty(fieldData)
				return save_data[@name()] = null

		if fieldData._editorWindowOpen
			throw new InvalidSaveDataException(text: $$("custom.data.type.html-editor.editor.window.alert.is-open"))

		save_data[@name()] = CustomDataTypeHtmlEditor.buildData(fieldData.value)
		return save_data[@name()]

	@buildData: (stringContent) ->
		if CUI.util.isEmpty(stringContent)
			return null

		searchValue = []
		for _, value of CUI.dom.htmlToNodes(stringContent)
			text = value.textContent
			if not text or /^(\s|\n)$/.test(text)
				continue
			searchValue.push(value.textContent.trim())

		searchValue = searchValue.join(" ")

		data =
			value: stringContent
			search_value: searchValue
			_fulltext:
				text: searchValue
		return data

	__initData: (data) ->
		if not data[@name()]
			initData = value: ""
			data[@name()] = initData
		else
			initData = data[@name()]
		initData

	isEmpty: (data) ->
		return CUI.util.isEmpty(data[@name()]?.value)

	hasRenderForTable: ->
		return false

	hasRenderForSort: ->
		return false

	getCSVDestinationFields: (csvImporter) ->
		opts =
			csvImporter: csvImporter
			field: @

		[ new CustomDataTypeHtmlEditorCSVImporterDestinationField(opts) ]

CustomDataType.register(CustomDataTypeHtmlEditor)

ez5.session_ready ->
	plugin = ez5.pluginManager.getPlugin("custom-data-type-html-editor")
	url = ez5.getAbsoluteURL(plugin.getBaseURL() + "/tinymce/tinymce.min.js")
	CustomDataTypeHtmlEditor.loadLibraryPromise = CUI.loadScript(url)
	return
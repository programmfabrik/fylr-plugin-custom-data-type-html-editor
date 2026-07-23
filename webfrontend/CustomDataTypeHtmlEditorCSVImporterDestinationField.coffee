class CustomDataTypeHtmlEditorCSVImporterDestinationField extends CustomDataTypeColumnCSVImporterDestinationField

	initOpts: ->
		super()
		@mergeOpt "field",
			check: CustomDataTypeHtmlEditor

	formatValues: (values) ->
		data = []

		for value in values
			try
				_data = JSON.parse(value)
				if CUI.util.isPlainObject(_data)
					data.push(_data)
					continue

			if not CUI.isString(value)
				continue
			data.push(CustomDataTypeHtmlEditor.buildData(value))

		if data.length == 0
			return undefined
		else if data.length == 1
			return data[0]
		else
			return data
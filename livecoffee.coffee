# TODO intercept tab change, then compile!!!!!

define (require, exports, module) ->
    ide = require 'core/ide'
    ext = require 'core/ext'
    util = require 'core/util'
    editors = require 'ext/editors/editors'
    markup = require 'text!ext/livecoffee/livecoffee.xml'
    menus = require "ext/menus/menus" 
    commands = require "ext/commands/commands"
    CoffeeScript = require 'ext/livecoffee/vendor/coffeescript'
    console.log CoffeeScript
    lineMatching = require 'ext/livecoffee/vendor/cs_js_source_mapping'
    console.log lineMatching
    css = require "text!ext/livecoffee/livecoffee.css"
    console.log css
    
    DIVIDER_POSITION = 2100
    MENU_ENTRY_POSITION = 2200
    
    return ext.register 'ext/livecoffee/livecoffee',
        name: 'LiveCoffee'
        dev: 'Tane Piper'
        type: ext.GENERAL
        alone: yes
        markup: markup
        commands:
            'livecoffee': hint: 'Compile the current coffeescript document'
        hotitems : {}
        nodes: []
        css: css

        hook: () ->
            _self = @
            commands.addCommand(
                name: "livecoffee"
                hint: "start livecoffee plugin"
                bindKey: 
                    mac: "Command-K"
                    win: "Ctrl-K"
                exec: -> _self.livecoffee()
            )
            @nodes.push menus.addItemByPath("Edit/~", new apf.divider(), DIVIDER_POSITION)
            @nodes.push menus.addItemByPath("Edit/LiveCoffee", new apf.item({command: "livecoffee"}), MENU_ENTRY_POSITION)

            @hotitems['livecoffee'] = [@nodes[1]]
            return
                
        livecoffee: () ->
            ext.initExtension @
            @compile()
            @liveCoffeeOutput.show()
            if @liveCoffeeOutput.visible
                editor = editors.currentEditor
                ace = editor.amlEditor.$editor
                editor.ceEditor.addEventListener 'keyup', () =>
                    @compile()
                editor.ceEditor.$ext.addEventListener 'click', () =>
                    if @liveCoffeeOptMatchLines.checked
                        currentLine = ace.getCursorPosition().row
                        @liveCoffeeCodeOutput.$editor.gotoLine @findMatchingLine currentLine, @matchingLines
            return

        compile: () ->
            editor = editors.currentEditor
            ace = editor.amlEditor.$editor
            doc = editor.getDocument()
            value = doc.getValue()
            compiledJS = ''
            try
                bare = @liveCoffeeOptCompileBare.checked
                compiledJS = CoffeeScript.compile value, {bare}
                @matchingLines = lineMatching.source_line_mappings value.split("\n"), compiledJS.split("\n")
                @liveCoffeeCodeOutput.setValue compiledJS
                
                if @liveCoffeeOptMatchLines.checked
                    currentLine = ace.getCursorPosition().row
                    @liveCoffeeCodeOutput.$editor.gotoLine @findMatchingLine currentLine, @matchingLines
                    
                
                if @liveCoffeeOptCompileNodes.checked
                    @liveCoffeeNodeOutput.setValue CoffeeScript.nodes value
                    
                if @liveCoffeeOptCompileTokens.checked
                    @liveCoffeeTokenOutput.setValue CoffeeScript.tokens value
                
                return
            catch exp
                @liveCoffeeCodeOutput.setValue exp.message
                return

        findMatchingLine: (lineNumber, matchingLines) ->
            matchingLine = 1
            for line in matchingLines
                if lineNumber < line[0]
                    # some counting weirdnes therefore ++
                    return ++matchingLine
                matchingLine = line[1]

                
        init: (amlNode) ->
            apf.importCssString(css);
            
            liveCoffeeOptCompileBare.addEventListener 'click', () =>
                @compile()
            @liveCoffeeOptCompileBare = liveCoffeeOptCompileBare
                
            liveCoffeeOptCompileNodes.addEventListener 'click', () =>
                if liveCoffeeOptCompileNodes.checked
                    @liveCoffeeNodes.enable()
                    @compile()
                else
                    liveCoffeeNodes.disable()
            @liveCoffeeOptCompileNodes = liveCoffeeOptCompileNodes  
                
            liveCoffeeOptCompileTokens.addEventListener 'click', () =>
                if liveCoffeeOptCompileTokens.checked
                    @liveCoffeeTokens.enable()
                    @compile()
                else
                    @liveCoffeeTokens.disable()
            @liveCoffeeOptCompileTokens = liveCoffeeOptCompileTokens
                
            @liveCoffeeOptMatchLines = liveCoffeeOptMatchLines
            
            liveCoffeeCodeOutput.syntax = 'javascript'
            @liveCoffeeCodeOutput = liveCoffeeCodeOutput
            @liveCoffeeOutput = liveCoffeeOutput
            
            liveCoffeeNodes.disable()
            @liveCoffeeNodes = liveCoffeeNodes
            @liveCoffeeNodeOutput = liveCoffeeNodeOutput
            
            liveCoffeeTokens.disable()
            @liveCoffeeTokens = liveCoffeeTokens
            @liveCoffeeTokenOutput = liveCoffeeTokenOutput
            
            return

        enable : () ->
            @nodes.each (item) ->
                item.enable()
                
            @disabled = false

        disable: () ->
            @nodes.each (item) ->
                item.disable()
                
            @disabled = true
                        
        destroy : () ->
            @nodes.each (item) ->
                item.destroy true, true
                return
            @nodes = [];
            
            @liveCoffeeOptCompileBare.destroy true, true
            @liveCoffeeOptCompileNodes.destroy true, true
            @liveCoffeeOptCompileTokens.destroy true, true
            @liveCoffeeOptMatchLines.destroy true, true
            @liveCoffeeCodeOutput.destroy true, true
            @liveCoffeeOutput.destroy true, true
            @liveCoffeeNodes.destroy true, true
            @liveCoffeeNodeOutput.destroy true, true
            @liveCoffeeTokens.destroy true, true
            @liveCoffeeTokenOutput.destroy true, true
            return

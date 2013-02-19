EVENT_SEPARATOR = ':'

class EventStack
    constructor: ->
        @stacks = {}

    on: (event, handler, priority) =>
        if typeof handler != 'function'
            throw new Error 'Event handler must be a function.'

        event = String(event).trim().toLowerCase()
        priority = 1 if not priority?

        @stacks[event] = [] if not @stacks[event]?
        stacks = @stacks[event]
        stacks[priority] = [] if not stacks[priority]?
        
        if event.indexOf(EVENT_SEPARATOR) != -1 then stacks[priority].push handler
        else stacks[priority].splice 0, 0, handler

    once: (event, handler, priority) =>
        _off = @off
        f = ->
            args = Array::slice.call arguments, 0
            handler.apply @, args
            _off event, f
        @on event, f, priority

    off: (event, handler) =>
        event = String(event).trim().toLowerCase()

        stacks = @stacks[event]
        for priority in stacks
            if priority?
                i = priority.indexOf(handler)
                return priority.splice i, 1 if i != -1

    emit: (event) =>
        event = String(event)

        if event.indexOf(EVENT_SEPARATOR) != -1
            throw new Error "Tried to emit an event that contained a modifier (#{event})"

        event = event.trim().toLowerCase()

        # create array to be emitted as handler arguments
        e = origin: @
        args = Array::slice.call arguments, 1
        args.splice 0, 0, e

        # emit event with "before" modifier, then emit on parent
        eventSelector = "#{event}#{EVENT_SEPARATOR}before"
        @_emit eventSelector, args
        @parent._emit eventSelector, args if @parent?

        # emit event, then emit on parent
        signal = value: false
        e.halt = -> signal.value = true
        @_emit event, args, signal
        @parent._emit event, args if @parent?
        e.halt = undefined

        # emit event with "after" modifier, then emit on parent
        eventSelector = "#{event}#{EVENT_SEPARATOR}after"
        @_emit eventSelector, args
        @parent._emit eventSelector, args if @parent?

    _emit: (event, args, signal) =>
        if @stacks[event]? and Array.isArray(@stacks[event])
            for stacks in @stacks[event]
                if stacks?
                    for handler in stacks
                        if signal? and signal.value then return
                        handler.apply @, args if handler?

module.exports = EventStack
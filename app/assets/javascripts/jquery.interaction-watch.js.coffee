# By Alan Hogan, 2012
(($, window) ->
  $.fn.extend interactionWatch: (func, options) ->
    @defaultOptions = 
      once: false # per element, not universal
      eventNamespace: 'interactionWatch' # do not include dot.
                      # Event bindings will be set and unset via this namespace.
    settings = $.extend({}, @defaultOptions, options)
    
    namespace = (eventsStr) -> 
      ("#{evt}.#{settings.eventNamespace}" for evt in eventsStr.split(/\s+/) when evt.length).join(' ')

    trip = ->
      if settings.once
        $(this).unbind(".#{settings.eventNamespace}") # all our events
      func.apply(@, arguments)
    
    t = true
    keydownTripKeyCodes = {8:t,13:t,37:t,38:t,39:t,40:t}
    
    @each (i, el) =>
      $el = $(el) 
      
      # Events which sometimes count as interaction
      $el.bind namespace('keydown'), (e) ->
        if keydownTripKeyCodes[e.keyCode] and not (e.altKey || e.ctrlkey || e.metaKey)
          trip.apply(@, arguments)
      $el.bind namespace('keypress'), (e) ->
        if e.charCode
          trip.apply(@, arguments)
          
      # events which always count as interaction
      $el.bind namespace('textinput change cut copy paste select click mousedown'), (e) ->
        trip.apply(@, arguments)
      
      true # keep looping
    
    @ # allow chaining
) jQuery, this
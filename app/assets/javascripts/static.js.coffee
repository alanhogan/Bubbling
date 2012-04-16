# Further improvements that could be made include:
# Namespacing events

(($) ->
  $.fn.extend bubble: (options) ->
    @defaultOptions = 
      maskPosition: 'in front'
      sourceSelect: '.source'
      maskSelect: '.mask'
    settings = $.extend({}, @defaultOptions, options)
    
    @bubbleRegex = ///
      \{\{ # Two literal curly brackets
        ( # Capturing group
          .+? # Capture anything, non-greedily 
           # (ensuring no we grab as small of bubbles as possible)
           # This could alternatively be a whitelist of allowed bubble name characters
        )
      \}\} # Two literal end curly brackets
    ///g
    @bubbleReplacement = "<span class='bubbling-bubble'><span class='bubbling-invis-brackets'>{{</span>$1<span class='bubbling-invis-brackets'>}}</span></span>"
      
    @copyBubbled = (from, to) ->
      to.innerHTML = from.value.replace @bubbleRegex, @bubbleReplacement
    @copySize = ($from, $to) ->
      $to.height $from.height()
      $to.width $from.width()
      
    @each (i, unit) =>
      $unit = $(unit)
      [$source, $mask] = ($unit.find(settings[sel]).first() for sel in ['sourceSelect', 'maskSelect'])
      @copyBubbled $source[0], $mask[0]
      @copySize $source, $mask
      
      # v1 / mask in front
      if settings.maskPosition is 'in front'
        $source.focus => $mask.hide() # for when browser supports pointer-events: none
        $mask.click => $mask.hide()   # for when it doesn’t. 
        $source.blur => $mask.show()
      #v2 / mask behind
      else
        $source.focus => $source.css opacity: 1.0
        $source.blur => $source.css opacity: 0.0
      
      # on blur, always update mask
      $source.blur =>
        @copyBubbled $source[0], $mask[0]
        @copySize $source, $mask
      
      # init
      if $source.is(":focus") then $source.focus() else $source.blur()

  # On load, apply bubbling effect.
  $ ->
    $('.bubbling.v1').bubble {maskPosition: 'in front'}
    $('.bubbling.v2').bubble {maskPosition: 'behind'}


) jQuery
# Further improvements that could be made include:
# Namespacing events

(($) ->
  $.fn.extend bubble: (options) ->
    @defaultOptions = 
      wrapperClassName: 'bubbling-unit'
      sourceClassName: 'bubbling-source'
      maskClassName: 'bubbling-mask bubbling-mask-behind'
      bubbleClassName: 'bubbling-bubble'
      bubbleBracketsClassName: 'bubbling-invis-brackets'
      cssPropertiesToCopy: 'padding line-height font color'.split(' ')
      onlyBubbleTheseWords: false
      matchAllowedWordsCaseSensitively: false
      checkForMalformedBubbles: false
      failedBubbleClassName: 'bubbling-erroneous-bubble'
      failedBubbleBracketsClassName: 'bubbling-failed-brackets'
    settings = $.extend({}, @defaultOptions, options)
    
    @strictBubbleRegex = ///
      (\{\{) # Two literal curly brackets (as a capturing group for interoperability with loose bubble regex)
        ( # Capturing group
          [^\{\}<>&"'\n\r]+ # Any number of non-bracket, non-HTML-special, non-newline characters
        )
      (\}\}) # Two literal end curly brackets (as a capturing group)
    ///g
    @looseBubbleRegex = ///
      (\{\{?) # One or two literal curly brackets, as a capturing group
        ( # Capturing group
          [^\{\}<>&"'\n\r]+? # Any number of non-bracket, non-HTML-special, non-newline characters (non-greedy)
        )
      (\}\}|\}(?!\})) # Two curly braces if present, otherwise just one.
    ///g
    
    @bubbleReplacement = "<span class='#{_.escape settings.bubbleClassName}'><span class='#{_.escape settings.bubbleBracketsClassName}'>$1</span>$2<span class='#{_.escape settings.bubbleBracketsClassName}'>$3</span></span>"
    @bubbleCandidateReplacement = "<span class='-bubbling-bubble-candidate-'><span class='-bubbling-brackets-1-'>$1</span><span class='-bubbling-content-'>$2</span><span class='-bubbling-brackets-2-'>$3</span></span>"
    
    
    if settings.onlyBubbleTheseWords
      @allowedBubbleWordHash = {}
      @allowedBubbleWordHash[if settings.matchAllowedWordsCaseSensitively then word else word.toLowerCase()] = true for word in settings.onlyBubbleTheseWords
    
    @copyCssProperties = ($from, $to) ->
      map = {}
      map[prop] = $from.css(prop) for prop in settings.cssPropertiesToCopy
      $to.css(map)
    @looseCopyBubbled = ($from, $to) ->
      # construct a temporary dom outside of the document…
      $tmpDom = $ '<div>' + $from[0].value.replace(@looseBubbleRegex, @bubbleCandidateReplacement) + '</div>'
      
      # inspect each potential bubble & proceed accordingly
      while true
        $candidate = $tmpDom.find('.-bubbling-bubble-candidate-:first')
        break unless $candidate.length > 0
        valid = true
        valid &&= $candidate.find('.-bubbling-brackets-1-').text() == '{{' && $candidate.find('.-bubbling-brackets-2-').text() == '}}'
        if settings.onlyBubbleTheseWords and valid
          word = $candidate.find('.-bubbling-content-').text()
          valid &&= @allowedBubbleWordHash[if settings.matchAllowedWordsCaseSensitively then word else word.toLowerCase()]?
        # Done checking, so manipulate.
        if valid
          # promote to successful bubble
          $candidate[0].className = settings.bubbleClassName
          $word = $candidate.find('.-bubbling-content-'); $word.replaceWith $word.contents()
          $candidate.find('span').each (i, span) -> span.className = settings.bubbleBracketsClassName
        else
          # show as failed bubble or plain text, as config’d.
          if settings.checkForMalformedBubbles
            # show them as failed bubbles
            $candidate[0].className = settings.failedBubbleClassName
            $word = $candidate.find('.-bubbling-content-'); $word.replaceWith $word.contents()
            $candidate.find('span').each (i, span) -> span.className = settings.failedBubbleBracketsClassName
          else
            # don’t wrap them at all
            $candidate.replaceWith $candidate.text()
              
      # finally insert the contents of that dom 
      $to.empty().append $tmpDom.contents()
    @strictCopyBubbled = ($from, $to) ->
      $to[0].innerHTML = $from[0].value.replace @strictBubbleRegex, @bubbleReplacement
    @copyBubbled = =>
      if settings.checkForMalformedBubbles || settings.onlyBubbleTheseWords
        @looseCopyBubbled arguments...
      else
        @strictCopyBubbled arguments...
    @copySize = ($from, to...) ->
      [h, w] = [$from.height(), $from.width()]
      $to = $(to); $to.height h; $to.width w
    @copyScroll = (from, to) ->
      to.scrollTop = from.scrollTop
      
    @each (i, textarea) =>
      # Remove the element from the dom, then pop it back inside a new wrapper.
      $source = $(textarea).addClass settings.sourceClassName
      $unit = $('<div></div>').addClass settings.wrapperClassName
      $source.before($unit).detach().appendTo $unit
      $mask = $('<div></div>').addClass(settings.maskClassName).appendTo $unit
      @copyBubbled $source, $mask
      @copyCssProperties $source, $mask
      $mask.css 'white-space': 'pre-wrap'
      @copySize $source, $mask, $unit
      
      $source.focus => $source.css opacity: 1.0
      $source.blur => $source.css opacity: 0.0
      
      # on blur, always update mask
      $source.bind 'blur change', =>
        @copyBubbled $source, $mask
        @copySize $source, $mask, $unit
        @copyScroll $source[0], $mask[0]
      scrollSoon = _.throttle ( => @copyScroll($source[0], $mask[0])), 20
      $source.bind 'scroll', scrollSoon
      
      # init
      if $source.is(":focus") then $source.focus() else $source.blur()

  # On load, apply bubbling effect.
  $ ->
    $('.bubbling').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: 'InputHere Date Time Location'.split ' '
    )

) jQuery
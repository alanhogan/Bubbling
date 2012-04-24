# jQuery.bubble
# Supports defining liquid template-style tags (like {{Foo}})
# that are then show as if they were bubbles, without the curly brackets.
# Also supports detecting improperly created tags, like those missing a brace
# or using the wrong word (or the wrong case).
#
# Requirements:
# jQuery 1.7+
# Underscore.js
# jquery.ba-resize (optional; see below.)
#
# Note that if you want to allow resizing of bubbled textareas, this
# plugin will support it automatically, but only if used in conjection with
# something like Ben Alman’s resize event patch, jquery.ba-resize.js:
# http://benalman.com/projects/jquery-resize-plugin/
# This works by periodically watching elements which you have bound
# a callback on to the resize event, and “manually” fires the resize
# event when the element changes. It’s necessary beacuse browsers do
# not (as of early 2012) fire resize events for anything but the window,
# even if they allow the user to resize the element.
#
# It’s important to note that this plugin manipulates the DOM significantly
# by moving textareas inside of a new wrapper div (caled the bubbling unit),
# and also inserts another div which contains the 'bubbled' view (which, 
# in turn, creates some new span elements).
# 
# Some overly specific CSS selectors like .foo > textarea.your-textarea will break.
# Similarly, unusual styles applied to 'div' and 'span' elements may cause
# unusal results. You should have no problems if you followed
# CSS best practices.
#
# Bubbling units listen for the custom events 'showBubbles' and 'showRaw' which
# serve as commands switching the view from bubbled to pure textarea.
# The bubbling unit will also emit 'showingBubbles' and 'showingRaw' when it switches.
# By default, it will automatically switch based on focus/blur events,
# meaning whenever your user interacts with the textarea, they’ll be able to
# do so and will see the raw code; at all other times, it’ll look nicer.
# To override this, set the option showBubblesOnBlur to false;
# you will then want to manually do something like 
# $('.bubbling-unit').trigger('showBubbles')
# to bring back the bubbling mode.
# Note that technically events are internally triggered on the textarea and listed-to
# on the bubbling unit; thanks to bubbling, this means it doesn’t matter whether you
# bind or trigger events on the textareas or bubbling units.

(($) ->
  $.fn.extend bubble: (options) ->
    @defaultOptions = 
      wrapperClassName: 'bubbling-unit'
      sourceClassName: 'bubbling-source'
      maskClassName: 'bubbling-mask'
      bubbleClassName: 'bubbling-bubble'
      bubbleBracketsClassName: 'bubbling-invis-brackets'
      cssPropertiesToCopy: 'padding line-height font color background border box-sizing'.split(' ')
      onlyBubbleTheseWords: false
      matchAllowedWordsCaseSensitively: false
      checkForMalformedBubbles: false
      failedBubbleClassName: 'bubbling-erroneous-bubble'
      failedBubbleBracketsClassName: 'bubbling-failed-brackets'
      showBubblesOnBlur: true
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
    
    
    @copyCssProperties = (properties, $from, $to) ->
      map = {}
      map[prop] = $from.css(prop) for prop in properties
      $to.css(map)

    @looseCopyBubbled = ($from, $to) ->
      # construct a temporary dom outside of the document…
      $tmpDom = $ '<div>' + _.escape($from[0].value).replace(@looseBubbleRegex, @bubbleCandidateReplacement) + '</div>'
      
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
      $to[0].innerHTML = _.escape($from[0].value).replace @strictBubbleRegex, @bubbleReplacement
    @copyBubbled = =>
      if settings.checkForMalformedBubbles || settings.onlyBubbleTheseWords
        @looseCopyBubbled arguments...
      else
        @strictCopyBubbled arguments...
    # kind of a mess but to can be an object with 'match' (straight) and/or 'outerToCss' arrays, or a jQuery object (treated just like)
    @copySize = ($from, to) ->
      [h, w] = [$from.height(), $from.width()]
      unless to.match || to.outerToCss
        to = {match: $to.toArray()}
      if to.match
        $to = $(to.match); $to.height h; $to.width w
      if to.outerToCss
        $to = $(to.outerToCss); $to.height $from.outerHeight(); $to.width $from.outerWidth()
    @copyScroll = (from, to) ->
      to.scrollTop = from.scrollTop
      
    @each (i, textarea) =>
      # Idea: Remove the element from the dom, then pop it back inside a new wrapper;
      # position the wrapper like the element used to be positioned;
      # copy (basically all) the styles of the textarea to the mask (bubble container).
      
      $source = $(textarea)

      # skip if not textarea.
      unless textarea.tagName.match /textarea/i
        window?.console?.error? 'Cannot bubble non-textarea.'
        return true

      # create the wrapper (called 'unit')
      $unit = $('<div></div>').addClass settings.wrapperClassName
      
      # Position our unit like the textarea was.
      propertiesToCopyToUnit = ['margin']
      unless $source.css('position').match /static/i
        propertiesToCopyToUnit.push ['position', 'top', 'right', 'bottom', 'left', ]...
      @copyCssProperties propertiesToCopyToUnit, $source, $unit
      $unit.css height: $source.outerHeight(), width: $source.outerWidth(), 'border-width': 0, 'padding': 0
      
      # Reposition textarea inside the new wrapper, and add its class for add'l styling
      $source.before($unit)
      $source.detach().appendTo($unit)
      $source.addClass settings.sourceClassName

      # Position new wrapper like the textarea was
      $unit.css('position', 'relative') if $unit.css('position') is 'static'
      #create mask
      $mask = $('<div></div>').addClass(settings.maskClassName).appendTo $unit
      # make sure to position textarea and mask absolutely (within wrapper).
      @copyBubbled $source, $mask
      # make the mask look just like the textarea
      @copyCssProperties settings.cssPropertiesToCopy, $source, $mask
      # Both of them need to be positioned properly in their new context:
      $([$mask[0], $source[0]]).css
        position: 'absolute'
        top: 0, bottom: 0
        left: 0, right: 0
        width: 'auto', height: 'auto'
        margin: 0
        overflow: 'auto'
        
      # and make whitespace copy over properly.
      $mask.css 'white-space': 'pre-wrap'
      @copySize $source, {match:[$mask]}
      
      $unit.bind 'showRaw.bubble', => 
        $unit.data('showingBubbles', false)
        $source.css 'opacity', 1.0
        $source.trigger 'showingRaw'
      $unit.bind 'showBubbles.bubble', =>
        $unit.data('showingBubbles', true)
        $source.css 'opacity', 0.0
        $source.trigger 'showingBubbles'
        @copyBubbled $source, $mask
        @copyScroll $source[0], $mask[0]
      
      $source.bind 'focus.bubble', => $source.trigger 'showRaw'
      if settings.showBubblesOnBlur
        $source.bind 'blur.bubble', => $source.trigger 'showBubbles'
      

      # When showing bubbles, always update mask
      # When text changes, refresh mask
      $source.bind 'change.bubble', =>
        @copyBubbled $source, $mask
        @copyScroll $source[0], $mask[0]
        
      # Watch for resize event, if supported (see note)
      $source.bind 'resize.bubble', _.throttle( 
        ( => 
          @copySize($source, {match:[$mask], outerToCss:[$unit]})
        ),
        50
      )
      # Sync scrolling
      scrollSoon = _.throttle ( => @copyScroll($source[0], $mask[0])), 20
      $source.bind 'scroll.bubble', scrollSoon
      
      # init
      if $source.is(":focus") then $source.trigger('showRaw') else $source.trigger('showBubbles')

    @ # allow chaining
) jQuery

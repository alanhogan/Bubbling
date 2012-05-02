# Demo those bubbles.

(($) ->
  # On load, apply bubbling effect.
  $ ->
    allowedWords = 'InputHere Date Time Location'.split ' '
    
    $('.bubbling').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: allowedWords
    )
    
    $('.bubbling-manual-toggle').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: allowedWords
      showBubblesOnBlur: false
    )

    $('#show_bubbling_title_2').click ->
      $('#action_title2').closest('.bubbling-unit').trigger('showBubbles')

    $('#show_bubbling_desc_2').click () ->
      $('#action_desc2').trigger('showBubbles')
    
    $('.bubbling-soft-focus').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: allowedWords
      showRawOnFocus: (event, opts) ->
        if opts?.showRaw?
          return opts.showRaw
        else return true # no option provided
    )
    
    $('#do_soft_focus').click ->
      $('#soft_focus').trigger('focus', [{showRaw: false}]).interactionWatch( 
        ( ->
          console.log this
          $(this).trigger 'showRaw'
        ), once: true
      )
      
      return false

) jQuery
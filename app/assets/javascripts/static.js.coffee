# Demo those bubbles.

(($) ->
  # On load, apply bubbling effect.
  $ ->
    $('.bubbling').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: 'InputHere Date Time Location'.split ' '
    )
    
    $('.bubbling-manual-toggle').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: 'InputHere Date Time Location'.split ' '
      showBubblesOnBlur: false
    )

    $('#show_bubbling_title_2').click ->
      $('#action_title2').closest('.bubbling-unit').trigger('showBubbles')

    $('#show_bubbling_desc_2').click () ->
      $('#action_desc2').trigger('showBubbles')

) jQuery
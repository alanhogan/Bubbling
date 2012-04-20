# Demo those bubbles.

(($) ->
  # On load, apply bubbling effect.
  $ ->
    $('.bubbling').bubble(
      checkForMalformedBubbles: true
      matchAllowedWordsCaseSensitively: true
      onlyBubbleTheseWords: 'InputHere Date Time Location'.split ' '
    )

) jQuery
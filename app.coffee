loadSubtitles = ->
  fname = 'srt/' + $('#fname').val()
  $.get fname, (data, xhr) ->
    console.log(data)

$ ->
  for fname in window.SRTS
    $('#fname').append(
      $('<option>').attr('value', fname).text(fname)
    )

  $('#load').click loadSubtitles

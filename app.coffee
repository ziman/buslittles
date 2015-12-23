$ ->
  for fname in window.SRTS
    $('#fname').append(
      $('<option>').attr('value', fname).text(fname)
    )

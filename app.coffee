parseSrt = (txt) ->
  if txt.search(/\d+:\d+:\d+([.,]\d+)? -->/) != -1
    console.log "type A"
    return parseSrt_typeA txt

  if txt.search(/^\{\d+\}\{\d+\}/) != -1
    console.log "type B"
    return parseSrt_typeB txt

  console.error "could not recognise srt format"

parseSrt_typeB = (txt) ->
  lines = txt.replace('\r', ' ').split('\n')
  console.log "#{lines.length} lines"

  fps = 25.0
  events = []
  for line in lines
    xs = line.trim().match(/^\{(\d+)\}\{(\d+)\}(.*)$/)
    unless xs
      console.log "unrecognised: #{line}"
      continue

    events.push({
      ts: parseFloat(xs[1]) / fps,
      text: xs[3]
    })

  return {
    events: events,
    duration: events[events.length-1].ts - events[0].ts,
  }

parseSrt_typeA = (txt) ->
  lines = txt.replace('\r', '').split('\n')
  console.log "#{lines.length} lines"

  events = []

  startTs = 0
  endTs = 0
  content = ''
  for line in lines
    xs = line.replace(',','.').match(/(\d+):(\d+):([\d.]+) --> (\d+):(\d+):([\d.]+)/)

    if line.trim().match(/^\d+$/)
      if content != ''
        events.push({ts: startTs, text: content})
        #events.push({ts: endTs, text: ''})
        content = ''

      # console.debug "event number #{line}"

    else if xs
      startTs = \
        parseInt(xs[1]) * 3600 \
        + parseInt(xs[2]) * 60 \
        + parseFloat(xs[3])

      endTs = \
        parseInt(xs[4]) * 3600 \
        + parseInt(xs[5]) * 60 \
        + parseFloat(xs[6])

      # console.debug "timestamp! #{startTs} --> #{endTs}"

    else
      content = content + ' ' + line
      # console.debug "plain content: #{line}"

  events.push({ts: startTs, text: content})
  #events.push({ts: endTs, text: ''})

  return {
    events: events,
    duration: events[events.length-1].ts - events[0].ts,
  }

now = ->
  d = new Date()
  return d.getTime() / 1000.0

human = (s) ->
  min = Math.floor(s/60)
  sec = Math.round(s - 60*min)

  min = "0#{min}" if min < 10
  sec = "0#{sec}" if sec < 10

  return "#{min}:#{sec}"

class Application
  tick: ->
    curTs = now() - @startTs
    console.log "tick: #{curTs}"

    while curTs - @srt.events[@pos].ts > -0.2  # also accept 0.2s in future
      $('#content').text(@srt.events[@pos].text)
      @pos++

    $('#picker').val(@pos-1)

    nextDelay = @srt.events[@pos].ts - curTs
    console.log "nextDelay = #{nextDelay}"

    @clockHandle = window.setTimeout (=> @tick()), Math.floor(1000 * nextDelay)

  reset: ->
    console.log 'reset'
    @pos = 0

  # t' = at + b
  transform: (a, b) ->
    @srt = {
      events: ({ts: a*e.ts + b, text: e.text} for e in @rawSrt.events),
      duration: a*@rawSrt.duration,
      a: a,
      b: b
    }

  fillPicker: ->
    picker = $('#picker')
    picker.empty()

    for e, i in @srt.events
      picker.append(
        $('<option>').attr('value', i).text(
          "#{human e.ts}: #{e.text}"
        )
      )

  load: ->
    @stop()

    fname = 'srt/' + $('#fname').val()
    $.get fname, (data, xhr) =>
      @rawSrt = parseSrt data
      @transform 1.0, 0.0
      @fillPicker()
      console.log @srt.events
      console.log "duration: #{human @srt.duration}"

  play: ->
    console.log 'play'

    if @state == 'stopped'
      @startTs = now()

    if @state == 'paused'
      @startTs += now() - @pauseTs

    @state = 'playing'
    @tick()

  pause: ->
    console.log 'pause'
    @state = 'paused'
    @pauseTs = now()
    window.clearTimeout @clockHandle

  stop: ->
    console.log 'stop'
    @pause()
    @reset()
    @state = 'stopped'

  next: ->
    console.log "next"
    @pause()
    @pauseTs = @startTs + @srt.events[@pos].ts
    $('#content').text(@srt.events[@pos].text)
    @pos++

  skip: (k) ->
    console.log "skip #{k}"
    console.log "startTs_1 = #{@startTs}"
    @pause()

    @startTs += k*parseFloat($('#skip-val').val())
    console.log "startTs_2 = #{@startTs}"

    dt = now() - @startTs
    while (@pos > 0) and (@srt.events[@pos-1].ts > dt)
      @pos -= 1

    @play()

    console.log "startTs_3 = #{@startTs}"

  speedup: ->
    @pause()

    k = 1.0/parseFloat($('#speedup-val').val())
    console.log "speedup #{k}"
  
    dt = now() - @startTs
    @transform(k, 0.0)
    @startTs = now() - k*dt

    @play()

  showPicker: ->
    if $('#show-picker').prop('checked')
      $('#picker-wrap').show()
    else
      $('#picker-wrap').hide()

  pickerClick: ->
    @pos = $('#picker').val()
    @next()

  constructor: ->
    @rawSrt = null
    @srt = null
    @startTs = null
    @clockHandle = null
    @pauseTs = null
    @state = 'stopped'

    for fname in window.SRTS
      $('#fname').append(
        $('<option>').attr('value', fname).text(fname)
      )

    $('#load').click => @load()
    $('#play').click => @play()
    $('#pause').click => @pause()
    $('#stop').click => @stop()
    $('#next').click => @next()
    $('#skip-forward').click => @skip(1.0)
    $('#skip-back').click => @skip(-1.0)
    $('#speedup').click => @speedup()
    $('#show-picker').click => @showPicker()
    $('#picker').click => @pickerClick()

$ -> new Application()

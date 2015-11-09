class Sort
  # static methods and variables
  numCircles = 60
  colorPalette= d3.interpolateRgb('#E81D62', '#00BBD3')

  loopFunc = (delay, func) ->
    setInterval func, delay

  swap = (action, arr, i, j) ->
    return if i is j
    t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
    action.push
      type: 'swap'
      m: i
      n: j

  pivot = (action, i) ->
    action.push
      type: 'pivot'
      val: i

  bubbleSort = (swap, pivot, arr) ->
    for i in [arr.length-1..0]
      for j in [0...i]
        if arr[i] < arr[j]
          swap arr, i, j
      pivot i

  quickSort = (swap, pivot, arr, start, end) ->
    if start is end
      pivot start
      return
    i = start
    j = end
    for k in [i..j]
      if arr[k] < arr[j]
        swap arr, k, i
        ++i
    swap arr, j, i
    pivot i
    quickSort(swap, pivot, arr, start, i-1) if start < i
    quickSort(swap, pivot, arr, i+1, end) if i < end

  # Fisher-Yates (aka Knuth) Shuffle
  shuffle = (array) ->
    currentIndex = array.length
    # While there remain elements to shuffle...
    while 0 isnt currentIndex
      # Pick a remaining element...
      randomIndex = Math.floor(Math.random() * currentIndex)
      --currentIndex
      # And swap it with the current element.
      tValue = array[currentIndex]
      array[currentIndex] = array[randomIndex]
      array[randomIndex] = tValue
    return array

  # event listener polyfill
  addEvent = (object, type, callback) ->
    return if object == null || typeof(object) == 'undefined'
    if object.addEventListener
      object.addEventListener type, callback, false
    else if object.attachEvent
      object.attachEvent "on" + type, callback
    else
      object["on"+type] = callback

  # fire a custom event
  # use to change the color of subtitle
  # TODO check browser compatibility
  fireColorChangeEvent = (color) ->
    event = new CustomEvent 'pivotColorChange', { 'detail': color }
    window.dispatchEvent event

  constructor: (@svg) ->
    addEvent window, 'resize', @svgOnResize
    @$svg = d3.select(svg)
    @sortingFunc = []
    @actions = []
    @circles = []
    @actionLoopId = null
    @shuffledValue = shuffle([0..numCircles])
    @circles = @shuffledValue.map (e) ->
      {color: colorPalette(e/numCircles), id: e, pivot: false}
    @svgOnResize()

    @swap = swap.bind(null, @actions)
    @pivot = pivot.bind(null, @actions)

    # different sorting functions
    @sortingFunc.push bubbleSort.bind(@, @swap, @pivot, @shuffledValue)
    @sortingFunc.push quickSort.bind(@,
        @swap,
        @pivot,
        @shuffledValue,
        0,
        @shuffledValue.length-1)

    # random sort
    @sortingFunc[~~(@sortingFunc.length*Math.random())]()

  svgOnResize: () =>
    rect = @svg.getBoundingClientRect()
    @svg.setAttribute 'width', rect.width
    @svg.setAttribute 'height', rect.height
    circlePosHeight = rect.height/2
    circlePosWidth = rect.width/(numCircles+2)
    @circles.forEach (e) ->
      e.cy = circlePosHeight
      e.cx = circlePosWidth
      e.w = circlePosWidth/3
      e.h = if e.pivot then circlePosWidth/3*4 else circlePosWidth/3
    @$svg.selectAll 'rect'
      .attr 'width', (v) -> v.w*2
      .attr 'height', (v) -> v.h*2
      .attr 'rx', (v) -> v.w
      .attr 'x', (v, i) -> v.cx*(i+1) - v.w
      .attr 'y', (v) -> v.cy - v.h
      .append 'title'
        .text (v) -> v.id

  show: () =>
    @$svg.selectAll 'rect'
      .data @circles, (v) -> v.id
      .enter()
      .append 'rect'
      .attr 'width', (v) -> v.w*2
      .attr 'height', (v) -> v.h*2
      .attr 'rx', (v) -> v.w
      .attr 'x', (v, i) -> v.cx*(i+1) - v.w
      .attr 'y', (v) -> v.cy - v.h
      .attr 'fill', (v) -> v.color
    @actionLoopId = loopFunc 100, @executeAction

  executeAction: () =>
    if 0 is @actions.length
      clearInterval @actionLoopId
      return
    action = @actions.shift()
    if action.type is 'swap'
      t = @circles[action.m]
      @circles[action.m] = @circles[action.n]
      @circles[action.n] = t
      @$svg.selectAll 'rect'
        .data @circles, (v) -> v.id
        .transition()
        .duration 400
        .ease 'easeInOutCubic'
        .attr 'x', (v, i) -> v.cx*(i+1) - v.w
    else if action.type is 'pivot'
      fireColorChangeEvent @circles[action.val].color
      @circles[action.val].h *= 4
      @circles[action.val].pivot = true
      @$svg.selectAll 'rect'
        .data @circles, (v) -> v.id
        .attr 'y', (v) -> v.cy - v.h
        .attr 'height', (v) -> v.h*2

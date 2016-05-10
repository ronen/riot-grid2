grid2
  .gridwrap(style="height:{opts.height}px")
  
    //- main body
    .gridbody(onscroll='{scrolling}',style="overflow:auto;left:{fixedLeftWidth}px;top:{rowHeight}px;bottom:0px")
      .scrollArea(style="width:{scrollWidth-fixedLeftWidth}px;height:{scrollHeight-rowHeight}px")
        .cell(each="{visCells.main}",no-reorder,style="left:{left}px;top:{top}px;width:{width}px;height:{rowHeight}px;") {text}
    
    //- fixed top
    .gridbody(style="height:{rowHeight}px")
      .header(style="top:0px;left:0px;width:{scrollWidth}px;height:{rowHeight}px")
        .headercell(each="{headers.main}",no-reorder,style="transform:translate3d({left}px,0px,0px); backface-visibility: hidden;width:{width}px;height:{rowHeight}px;") {text}
    
    //- fixed left
    .gridbody(style="width:{fixedLeftWidth}px;height:{opts.height-2}px")
      .fixedLeft(style="transform:translate3d(0px,{0-gridbody[0].scrollTop}px,0px);backface-visibility: hidden;width:{fixedLeftWidth}px;bottom:1px;z-index:2;")
        .header(style="top:{gridbody[0].scrollTop}px;left:0px;width:{fixedLeftWidth}px;height:{rowHeight}px")
          .headercell(each="{headers.fixed}",style="top:0px;left:{left}px;width:{width}px;height:{rowHeight}px;") {text}
        .cell(each="{visCells.fixed}",no-reorder,style="transform:translate3d({left}px,{top}px,0px);backface-visibility: hidden;width:{width}px;height:{rowHeight}px;") {text} 
  
  style(type="text/stylus").
    
    grid2
      display block
      -webkit-font-smoothing: antialiased
      text-rendering: optimizeSpeed
      .scrollArea
        transform: translateZ(0)
      .gridwrap
        position relative
        display block
        border 1px solid #ccc
        font-family sans-serif
        font-size:14px
      
      .gridbody
        position absolute
        overflow:hidden
        top 0
        left 0
        right 0
        bottom 0
        transform: translateZ(0)
        backface-visibility hidden
      
      .fixedLeft
        position absolute
        top 0
        bottom 0
        
        
      .cell,.headercell
        position absolute
        box-sizing border-box
        padding 5px
        whitespace no-wrap
        overflow hidden
        background white
        border 1px solid #ccc
        border-width 0 1px 1px 0
        
        
        
      .header
        position absolute
        z-index 1
        overflow hidden
        transform: translateZ(0)
      
  script(type='text/coffee').
    @rowHeight = 30
    
    @on 'mount',->
      @visCells = null
      @gridbody = @root.querySelectorAll(".gridbody")
      @update()
      
    @on 'update',->
      return if !@gridbody || !opts.data || !opts.columns
      if opts.columns && opts.data && (@columns != opts.columns || @data != opts.data)
        @data = opts.data
        @columns = opts.columns
        @rows=[]
        console.time 'calcpos'
        @calcPos()
        console.timeEnd 'calcpos'
      if !@visCells
        console.time 'calcvis'
        @visCells = calcVisible(@rows,@gridbody[0],@rowHeight)
        console.timeEnd 'calcvis'
      else
        console.time 'recalc'
        @visCells = reCalc(@visCells,@rows,@gridbody[0],@rowHeight)
        console.timeEnd 'recalc' 

    @calcPos= =>
      # work out co-ordinates of all cells
      left = 0
      top = 0
      @rows = []
      @fixedLeftWidth = @columns.filter((col)-> col.fixed?).reduce ((a,col)-> a+col.width),0
      @headers = {fixed:[],main:[]}
      left = 0
      for col,cidx in @columns
        key = if col.fixed then "fixed" else "main"
        @headers[key].push
          left:left
          right:col.width+left
          bottom:top+@rowHeight
          width:col.width
          text:col.label
        left+=col.width

      key = 0 #every cell has unique key
      for row,ridx in @data
        left = 0
        top = (ridx+1)*@rowHeight
        @rows[ridx]={data:[]}
        for col,cidx in @columns
          @rows[ridx].data.push
            top:if col.fixed then top else top-@rowHeight
            left: if col.fixed then left else left-@fixedLeftWidth
            right:if col.fixed then col.width+left else col.width+left-@fixedLeftWidth
            bottom:top+@rowHeight
            width:col.width
            text:row[col.field]
            fixed:if col.fixed then true else false
            key:key
          key++
          left+=col.width
      @scrollWidth = left
      @scrollHeight = top+@rowHeight
      @update()
      
    @scrolling = (e)=>
      e.preventUpdate = true
      @gridbody[1].scrollLeft = @gridbody[0].scrollLeft
      @update()
        
    calcArea = (gridbody)->
      top:gridbody.scrollTop
      left:gridbody.scrollLeft
      right:gridbody.scrollLeft+gridbody.offsetWidth
      bottom:gridbody.scrollTop+gridbody.offsetHeight
            
    calcVisible=(rows,gridbody,rowHeight)->
      r1 = calcArea(gridbody)
      first = Math.max(Math.floor(r1.top / rowHeight),0)
      last = Math.ceil(r1.bottom / rowHeight)
      visrows = rows.slice(first,last)
      visible = []
      visiblefixed = []
      for cells in visrows
        for r2,idx in cells.data
          if r2.fixed
            visiblefixed.push r2
          else if !(r2.left > r1.right || r2.right < r1.left)
            visible.push r2
          break if r2.left > r1.right
          
      return {main:visible,fixed:visiblefixed}
    
    reCalc=(visCells,rows,gridbody,rowHeight)->
      newcells = calcVisible(rows,gridbody,rowHeight)
      area = calcArea(gridbody)
      # record unused
      visCells.main = reUse(visCells.main,newcells.main,area)
      visCells.fixed = reUse(visCells.fixed,newcells.fixed,area)
      return visCells
      
     
    reUse = (visible,newcells,area)->
      unused = []
      viskeys = []
      for cell,idx in visible
        if cell.left > area.right || cell.right < area.left || cell.bottom < area.top || cell.top > area.bottom
          unused.push idx
        else
          viskeys.push cell.key 

      for show in newcells
        if viskeys.indexOf(show.key) == -1
          if unused.length > 0 then visible[unused.pop()] = show else visible.push(show)

      return visible
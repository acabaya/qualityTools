#data - fdo if not this is defaulting to persp with color regions defined by col
#x - name of x vector in data
#y - name of y vector in data
#z - name of response in data
#TODO: incorporate more than one z for more than one fit
#formula  - "quadratic", "full", "interaction", "linear", "fit"  or a formula y ~ x+y +x*y
#         - "fit" takes the formula from the fit in the facDesign object
#factors  - list of 4th 5th factor with value i.e. factors = list(D = 1.2, E = -1)
#          - if nothing is specified  values will be the mean of the low and the high value of the factors
wirePlot = function(x,y,z, data = NULL, xlim, ylim, zlim, main, xlab, ylab, border, sub,zlab, form = "fit", phi, theta, ticktype, col = 1, steps, factors, fun, plot)
#xlim = range(x), ylim = range(y),
#      zlim = range(z, na.rm = TRUE),
#      xlab = NULL, ylab = NULL, zlab = NULL,
#      main = NULL, sub = NULL,
#      theta = 0, phi = 15, r = sqrt(3), d = 1,
#      scale = TRUE, expand = 1,
#      col = "white", border = NULL, ltheta = -135, lphi = 0,
#      shade = NA, box = TRUE, axes = TRUE, nticks = 5,
#      ticktype = "simple", ...)
{
  DB = FALSE

  form = form #holds the final formula
  fact = NULL #holds a list of the factors that are to be set on a specific value
  if(missing(steps))
    steps = 25
  fdo = data
  fit = NULL
  lm.1 = NULL
  
  
  
  

  
  if(!is.function(col))
  {
    if(identical(col,1))
      col = colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan","#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))
    if(identical(col,2))
      col = colorRampPalette(c("blue", "white", "red"),space = "Lab")
    if(identical(col,3))
      col = colorRampPalette(c("blue","white","orange"))
    if(identical(col,4))                
      col = colorRampPalette(c("gold","white","firebrick"))
  }
  
  if(is.null(data))
  {
   cat("\n defaulting to persp function\n")
   return("persp")
  }
  
  if(class(data) != "facDesign")
  {
    cat("\n defaulting to persp function using formula\n")
    return("persp")
  }
  
  #conversion to characters
  x.c = deparse(substitute(x))
  y.c = deparse(substitute(y))
  z.c = deparse(substitute(z))


  if(missing(plot))
    plot = TRUE
  if(missing(main))
    main = paste("Respone Surface for", z.c)
  if(missing(ylab))
    ylab = y.c
  if(missing(xlab))
    xlab = x.c
  if(missing(zlab))
    zlab = z.c
  if(missing(ticktype))
    ticktype = "detailed"
  if(missing(border))
    border = NULL
  if(missing(phi))
    phi = 30
  if(missing(theta))
    theta=-30       
  if(missing(factors))
    factors = NULL
  
  #check if x,y and z could be found
  allVars = c(names(names(fdo)), names(response(fdo)))
  isct = intersect(c(x.c,y.c,z.c), c(names(names(fdo)), names(response(fdo))))  
  if(DB)
  {
    print(allVars)
    print(isct)
  }
  
  if(length(isct) < length(c(x.c,y.c,z.c)))
  {
   d = setdiff(isct, allVars) 
   stop(paste(d, "could not be found\n"))
  }
  
  
  ######Incorporate the plotting of desirabilities######
  if(missing(fun))  #no function given
    fun = NULL
    
  if(!is.function(fun) & !is.null(fun))
    if(!(fun %in% c("overall", "desirability")))
      stop("fun should be a function, \"overall\" or \"desirability\"")
  
  if(identical(fun, "desirability"))  #if desirability --> create .desireFun
  {
    obj = desires(fdo)[[z.c]]
    fun = .desireFun(obj@low, obj@high, obj@target, obj@scale, obj@importance)
  }
  ######END: Incorporate the plotting of desirabilities######




  
  
  #go for the formula for fitting
  if(form %in% c("fit"))
  {
    lm.1 = fits(fdo)[[z.c]]
    if(DB)
      print(lm.1)
    
    if(is.null(fit))
      form = "full"  #if this fit doesn't exist take a full fit 
  }
  if(form %in% c("quadratic", "full", "interaction", "linear"))
  {
    #form = form.help(formula, lm.model)
  }
  
  if(identical(form, "interaction"))
  {
   form = paste(z.c, "~", x.c, "+", y.c, "+", x.c,":",y.c)
  }
  
  if(identical(form, "linear"))
  {
   form = paste(z.c, "~", x.c, "+", y.c)
  }
  if(identical(form, "quadratic"))
  {
   form = paste(z.c,"~I(",x.c,"^2) + I(",y.c,"^2)")
  }

  if(identical(form, "full"))
  {
   form = paste(z.c, "~", x.c, "+", y.c, "+", x.c,":",y.c)
   if(nrow(star(fdo)) > 0)
   form = paste(form,"+ I(",x.c,"^2) + I(",y.c,"^2)")
   if(DB)
     print(form)
    
  }


  
  
  if(is.null(form))
    stop(paste("invalid formula",form))
  
  
  ###actual fitting of the response  
  #outer mit formula aufrufen und weiteren Faktoren und Ihren Einstellungen aus der Faktorlist fac
  #matrix und x und y erhalten
  if(is.null(lm.1))
    lm.1 = lm(form ,data = fdo)
  
  if(missing(sub))
    sub = deparse(formula(lm.1))
  
  if(DB)
    print(lm.1)
    
  dcList = vector(mode = "list", length = length(names(fdo))) #this is the do.call list
  names(dcList) = names(names(fdo))
  dcList[1:length(names(fdo))] = 0  #TODO: durch den Mittelwert 
  if(!is.null(factors))
  {
   for(i in names(factors))
    dcList[[i]] = factors[[i]][1] #take only first element of each value stored for a factors
  }


  if(DB)
    print(dcList)

#################helper function to use in outer###############
help.predict = function(x,y, x.c, y.c, lm.1,  ...)
{
 dcList[[x.c]] = x
 dcList[[y.c]] = y
 temp = do.call(data.frame, dcList) 
 invisible(predict(lm.1, temp))
} 
################################################################





  if(DB)
  {
    print(x.c)
    print(y.c)  
    print(help.predict(1, 2, "A", "B", lm.1 = lm.1))
    print(help.predict(1, 2, x.c, y.c, lm.1 = lm.1))
  }
  #matrix erstellen fuer persp
  xVec = seq(min(fdo[,x.c]), max(fdo[,x.c]), length = steps)
  yVec = seq(min(fdo[,y.c]), max(fdo[,y.c]), length = steps)
  
  mat = outer(xVec, yVec,  help.predict, x.c, y.c, lm.1)
  
  
  #evaluate each value of the grid mat with the given function (e.g. desirability)
  if(is.function(fun))
    mat = try(apply(mat, c(1,2), fun))
    
  if(identical(fun, "overall"))
  {
    main = "composed desirability"
    mat = matrix(1, nrow = nrow(mat), ncol = ncol(mat))
    for(i in names(response(fdo)))
    {
     obj = desires(fdo)[[i]]
     fun = .desireFun(obj@low, obj@high, obj@target, obj@scale, obj@importance)
     temp = outer(xVec, yVec, help.predict, x.c, y.c, fits(fdo)[[i]])
     temp = try(apply(temp, c(1,2), fun))
     
     mat = mat * temp
    }
    mat = mat^(1/length(names(response(fdo))))
  }
  

  ###actual drawing of the response
  #adapted code from example(persp)
  if(is.function(col))
  {
    nrMat <- nrow(mat)
    ncMat <- ncol(mat)
    # Create a function interpolating colors in the range of specified colors
    jet.colors <- colorRampPalette(c("blue", "green")) 
    # Generate the desired number of colors from this palette
    nbcol <- 100
    color <- col(nbcol)
    # Compute the z-value at the facet centres
    matFacet <- mat[-1, -1] + mat[-1, -ncMat] + mat[-nrMat, -1] + mat[-nrMat, -ncMat]
    # Recode facet z-values into color indices
    facetcol <- cut(matFacet, nbcol)
  }
  else
  {
    color = col
    facetcol = 1
  }
  
  if(plot)
  {
    persp(xVec, yVec, mat, main = main, sub = sub, xlab = xlab, ylab = ylab, zlab = zlab,  col=color[facetcol],border = border, ticktype = ticktype, phi=phi, theta=theta)
    
    if(is.function(col))
    {
      zlim = range(mat)
      leglevel = pretty(zlim, 6)  
      legcol = col(length(leglevel))
      #make a nice character vector for the legend
      legpretty = as.character(abs(leglevel))
      temp = character(length(leglevel))
      temp[leglevel > 0] = "+"
      temp[leglevel < 0] = "-"
      temp[leglevel == 0] = " "
      legpretty = paste(temp, legpretty, sep = "")
        
      legend("topright", inset = 0.02, legend = paste(">",legpretty), col = legcol, bg = "white", pt.cex = 1.5, cex = 0.75, pch = 15)
    }
  }
#  filled.contour(xVec, yVec, mat, main = main, xlab = xlab, ylab = ylab, col=color[facetcol])
  invisible(list(x = xVec, y = yVec, z = mat))
}

#example
#fdo = rsmDesign(k = 3, blocks = 2)
#response(fdo) = data.frame(y = rnorm(nrow(standOrd(fdo))))
#fits(fdo) = lm(y ~ A*B*C + I(A^2) + I(B^2) + I(C^2), data = fdo)
#wirePlot(A,B,y, data = fdo)
#par(mfrow = c(2,2))
#wirePlot(A,B,y, data = fdo, form = "full")
#wirePlot(A,B,y, data = fdo, form = "linear")
#wirePlot(A,B,y, data = fdo, form = "interaction")
#wirePlot(A,B,y, data = fdo, form = "quadratic")




#function to draw a filled contourPlot
#this is a modified version of R's filled.contour which works with layouts. layout part was removed and a different colorkey was introduced.
#.mfc can be resized and anything added (such as lines) will keep the proportions 
.mfc = function (x = seq(0, 1, length.out = nrow(z)), y = seq(0, 1, 
    length.out = ncol(z)), z, xlim = range(x, finite = TRUE), 
    ylim = range(y, finite = TRUE), zlim = range(z, finite = TRUE), 
    levels = pretty(zlim, nlevels), nlevels = 20, color.palette = cm.colors, 
    col = color.palette(length(levels) - 1), plot.title, plot.axes, 
    key.title, key.axes, asp = NA, xaxs = "i", yaxs = "i", las = 1, 
    axes = TRUE, frame.plot = axes, ...) 
{
    if (missing(z)) {
        if (!missing(x)) {
            if (is.list(x)) {
                z <- x$z
                y <- x$y
                x <- x$x
            }
            else {
                z <- x
                x <- seq.int(0, 1, length.out = nrow(z))
            }
        }
        else stop("no 'z' matrix specified")
    }
    else if (is.list(x)) {
        y <- x$y
        x <- x$x
    }
    if (any(diff(x) <= 0) || any(diff(y) <= 0)) 
        stop("increasing 'x' and 'y' values expected")
    mar.orig <- (par.orig <- par(c("mar", "las", "mfrow")))$mar
#    on.exit(par(par.orig))
    w <- (3 + mar.orig[2L]) * par("csi") * 2.54
    par(las = las)
    mar <- mar.orig
    mar[4L] <- mar[2L]
    mar[2L] <- 1
    mar = c(4.1, 4.1, 4.1, 4.1)
    par(mar = mar)

    plot(1,1, type = "n", axes = FALSE, xlim, ylim, xlab = "", ylab = "", main = "", xaxs = xaxs, yaxs = yaxs, asp = asp)
    
    if (!is.matrix(z) || nrow(z) <= 1L || ncol(z) <= 1L) 
        stop("no proper 'z' matrix specified")
    if (!is.double(z)) 
        storage.mode(z) <- "double"
    .Internal(filledcontour(as.double(x), as.double(y), z, as.double(levels), col = col))
    
    
    leglevel = pretty(zlim, 6)  
    legcol = color.palette(length(leglevel))
    
    #make a nice character vector for the legend
    legpretty = as.character(abs(leglevel))
    temp = character(length(leglevel))
    temp[leglevel > 0] = "+"
    temp[leglevel < 0] = "-"
    temp[leglevel == 0] = " "
    legpretty = paste(temp, legpretty, sep = "")
    
    legend("topright", inset = 0.02, legend = paste(">",legpretty), col = legcol, bg = "white", pt.cex = 1.5, cex = 0.75, pch = 15)
    
    if (missing(plot.axes)) {
        if (axes) {
            title(main = "", xlab = "", ylab = "")
            Axis(x, side = 1)
            Axis(y, side = 2)
        }
    }
    else plot.axes
    if (frame.plot) 
        box()
    if (missing(plot.title)) 
        title(...)
    else plot.title
    invisible()
}

#par(mfrow = c(2,2))
#do.call(.mfc, wirePlot(A, B, y, data = fdo))
#lines(c(0,1), c(0,1), col = "red")
#



contourPlot = function(x,y,z, data = NULL, xlim, ylim, zlim, main, xlab, ylab, border, sub,zlab, form = "fit", ticktype, col = 1, steps, factors, fun)
{
  DB = FALSE
  
  form = form #holds the final formula
  fact = NULL #holds a list of the factors that are to be set on a specific value
  if(missing(steps))
    steps = 25
  fdo = data
  fit = NULL
  lm.1 = NULL
  
  
  if(!is.function(col))
  {
    if(identical(col,1))
      col = colorRampPalette(c("#00007F", "blue", "#007FFF", "cyan","#7FFF7F", "yellow", "#FF7F00", "red", "#7F0000"))
    if(identical(col,2))
      col = colorRampPalette(c("blue", "white", "red"),space = "Lab")
    if(identical(col,3))
      col = colorRampPalette(c("blue","white","orange"))
    if(identical(col,4))                
      col = colorRampPalette(c("gold","white","firebrick"))
    if(identical(col,5))                
      col = colorRampPalette(c("blue4","lightblue1", "lightgreen","green4"))
  }
  
  if(is.null(data))
  {
   cat("\n defaulting to filled.contour function\n")
   return("persp")
  }
  
  if(class(data) != "facDesign")
  {
    cat("\n defaulting to filled.contour function using formula\n")
    return("persp")
  }
  
  #conversion to characters
  x.c = deparse(substitute(x))
  y.c = deparse(substitute(y))
  z.c = deparse(substitute(z))

  if(missing(main))
    main = paste("Filled Contour for", z.c)
  if(missing(ylab))
    ylab = y.c
  if(missing(xlab))
    xlab = x.c
  if(missing(factors))
    factors = NULL
  
  #check if x,y and z could be found
  allVars = c(names(names(fdo)), names(response(fdo)))
  isct = intersect(c(x.c,y.c,z.c), c(names(names(fdo)), names(response(fdo))))  
  if(DB)
  {
    print(allVars)
    print(isct)
  }
  
  if(length(isct) < length(c(x.c,y.c,z.c)))
  {
   d = setdiff(isct, allVars) 
   stop(paste(d, "could not be found\n"))
  }
  
  
  ######Incorporate the plotting of desirabilities######
  if(missing(fun))  #no function given
    fun = NULL
    
  if(!is.function(fun) & !is.null(fun))
    if(!(fun %in% c("overall", "desirability")))
      stop("fun should be a function, \"overall\" or \"desirability\"")
  
  if(identical(fun, "desirability"))  #if desirability --> create .desireFun
  {
    obj = desires(fdo)[[z.c]]
    fun = .desireFun(obj@low, obj@high, obj@target, obj@scale, obj@importance)
  }
  ######END: Incorporate the plotting of desirabilities######

  
  
  
  #go for the formula for fitting
  if(form %in% c("fit"))
  {
    lm.1 = fits(fdo)[[z.c]]
    if(DB)
      print(lm.1)
    
    if(is.null(fit))
      form = "full"  #if this fit doesn't exist take a full fit 
  }
  if(form %in% c("quadratic", "full", "interaction", "linear"))
  {
    #form = form.help(formula, lm.model)
  }
  
  if(identical(form, "interaction"))
  {
   form = paste(z.c, "~", x.c, "+", y.c, "+", x.c,":",y.c)
  }
  
  if(identical(form, "linear"))
  {
   form = paste(z.c, "~", x.c, "+", y.c)
  }
  if(identical(form, "quadratic"))
  {
   form = paste(z.c,"~I(",x.c,"^2) + I(",y.c,"^2)")
  }

  if(identical(form, "full"))
  {
   form = paste(z.c, "~", x.c, "+", y.c, "+", x.c,":",y.c)
   if(nrow(star(fdo)) > 0)
   form = paste(form,"+ I(",x.c,"^2) + I(",y.c,"^2)")
   if(DB)
     print(form)
    
  }

  if(is.null(form))
    stop(paste("invalid formula",form))
  
  
  ###actual fitting of the response  
  #outer mit formula aufrufen und weiteren Faktoren und Ihren Einstellungen aus der Faktorlist fac
  #matrix und x und y erhalten
  if(is.null(lm.1))
    lm.1 = lm(form ,data = fdo)
  
  if(missing(sub))
    sub = deparse(formula(lm.1))
  
  if(DB)
    print(lm.1)
    
  dcList = vector(mode = "list", length = length(names(fdo))) #this is the do.call list
  names(dcList) = names(names(fdo))
  dcList[1:length(names(fdo))] = 0  #TODO: durch den Mittelwert ersetzen
  if(!is.null(factors))
  {
    for(i in names(factors))
       dcList[[i]] = factors[[i]][1] #take only first element of each value stored for a factors
  }


  if(DB)
    print(dcList)

#################helper function to use in outer###############
help.predict = function(x,y, x.c, y.c, lm.1,  ...)
{
 dcList[[x.c]] = x
 dcList[[y.c]] = y
 temp = do.call(data.frame, dcList) 
 invisible(predict(lm.1, temp))
} 
###############################################################

  if(DB)
  {
    print(x.c)
    print(y.c)  
    print(help.predict(1, 2, "A", "B", lm.1 = lm.1))
    print(help.predict(1, 2, x.c, y.c, lm.1 = lm.1))
  }
  #matrix erstellen fuer persp
  xVec = seq(min(fdo[,x.c]), max(fdo[,x.c]), length = steps)
  yVec = seq(min(fdo[,y.c]), max(fdo[,y.c]), length = steps)
  mat = outer(xVec, yVec,  help.predict, x.c, y.c, lm.1)
  
  ###actual drawing of the response
  #adapted code from example(persp)
  if(is.function(col))
  {
    nrMat <- nrow(mat)
    ncMat <- ncol(mat)
    # Generate the desired number of colors from this palette
    nbcol <- 1000
    color <- col(nbcol)
    # Compute the z-value at the facet centres
    matFacet <- mat[-1, -1] + mat[-1, -ncMat] + mat[-nrMat, -1] + mat[-nrMat, -ncMat]
    # Recode facet z-values into color indices
    facetcol <- cut(matFacet, nbcol)
  }
  else
  {
    color = col
    facetcol = 1
  }
  
  #evaluate each value of the grid mat with the given function (e.g. desirability)
  if(is.function(fun))
    mat = try(apply(mat, c(1,2), fun))
    
  if(identical(fun, "overall"))
  {
    main = "composed desirability"
    mat = matrix(1, nrow = nrow(mat), ncol = ncol(mat))
    for(i in names(response(fdo)))
    {
     obj = desires(fdo)[[i]]
     fun = .desireFun(obj@low, obj@high, obj@target, obj@scale, obj@importance)
     temp = outer(xVec, yVec, help.predict, x.c, y.c, fits(fdo)[[i]])
     temp = try(apply(temp, c(1,2), fun))
     
     mat = mat * temp
    }
    mat = mat^(1/length(names(response(fdo))))
  }
  #################################################################################
 


  .mfc(xVec, yVec, mat, main = main, xlab = xlab, ylab = ylab, color=col)
  invisible(list(x = xVec, y = yVec, z = mat))
}

#par(mfrow = c(2,2))
#contourPlot(A, B, y, data = fdo, form = "full")
#wirePlot(A, B, y, data = fdo)
#












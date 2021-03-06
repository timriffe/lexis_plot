# Adjusted viridis function: the line where cols are defined allows now to
# use any bins and not only those of an equally spaced categorisation
magmaadjust <- function (n, alpha = 1, bins, option = "magma") {
  option <- switch(option,
                   A = "A",
                   magma = "A",
                   B = "B",
                   inferno = "B", 
                   C = "C",
                   plasma = "C",
                   D = "D",
                   viridis = "D",
                   {
                     warning(paste0("Option '", option, "' does not exist. Defaulting to 'viridis'."))
                     "D"
                   })
  ## colorspace::sequential_hcl(1e3, palette = "Inferno")
  map <- viridisLite::viridis.map[viridisLite::viridis.map$opt == option, ]
  map_cols <- grDevices::rgb(map$R, map$G, map$B)
  fn_cols <- grDevices::colorRamp(map_cols, space = "Lab", 
                                  interpolate = "spline")
  cols <- fn_cols(bins)/255
  grDevices::rgb(cols[, 1], cols[, 2], cols[, 3], alpha = alpha)
}

# Cohort mortality rates (magma colors)
if (var_of_int==1) {
  pop_ch <- filter(pop_ch, mx <= 1, mx != 0) # because log(0) is infinity
  
  # The colbins to extract colors from the magmafunction are derived
  # using a beta distribution, providing us high flexibility to cut colors
  # from the magmacolor scheme
  colbins <- pbeta(seq(0,0.95,((0.95-0)/100)),4.4,2.6)
  
  colpal <- magmaadjust(100,bins=colbins, option = "magma")
  
  # Assigns color according to fixed breaks categorization 
  # Here we take the bins by equal interval from the log scale, and exponentiate them
  bins <- exp(c(-100,seq(-9.9,0,0.1)))
  
  catg <- classIntervals(pop_ch$mx, fixedBreaks=bins,
                         style = "fixed")
  color <- findColours(catg, colpal)
  
  #if (backgr_color == "white") {

  # Here we also tried from white to red and to firebrick1 and it doesn't look good at all.
  # We also tried the color blind pallete from ggthemes::show_col(ggthemes::colorblind_pal()(8))
  #  colramp <- colorRampPalette(c("white", "#CC79A7"),bias=1,space="rgb",interpolate="linear",alpha=F)
  #  colpal <- colramp(100)
  #  color <- findColours(catg, colpal)
  #}
  
  pop_ch$color <- color
}

# Gender differences in cohort mortality rates (ratio)
if (var_of_int==2) {
  non_chosen_sex <- setdiff(sexes, sexes[ch])
  pop_ch$gendif <- pop_ch$mx / pop_ch[[non_chosen_sex]] * 100
  pop_ch$gendif[pop_ch$gendif==Inf] <- NA
  
  pal <- rev(brewer.pal(11,"PRGn"))
  if (backgr_color=="black") {
    colramp <- colorRampPalette(c(pal[1],pal[6],pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)
  } else{
    colramp <- colorRampPalette(c(pal[1],"grey85",pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)
  }
  colpal <- colramp(300)
  bins <- c(seq(-50,249,1),max(pop_ch$gendif,na.rm=T))
  catg <- classIntervals(pop_ch$gendif, fixedBreaks=bins,
                         style = "fixed")
  pop_ch$color <- findColours(catg, colpal)
}   

## # Gender differences in cohort mortality rates (difference)
## if (var_of_int==3) {
##   non_chosen_sex <- setdiff(sexes, sexes[ch])
##   pop_ch$gendif <- (pop_ch$mx - pop_ch[[non_chosen_sex]])
##   pop_ch$gendif[pop_ch$gendif==Inf] <- NA

##   pal <- rev(brewer.pal(11,"PRGn"))
##   if (backgr_color=="black") {
##     colramp <- colorRampPalette(c(pal[1],pal[6],pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)
##   } else{
##     colramp <- colorRampPalette(c(pal[1],"grey85",pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)
##   }
##   colpal <- colramp(300)
##   bins <- exp(c(-100,seq(-9.9,0,0.1))) - 0.0001
##   print(min(pop_ch$gendif, na.rm = TRUE))
##   print(max(pop_ch$gendif, na.rm = TRUE))  
##   catg <- classIntervals(pop_ch$gendif, fixedBreaks=bins,
##                          style = "fixed")
##   pop_ch$color <- findColours(catg, colpal)
## }   

# First order differences
if (var_of_int==3) {
  mincoh <- min(pop_ch$Year)
  maxcoh <- max(pop_ch$Year)
  rangecoh <- mincoh:maxcoh
  # Length, if we take first order differences
  l_fod <- length(rangecoh) - 1
  
  #  Direct first order change - Example for females
  reslist <- list()
  
  for (i in 1:l_fod) {
    cmx_tm1 <- filter(pop_ch, Year == rangecoh[i])
    cmx_t <- filter(pop_ch, Year == rangecoh[i + 1])
    cmx_t <- semi_join(cmx_t, cmx_tm1, by = "Age")
    cmx_tm1 <- semi_join(cmx_tm1, cmx_t, by = "Age")

    fod <- log(cmx_t[[sexes[ch]]]) - log(cmx_tm1[[sexes[ch]]])

    fod[fod==Inf] <- NA
    reslist[[i]] <- cmx_t %>% select(Year, Age) %>% mutate(!!sexes[ch] := fod)
  }
  
  cmx_new <- bind_rows(reslist) %>% rename(change = !!sym(sexes[ch]))
  pop_ch <- left_join(pop_ch, cmx_new, by = c("Year", "Age"))
  pop_ch$change[pop_ch$change==-Inf] <- NA  


  pal <- rev(brewer.pal(11,"PRGn"))
  if (backgr_color=="black") {
    colramp <- colorRampPalette(c(pal[1],pal[6],pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)
  } else{
    colramp <- colorRampPalette(c(pal[1],pal[2],"grey85",pal[10],pal[11]),bias=1,space="rgb",interpolate="linear",alpha=F)     
  }

  colpal <- colramp(200)
  bins <- c(min(pop_ch$change,na.rm=T),
            seq(-0.495,0.495,0.005),
            max(pop_ch$change,na.rm=T))
  catg <- classIntervals(pop_ch$change, fixedBreaks=bins,
                         style = "fixed")
  pop_ch$color <- findColours(catg, colpal)
}


color_matrix <-
  complete(pop_ch, Cohort, Age, fill = list(Pop = NA, Maxpop = NA, mx = NA, color = NA, relative_pop = NA)) %>%
  select(Cohort, Age, color) %>%
  spread(Age, color) %>%
  as.matrix()

width_matrix <-
  complete(pop_ch, Cohort, Age, fill = list(Pop = NA, Maxpop = NA, mx = NA, color = NA, relative_pop = NA)) %>%
  select(Cohort, Age, relative_pop) %>%
  spread(Age, relative_pop) %>%
  as.matrix()

print("test4:")
print(tail(color_matrix))

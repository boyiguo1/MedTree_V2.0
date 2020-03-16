# source("global.R")

# library(CCA)              # R Library supporting CCA
# library(data.tree)        # R Library supporting the tree results

# Try everything method
# CCA diff.x and diff.y. One variable as split rule
# Currently using correlation to detect the association between x and projection of x
# left.out is ensure at least left.out*2 sample for either treated or untreated sample in the group
# left.out is used for how many treated or untreated are left out when selecting split value
# e.g. if left.out= 1 choosing max(min(treated x),min( untreated x))
# impurity has two option: "MeanTreatmentEffect", "varReduce"


#' Fitting MOTTE Tree in the MOTTE.RF
#'
#' @param x.b Pre-treatment covariates, i.e. microbiomes
#' @param x.e Post-treatment covariates, i.e. microbiomes
#' @param treat A vector of binary value, the arm of treatment
#' @param y.b Pre-treatment response, i.e. biomarkers
#' @param y.e Post-treatment response, i.e. biomarkers
# TODO: change the language, it is awkward.
#' @param nodesize An integer value. The threshold that control the maximum size of a node
#' @param nsplits A numeric value, the number of maximum splits
#' @param left.out left.out is ensure at least left.out*2 sample for either treated or untreated sample in the group
# left.out is used for how many treated or untreated are left out when selecting split value
# e.g. if left.out= 1 choosing max(min(treated x),min( untreated x))
#' @param seed a seed number to generate the random subsets of split candidates. Doesn't work when applying nsplit==NULL
#'
#' @return A data.tree object, node
#' @export
#'
#' @importFrom stats quantile var
#' @import data.tree
#'
# TODO: add import function here
# TODO: add description to setting reference trt.lvl. as R convention, the first level from levels function are use as the refence group
#       i.e. treatment 0/ treatment control
#' @examples
#' set.seed(1)
#' B <- create.B(10)
#' Z <- create.Z(10, 3)
#'
#' tmp.dat <- sim_MOTTE_data( n.train = 500, n.test = 200,
#' p = 10, q = 3, ratio = 0.5,
#' B = B, Z = Z)
#'
#' train.dat <- tmp.dat$train
#'
#' x.b <- scale(train.dat$x.b, center = FALSE, scale = TRUE)
#' x.e <- scale(train.dat$x.e, center = FALSE, scale = TRUE)
#' y.b <- scale(train.dat$y.b, center = FALSE, scale = TRUE)
#' y.e <- scale(train.dat$y.e, center = FALSE, scale = TRUE)
#' treat <- train.dat$trt
#' #with(train.dat,
#'     build_MOTTE_tree(x.b, x.e, factor(treat), y.b, y.e,
#'                      nodesize=30, nsplits=NULL, left.out = 0.1)
#'  #)
#'

build_MOTTE_tree_y <- function(x.b, x.e, treat, y.b, y.e,
                        nodesize, nsplits, left.out#) {
                        #, seed = 1
  ) {

  #set.seed(seed)

  trt.lvl <- levels(treat)
  if(length(trt.lvl) != 2)
    stop("Error Message: trt.lvl !=2 in build_MOTTE_tree")

  # Dimension
  n <- nrow(x.b)
  n.treat.1 <- sum(treat==trt.lvl[1])
  p <- ncol(x.b)
  q <- ncol(y.b)

  ### Base cases:
  # a)
  # Only one treatment group in terminal node
  # Comment: extremely unlikely to happen
  if(length(unique(treat))==1){
    return(
      data.tree::Node$new(
        paste("Terminal Node: ", n ," members", "Unique"),
        #xcenter = NULL,
        split.comb=NULL, split.value=NULL,
        Outcome=y.e, Treatment=treat)
    )}

  ### Base cases:
  # b)
  # The number of observations is smaller than threshold
  if(n <= nodesize){
    return(
      data.tree::Node$new(paste("Terminal Node: ", n," members"),
               #xcenter = NULL,
               split.comb=NULL, split.value=NULL,
               Outcome=y.e, Treatment=treat)
    )}

  ### Base cases:
  # c)
  # The number of observations in each group is not larger than dimensions
  # Enforced to prevent error in CCA

  if(min(n-n.treat.1,n.treat.1) <= max(p,q)){
    return(
      data.tree::Node$new(paste("Terminal Node: ", n ," members"),
               #xcenter = NULL,
               split.comb=NULL, split.value=NULL,
               Outcome=y.e, Treatment=treat)
    )}

  ### Recursive cases:

  # Local level CCA using the subset of variables
  diff.x <- x.e - x.b
  diff.y <- y.e - y.b

  # Create the augmented matrices for both treatment arm
  # Each of the matrix have p(X^b) + p(\Delta X) + q (\Delta Y) columns
  # Trtment lvl 1

  trt.1.left.matrix <-
    rbind(
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0, nrow=n.treat.1, ncol=p+q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=2*p),diff.y[treat==trt.lvl[1],,drop=FALSE])

    )
  trt.1.right.matrix <-
    rbind(
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=2*p),diff.y[treat==trt.lvl[1],,drop=FALSE]),
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0, nrow=n.treat.1, ncol=p+q))
    )

  # Trtment lvl 2

  trt.2.left.matrix <-
    rbind(
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0, nrow=n-n.treat.1, ncol=p+q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.y[treat==trt.lvl[2],,drop=FALSE])
    )
  trt.2.right.matrix <-
    rbind(
      cbind(matrix(0,nrow=n-n.treat.1,ncol=p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.y[treat==trt.lvl[2],,drop=FALSE]),
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0, nrow=n-n.treat.1, ncol=p+q))
         )

  # Conduct CCA
  trt.1.cancor.res <- CCA::cc(rbind(trt.1.left.matrix,trt.1.right.matrix),
                              rbind(trt.1.right.matrix, trt.1.left.matrix))
  trt.2.cancor.res <- CCA::cc(rbind(trt.2.left.matrix, trt.2.right.matrix),
                              rbind(trt.2.right.matrix, trt.2.left.matrix))

  # Use the CCA scores
  # In this step we use the first canonical direction
  # Each xceof column is one canonical loading
  # TODO: write a function that extract ccs.
  trt.1.x.loading <- trt.1.cancor.res$xcoef[1:p,1]
  trt.2.x.loading <- trt.2.cancor.res$xcoef[1:p,1]
  # TODO: verify this
  diff.y.0.loading <- trt.1.cancor.res$xcoef[(2*p+1):(2*p+q),1]
  diff.y.1.loading <- trt.2.cancor.res$xcoef[(2*p+1):(2*p+q),1]
  #trt.2.y.loading <- trt.2.cancor.res$xcoef[(2*p+1):(ncol(Left.matrix)),1]
  # TODO: check if xcoef give the same as ycoef


  # Calculate the canonical variates
   #x.proj <- scale(x.b,center=x.center, scale=F)%*%x.loading
  y0.proj <- diff.y %*% diff.y.0.loading
  y1.proj <- diff.y %*% diff.y.1.loading

  x.loading <- trt.2.x.loading - trt.1.x.loading
  x.proj <- x.b %*% x.loading
  #y.proj <- diff.y %*% (trt.2.x.loading - trt.1.x.loading)


  # Generate a vector consists of split value candidates
  #split.value.cand <- unique(x.proj)

  split.value.cand.treat1 <- unique(x.proj[treat==trt.lvl[1]])
  split.value.cand.treat2 <- unique(x.proj[treat==trt.lvl[2]])

  treat1.boundry <- stats::quantile(split.value.cand.treat1, c(left.out, 1-left.out))
  treat2.boundry <- stats::quantile(split.value.cand.treat2, c(left.out, 1-left.out))

  split.value.cand <- unique(x.proj)
  # Here it used the internal funciton is.between
  split.value.cand <- split.value.cand[is.between(unique(x.proj),
                                 min = max(treat1.boundry[1],treat2.boundry[1]),
                                 max = min(treat1.boundry[2],treat2.boundry[2]))]

  if(length(split.value.cand)==0) {
    return(
      data.tree::Node$new(paste("Terminal Node: ", n," members. No split"),
               #xcenter = NULL,
               split.comb=NULL, split.value=NULL,
               Outcome=y.e, Treatment=treat)
    )
  }

  # Only checking on subset of candidates
  # Reduce calculation load
  if(!is.null(nsplits)) {
    split.value.cand <- sample(split.value.cand,
                               min(nsplits, length(split.value.cand)),
                               replace=FALSE)
  }

  # Calculate impurity scores regarding variance reduction
  # impurity.score is a 2*n' matrix, the first row is the split value candidates, and second row is the
  # corresponding variance reduction
  impurity.score <- sapply(split.value.cand,FUN=function(x) {

    L.node.indices <- x.proj >= x
    R.node.indices <- x.proj < x

    t1.indices <- treat == trt.lvl[1]
    t2.indices <- treat == trt.lvl[2]

    L.length <- sum(L.node.indices)
    R.length <- sum(R.node.indices)
    # revision to split based on treatment difference reflected on X^b
    #total.var <- (n-1)/n*var(y0.proj) + (n-1)/n*var(y1.proj)
    total.var <- (n-1)/n*var(x.proj)
    left.var <- (L.length-1)/n*(var(y0.proj[L.node.indices & t1.indices]) + var(y1.proj[L.node.indices & t2.indices]))
    #left.var <- (L.length-1)/n*var(x.proj[L.node.indices])
    right.var <- (R.length-1)/n*(var(y0.proj[R.node.indices & t1.indices]) + var(y1.proj[R.node.indices & t2.indices]))
    #right.var <- (R.length-1)/n*var(x.proj[R.node.indices])
    return(
      matrix(
        c(x,total.var-left.var-right.var),
        nrow=2,ncol=1
      )
    )
  })

  split.value <- impurity.score[1,which.max(impurity.score[2,])]

  # Create a new node
  node <-data.tree::Node$new(
    paste("split.value = ", round(split.value, digits=3)),                        # Node name: must be unique to siblings
    #xcenter = x.center,
    split.comb=x.loading, split.value=split.value,
    Outcome=NULL, Treatment=NULL
  )

  greater.indices <- which(x.proj>=split.value)
  less.indices <- which(x.proj<split.value)

  if(length(greater.indices)<=0) stop("greater indices <=0")
  if(length(less.indices)<=0) stop("less indices < 0")

  child.ge <- build_MOTTE_tree(
    x.b = x.b[greater.indices,,drop=FALSE], x.e = x.e[greater.indices,,drop=FALSE],
    treat = treat[greater.indices],
    y.b = y.b[greater.indices,,drop=FALSE], y.e = y.e[greater.indices,,drop=FALSE],
    nodesize = nodesize, nsplits = nsplits, left.out = left.out
  )

  #
  child.l <- build_MOTTE_tree(
    x.b = x.b[less.indices,,drop=FALSE], x.e = x.e[less.indices,,drop=FALSE],
    treat = treat[less.indices],
    y.b = y.b[less.indices,,drop=FALSE], y.e = y.e[less.indices,,drop=FALSE],
    nodesize = nodesize, nsplits = nsplits, left.out = left.out
  )
  # side == TRUE means greater or equal than
  # side ==FALSE means less than
  # For error prevention when traverse the tree
  child.ge$side <- TRUE
  child.l$side <- FALSE

  # Rename child nodes in case of duplicate names between silblings
  child.ge$name <- paste("Greater Child: ",child.ge$name)
  child.l$name <- paste("Smaller Child: ",child.l$name)

  # Insert Children in the tree
  # TODO::add data.tree:: to somewhere
  node$AddChildNode(child.ge)
  node$AddChildNode(child.l)
  return(node)
}


#TODO: add a recursive function, which contains standardization of the data.
# Record the centers
# x.center <- attr(scale(x.b, center = T, scale = FALSE),"scaled:center")
# diff.y.0.center <- attr(scale(diff.y[treat==trt.lvl[1],,drop=FALSE],center = T, scale = FALSE),"scaled:center")
# diff.y.1.center <- attr(scale(diff.y[treat==trt.lvl[2],,drop=FALSE],center = T, scale = FALSE),"scaled:center")
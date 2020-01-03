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
#' @param nodesize TODO: add description
#' @param nsplits A numeric value, the number of maximum splits
#' @param left.out left.out is ensure at least left.out*2 sample for either treated or untreated sample in the group
# left.out is used for how many treated or untreated are left out when selecting split value
# e.g. if left.out= 1 choosing max(min(treated x),min( untreated x))
#'
#' @return A data.tree object
#' @export
#'
#' @examples
#' # TODO: Add an example
build_MOTTE_tree <- function(x.b, x.e, treat, y.b, y.e,
                        nodesize, nsplits, left.out) {

  trt.lvl <- levels(treat)
  if(length(trt.lvl) != 2)
    stop("Error Message: trt.lvl !=2 in buildTree")

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
      Node$new(
        paste("Terminal Node: ", n ," members", "Unique"),
        xcenter = NULL, split.comb=NULL, split.value=NULL,
        Outcome=y.e, Treatment=treat)
    )}

  ### Base cases:
  # b)
  # The number of observations is smaller than threshold
  if(n <= nodesize){
    return(
      Node$new(paste("Terminal Node: ", n," members"),
               xcenter = NULL, split.comb=NULL, split.value=NULL,
               Outcome=y.e, Treatment=treat)
    )}

  ### Base cases:
  # c)
  # The number of observations in each group is not larger than dimensions
  # Enforced to prevent error in CCA

  if(min(n-n.treat.1,n.treat.1) <= max(p,q)){
    return(
      Node$new(paste("Terminal Node: ", n ," members"),
               xcenter = NULL, split.comb=NULL, split.value=NULL,
               Outcome=y.e, Treatment=treat)
    )}

  ### Recursive cases:

  # Local level CCA using the subset of variables
  diff.x <- x.e - x.b
  diff.y <- y.e - y.b

  # Create the augmented matrices
  Left.matrix <-
    rbind(
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*p+2*q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=p+2*q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=3*p),diff.y[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=3*p+q),diff.y[treat==trt.lvl[2],,drop=FALSE]),
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=p+2*q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=3*p),diff.y[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=3*p+q),diff.y[treat==trt.lvl[2],,drop=FALSE])
    )

  Right.matrix <-
    rbind(
      cbind(matrix(0,nrow=n.treat.1,ncol=3*p),diff.y[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=3*p+q),diff.y[treat==trt.lvl[2],,drop=FALSE]),
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=p+2*q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=3*p),diff.y[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=3*p+q),diff.y[treat==trt.lvl[2],,drop=FALSE]),
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=2*p+2*q)),
      cbind(x.b[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*p+2*q)),
      cbind(matrix(0,nrow=n.treat.1,ncol=p),diff.x[treat==trt.lvl[1],,drop=FALSE],matrix(0,nrow=n.treat.1,ncol=p+2*q)),
      cbind(matrix(0,nrow=n-n.treat.1,ncol=2*p),diff.x[treat==trt.lvl[2],,drop=FALSE],matrix(0,nrow=n-n.treat.1,ncol=2*q))
    )

  # Record the centers
  x.center <- attr(scale(x.b, center = T, scale = FALSE),"scaled:center")
  diff.y.0.center <- attr(scale(diff.y[treat==trt.lvl[1],,drop=FALSE],center = T, scale = FALSE),"scaled:center")
  diff.y.1.center <- attr(scale(diff.y[treat==trt.lvl[2],,drop=FALSE],center = T, scale = FALSE),"scaled:center")

  # Conduct CCA
  cancor.res <- cc(scale(Left.matrix,center =T, scale=F),
                   scale(Right.matrix,center = T, scale=F))

  # Use the CCA scores
  # In this step we use the first canonical direction
  # Each xceof column is one canonical loading
  x.loading <- cancor.res$xcoef[1:p,1]
  diff.y.0.loading <- cancor.res$xcoef[(3*p+1):(3*p+q),1]
  diff.y.1.loading <- cancor.res$xcoef[(3*p+q+1):(ncol(Left.matrix)),1]

  # Calculate the canonical variates
  x.proj <- scale(x.b,center=x.center, scale=F)%*%x.loading
  y0.proj <- scale(diff.y, center = diff.y.0.center, scale=F)%*%diff.y.0.loading
  y1.proj <- scale(diff.y, center = diff.y.1.center, scale= F) %*% diff.y.1.loading

  # Generate a vector consists of split value candidates
  #split.value.cand <- unique(x.proj)

  split.value.cand.treat1 <- unique(x.proj[treat==trt.lvl[1]])
  split.value.cand.treat2 <- unique(x.proj[treat==trt.lvl[2]])

  treat1.boundry <- quantile(split.value.cand.treat1, c(left.out, 1-left.out))
  treat2.boundry <- quantile(split.value.cand.treat2, c(left.out, 1-left.out))

  split.value.cand <- unique(x.proj)
  split.value.cand <- split.value.cand[is.between(unique(x.proj),
                                 min = max(treat1.boundry[1],treat2.boundry[1]),
                                 max = min(treat1.boundry[2],treat2.boundry[2]))]

  if(length(split.value.cand)==0) {
    return(
      Node$new(paste("Terminal Node: ", n," members. No split"),
               xcenter = NULL, split.comb=NULL, split.value=NULL,
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

    L.length <- sum(L.node.indices)
    R.length <- sum(R.node.indices)

    total.var <- (n-1)/n*var(y0.proj) + (n-1)/n*var(y1.proj)
    left.var <- (L.length-1)/n*(var(y0.proj[L.node.indices]) + var(y1.proj[L.node.indices]))
    right.var <- (R.length-1)/n*(var(y0.proj[R.node.indices]) + var(y1.proj[R.node.indices]))
    return(
      matrix(
        c(x,total.var-left.var-right.var),
        nrow=2,ncol=1
      )
    )
  })

  split.value <- impurity.score[1,which.max(impurity.score[2,])]

  # Create a new node
  node <- Node$new(
    paste("split.value = ", round(split.value, digits=3)),                        # Node name: must be unique to siblings
    xcenter = x.center,
    split.comb=x.loading, split.value=split.value,
    Outcome=NULL, Treatment=NULL
  )

  greater.indices <- which(x.proj>=split.value)
  less.indices <- which(x.proj<split.value)

  if(length(greater.indices)<=0) stop("greater indices <=0")
  if(length(less.indices)<=0) stop("less indices < 0")

  child.ge <- buildTree(
    x.b = x.b[greater.indices,,drop=FALSE], x.e = x.e[greater.indices,,drop=FALSE],
    treat = treat[greater.indices],
    y.b = y.b[greater.indices,,drop=FALSE], y.e = y.e[greater.indices,,drop=FALSE],
    nodesize = nodesize, nsplits = nsplits, left.out = left.out
  )

  #
  child.l <- buildTree(
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
  node$AddChildNode(child.ge)
  node$AddChildNode(child.l)
  return(node)
}
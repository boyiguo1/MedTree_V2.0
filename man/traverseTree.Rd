% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/predict.R
\name{traverseTree}
\alias{traverseTree}
\title{Traverse Tree}
\usage{
traverseTree(root, x.b)
}
\arguments{
\item{root}{data.tree}

\item{x.b}{a single row vector contains the baseline variates of one observation}
}
\value{
A list contain two matrices: OUTCOME and TREATMENT
}
\description{
Traverse MOTTE.Tree
}

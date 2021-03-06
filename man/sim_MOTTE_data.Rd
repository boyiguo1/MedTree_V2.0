% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sim_MOTTE_data.R
\name{sim_MOTTE_data}
\alias{sim_MOTTE_data}
\title{Simulate MOTTE formated data}
\usage{
sim_MOTTE_data(
  n.train = 500,
  n.test = 200,
  p = 10,
  q = 3,
  ratio = 0.5,
  cov.mat = diag(p),
  trt.f = c("Linear", "Polynomial", "Box"),
  link.f = c("Linear", "Polynomial"),
  B,
  Z
)
}
\arguments{
\item{n.train}{An integer value, sample size for training data}

\item{n.test}{An integer value, sample size for testing data}

\item{p}{An integer value, the dimensionality of covaraites (X)}

\item{q}{An integer value, the dimensionality of responses (Y)}

\item{ratio}{An fraction value, the ratio between treatment groups}

\item{cov.mat}{Covariance matrix for X.b}

\item{trt.f}{character, the name of treatment effect funciton}

\item{link.f}{character, the name of treatment effect funciton}

\item{B}{matrix, the coefficient matrix used in the trt.f}

\item{Z}{matrix, the coefficient matrix used in the link.f}
}
\value{
A nested list that contain training data and testing data. TODO: add more introdcution to whats in the list
}
\description{
Simulate MOTTE formated data
}
\examples{
set.seed(1)

n.train = 200
n.test = 100
p = 10
q = 3
ratio = 0.5
cov.mat = diag(p)
trt.f = "Polynomial"
link.f = "Polynomial"
B = create.B(p)
Z = create.Z(p,q)

# B <- create.B(10)
# Z <- create.Z(10, 3)

sim.dat <- sim_MOTTE_data( n.train = 500, n.test = 200,
p = 10, q = 3, ratio = 0.5,
B = B, Z = Z)

}

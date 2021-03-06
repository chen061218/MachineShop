% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ML_StackedModel.R
\name{StackedModel}
\alias{StackedModel}
\title{Stacked Regression Model}
\usage{
StackedModel(..., control = MachineShop::settings("control"), weights = NULL)
}
\arguments{
\item{...}{\link[=models]{model} functions, function names, calls, or vector
of these to serve as base learners.}

\item{control}{\link[=controls]{control} function, function name, or call
defining the resampling method to be employed for the estimation of base
learner weights.}

\item{weights}{optional fixed base learner weights.}
}
\value{
\code{StackedModel} class object that inherits from \code{MLModel}.
}
\description{
Fit a stacked regression model from multiple base learners.
}
\details{
\describe{
  \item{Response Types:}{\code{factor}, \code{numeric}, \code{ordered},
    \code{Surv}}
}
}
\examples{
model <- StackedModel(GBMModel, SVMRadialModel, GLMNetModel(lambda = 0.01))
model_fit <- fit(sale_amount ~ ., data = ICHomes, model = model)
predict(model_fit, newdata = ICHomes)

}
\references{
Breiman, L. (1996) \emph{Stacked Regression.} Machine Learning, 24, 49--64.
}
\seealso{
\code{\link{fit}}, \code{\link{resample}}
}

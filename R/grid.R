#' Tuning Grid Control
#'
#' Defines control parameters for a tuning grid.
#'
#' @param length number of values to be generated for each model parameter in
#'   the tuning grid.
#' @param random number of unique grid points to sample at random, \code{Inf}
#'   for all random points, or \code{FALSE} for all fixed points.
#'
#' @return \code{Grid} class object.
#'
#' @seealso \code{\link{TunedModel}}
#'
#' @examples
#' TunedModel(GBMModel, grid = Grid(10, random = 5))
#'
Grid <- function(length = 3, random = FALSE) {
  if (is.finite(length)) {
    length <- as.integer(length[[1]])
    if (length <= 0) stop("grid parameter 'length' must be >= 1")
  } else {
    stop("grid parameter 'length' must be numeric")
  }

  if (isTRUE(random) || is.numeric(random)) {
    random <- floor(random[[1]])
    if (random <= 0) stop ("number of 'random' grid points must be >= 1")
  } else if (!isFALSE(random)) {
    stop("'random' grid value must be logical or numeric")
  }

  new("Grid", length = length, random = random)
}


#' Tuning Parameters Grid
#'
#' Defines a tuning grid from a set of parameters.
#'
#' @rdname ParameterGrid
#'
#' @param ... named \code{param} objects as defined in the \pkg{dials} package.
#' @param x list of named \code{param} objects or a
#'   \code{\link[dials]{parameters}} object.
#' @param length single number or vector of numbers of parameter values to use
#'   in constructing a regular grid if \code{random = FALSE}; ignored otherwise.
#' @param random number of unique grid points to sample at random or
#'   \code{FALSE} for all points from a regular grid defined by \code{length}.
#'
#' @return \code{ParameterGrid} class object that inherits from
#' \code{parameters} and \code{Grid}.
#'
#' @seealso \code{\link{TunedModel}}
#'
#' @examples
#' ## GBMModel tuning parameters
#' library(dials)
#'
#' grid <- ParameterGrid(
#'   n.trees = trees(),
#'   interaction.depth = tree_depth(),
#'   random = 5
#' )
#' TunedModel(GBMModel, grid = grid)
#'
ParameterGrid <- function(...) {
  UseMethod("ParameterGrid")
}


#' @rdname ParameterGrid
#'
ParameterGrid.param <- function(..., length = 3, random = FALSE) {
  ParameterGrid(list(...), length = length, random = random)
}


#' @rdname ParameterGrid
#'
ParameterGrid.list <- function(x, length = 3, random = FALSE, ...) {
  ParameterGrid(parameters(x), length = length, random = random)
}


#' @rdname ParameterGrid
#'
ParameterGrid.parameters <- function(x, length = 3, random = FALSE, ...) {
  if (all(is.finite(length))) {
    length <- as.integer(length)
    if (any(length < 0)) stop("grid parameter 'length' must be >= 0")
  } else {
    stop("grid parameter 'length' must be numeric")
  }

  if (isFALSE(random)) {
    if (length(length) > 1) length <- rep_len(length, nrow(x))
    keep <- length > 0
    x <- x[keep, ]
    length <- length[keep]
  } else if (is.finite(random)) {
    random <- as.integer(random[[1]])
    if (random <= 0) stop ("number of 'random' grid points must be >= 1")
  } else {
    stop("'random' grid value must be logical or numeric")
  }

  new("ParameterGrid", x, length = length, random = random)
}


as.grid <- function(x, ...) {
  UseMethod("as.grid")
}


as.grid.default <- function(x, ...) {
  stop("unsupported grid object of class ", class(x)[1])
}


as.grid.tbl_df <- function(x, fixed = tibble(), ...) {
  x[names(fixed)] <- fixed
  if (ncol(x)) x[!duplicated(x), ] else x
}


as.grid.Grid <- function(x, ..., model, fixed = tibble()) {
  mf <- ModelFrame(..., na.rm = FALSE)
  params_list <- model@grid(mf, length = x@length, random = x@random)
  params <- map(unique, params_list)
  params[lengths(params) == 0] <- NULL
  as.grid(expand_params(params, random = x@random), fixed = fixed)
}


as.grid.ParameterGrid <- function(x, ..., model, fixed = tibble()) {
  grid <- if (nrow(x)) {
    if (any(map_logi(dials::has_unknowns, x$object))) {
      mf <- ModelFrame(..., na.rm = FALSE)
      data <- switch(model@predictor_encoding,
                     "model.matrix" = model.matrix(mf, intercept = FALSE),
                     "terms" = {
                       mf_terms <- attributes(terms(mf))
                       var_list <- eval(mf_terms$variables, mf)
                       names(var_list) <- rownames(mf_terms$factors)
                       as.data.frame(var_list[-c(1, mf_terms$offset)])
                     })
      x <- dials::finalize(x, x = data)
    }
    if (x@random) {
      dials::grid_random(x, size = x@random)
    } else {
      dials::grid_regular(x, levels = x@length)
    }
  } else {
    tibble(.rows = 1)
  }
  as.grid(grid, fixed = fixed)
}

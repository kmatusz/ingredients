#' Internal Function for Individual Variable Profiles
#'
#' This function calculates individual variable profiles (ceteris paribus profiles), i.e. series of predictions from a model calculated for observations with altered single coordinate.
#'
#' Note that \code{calculate_variable_profile} function is S3 generic.
#' If you want to work on non standard data sources (like H2O ddf, external databases)
#' you should overload it.
#'
#' @param data set of observations. Profile will be calculated for every observation (every row)
#' @param variable_splits named list of vectors. Elements of the list are vectors with points in which profiles should be calculated. See an example for more details.
#' @param predict_function function that takes data and model and returns numeric predictions. Note that the ... arguments will be passed to this function.
#' @param model a model that will be passed to the \code{predict_function}
#' @param ... other parameters that will be passed to the \code{predict_function}
#'
#' @references Predictive Models: Visual Exploration, Explanation and Debugging \url{https://pbiecek.github.io/PM_VEE}
#'
#' @return a data frame with profiles for selected variables and selected observations
#' @examples
#' library("DALEX")
#'  \donttest{
#' library("randomForest")
#' set.seed(59)
#' apartments_rf_model <- randomForest(m2.price ~ construction.year + surface + floor +
#'                                       no.rooms + district, data = apartments)
#' vars <- c("construction.year", "surface", "floor", "no.rooms", "district")
#' variable_splits <- calculate_variable_split(apartments, vars)
#' new_apartment <- apartmentsTest[1:10, ]
#' profiles <- calculate_variable_profile(new_apartment, variable_splits,
#'                                apartments_rf_model)
#' head(profiles)
#'
#' # only subset of observations
#' small_apartments <- select_sample(apartmentsTest, n = 10)
#' small_apartments
#' small_profiles <- calculate_variable_profile(small_apartments, variable_splits,
#'                                apartments_rf_model)
#' head(small_profiles)
#'
#' # neighbors for a selected observation
#' new_apartment <- apartments[1, 2:6]
#' small_apartments <- select_neighbours(apartmentsTest, new_apartment, n = 10)
#' small_apartments
#' small_profiles <- calculate_variable_profile(small_apartments, variable_splits,
#'                                apartments_rf_model)
#' head(new_apartment)
#' head(small_profiles)
#' }
#' @export
calculate_variable_profile <- function(data, variable_splits, model, predict_function = predict, ...) {
  UseMethod("calculate_variable_profile")
}
#' @export
calculate_variable_profile.default <- function(data, variable_splits, model, predict_function = predict, ...) {
  variables <- names(variable_splits)
  profiles <- lapply(variables, function(variable) {
    split_points <- variable_splits[[variable]]

    # remember ids of selected points
    if (is.null(rownames(data))) {
      ids <- rep(1:nrow(data), each = length(split_points)) # it never goes here, because null rownames are automatically setted to 1:n
    } else {
      ids <- rep(rownames(data), each = length(split_points))
    }
    new_data <- data[rep(1:nrow(data), each = length(split_points)),]
    new_data[, variable] <- rep(split_points, nrow(data))

    yhat <- predict_function(model, new_data, ...)
    new_data <- cbind(new_data,
                      `_yhat_` = yhat,
                      `_vname_` = variable,
                      `_ids_` = ids)
    new_data
  })
  profile <- do.call(rbind, profiles)
  class(profile) <- c("individual_variable_profile", class(profile))
  profile
}


#' Internal Function for Split Points for Selected Variables
#'
#' This function calculate candidate splits for each selected variable.
#' For numerical variables splits are calculated as percentiles
#' (in general uniform quantiles of the length grid_points).
#' For all other variables splits are calculated as unique values.
#'
#' Note that \code{calculate_variable_split} function is S3 generic.
#' If you want to work on non standard data sources (like H2O ddf, external databases)
#' you should overload it.
#'
#' @param data validation dataset. Is used to determine distribution of observations.
#' @param variables names of variables for which splits shall be calculated
#' @param grid_points number of points used for response path
#'
#' @return A named list with splits for selected variables
#' @importFrom stats predict
#' @examples
#' library("DALEX")
#'  \dontrun{
#' library("randomForest")
#' set.seed(59)
#' apartments_rf_model <- randomForest(m2.price ~ construction.year + surface + floor +
#'                                       no.rooms + district, data = apartments)
#' vars <- c("construction.year", "surface", "floor", "no.rooms", "district")
#' calculate_variable_split(apartments, vars)
#' }
#' @export
calculate_variable_split <- function(data, variables = colnames(data), grid_points = 101) {
  UseMethod("calculate_variable_split")
}
#' @export
calculate_variable_split.default <- function(data, variables = colnames(data), grid_points = 101) {
  variable_splits <- lapply(variables, function(var) {
    selected_column <- data[,var]
    if (is.numeric(selected_column)) {
      probs <- seq(0, 1, length.out = grid_points)
      unique(quantile(selected_column, probs = probs))
    } else {
      unique(selected_column)
    }
  })
  names(variable_splits) <- variables
  variable_splits
}


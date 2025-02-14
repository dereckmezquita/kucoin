# File: ./R/KucoinSpotMarketData.R

box::use(
    ./utils[get_api_keys]
)

#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list()
)

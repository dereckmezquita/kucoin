# File: ./R/KucoinSpotMarketData.R

box::use(
    impl = ./impl_market_data,
    ./utils[ get_api_keys ]
)

#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list()
)

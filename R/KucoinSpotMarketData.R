# File: KucoinSpotMarketData

box::use(
    R6,
    rlang[abort],
    ./market[],
    ./utils[get_api_keys]
)

#' @export
KucoinSpotMarketData <- R6::R6Class(
    "KucoinSpotMarketData",
    public = list(
        #' @field config A list containing API configuration parameters such as
        #' `api_key`, `api_secret`, `api_passphrase`, `base_url`, and `key_version`.
        config = NULL,
        
        #' Initialize a new KucoinSpotMarketData object.
        #'
        #' @description
        #' Sets up the configuration for making authenticated API requests.
        #' If no configuration is provided, `get_api_keys()` is invoked to load the necessary credentials from environment variables.
        #'
        #' @param config A list containing API configuration parameters.
        #'               Defaults to the output of `get_api_keys()`.
        #' @return A new instance of the `KucoinSpotMarketData` class.
        initialize = function(config = get_api_keys()) {
            self$config <- config
        }
    )
)

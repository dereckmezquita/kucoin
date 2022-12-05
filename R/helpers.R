# response processor ------------------------------------------------------
# response analyzer
analyze_response <- function(x) {
    # stop if not return json
    if (httr::http_type(x) != "application/json") {
        stop("Server not responded correctly")
    }

    # stop if server responding with error
    if (httr::http_error(x)) {
        rlang::abort(stringr::str_interp('Stopped with message: "${httr::http_status(x)$message}"'))
    }

    # return original if all success
    return(x)
}

# input processor ---------------------------------------------------------
# convert conventional pair symbol to KuCoin's API standard
prep_symbols <- function(x, revert = FALSE) {
    if (revert) {
        x <- gsub("\\-", "\\/", x)
    } else {
        x <- gsub("\\/", "\\-", x)
    }
  
    return(x)
}

# format date input
prep_datetime <- function(x) {
    x <- as.numeric(x)

    if (nchar(as.character(x)) > 10) {
        x <- floor(x)
    }

    return(x)
}

# format frequency input
prep_frequency <- function(x) {
    if (!(is.character(x) & length(x) == 1)) {
        rlang::abort("Frequency should be a character vector with length equal to one")
    }

    lkp <- data.table::fread(
        '"freq","formatted"
        "1 minute","1min"
        "3 minutes","3min"
        "5 minutes","5min"
        "15 minutes","15min"
        "30 minutes","30min"
        "1 hour","1hour"
        "2 hours","2hour"
        "4 hours","4hour"
        "6 hours","6hour"
        "8 hours","8hour"
        "12 hours","12hour"
        "1 day","1day"
        "1 week","1week"'
    )

    x <- lkp[freq == x, ]$formatted

    if (length(x) == 0) {
        rlang::abort("Unsupported frequency! See function documentation for helps")
    }

    return(x)
}

# prepare datetime range
prep_datetime_range <- function(from, to, frequency) {
    this.frequency <- frequency

    # readjust input
    from <- lubridate::floor_date(from, frequency)
    to <- lubridate::ceiling_date(to, frequency)

    # prepare frequency lookup table
    lkp <- data.table::fread(
        '"frequency", "num", "chr"
        "1 minute", 1, "mins"
        "3 minutes", 3, "mins"
        "5 minutes", 5, "mins"
        "15 minutes", 15, "mins"
        "30 minutes", 30, "mins"
        "1 hour", 1, "hours"
        "2 hours", 2, "hours"
        "4 hours", 4, "hours"
        "6 hours", 6, "hours"
        "8 hours", 8, "hours"
        "12 hours", 12, "hours"
        "1 day", 1, "days"
        "1 week", 1, "weeks"'
    )

    # get numeric and character part from frequency
    num <- lkp[frequency == this.frequency, ]$num
    chr <- lkp[frequency == this.frequency, ]$chr

    # calculate time difference
    timelength <- difftime(
        time1 = to,
        time2 = from,
        units = chr
    )

    timelength <- floor(as.numeric(timelength) / num) + 1

    # create time sequence
    timeseq <- seq.POSIXt(from, by = paste(num, chr), length.out = timelength)

    # prepare time range lookup table
    start_index <- c(1, c(2:timelength)[2:timelength %% 1500 == 0])
    end_index <- c(start_index[-1] - 1, timelength)

    results <- data.table::data.table(
        from = timeseq[start_index],
        to = timeseq[end_index]
    )

    # return the results
    return(results)
}

prep_query_strings <- function(queries) {

    # convert to query strings
    if (length(queries) > 0) {
        results <- c()

        for (i in names(queries)) {
            result <- paste(i, queries[[i]], sep = "=")
            results <- c(results, result)
        }
        results <- paste0("?", paste0(results, collapse = "&"))
    } else {
        results <- ""
    }

    # return the results
    return(results)
}

# api base data -----------------------------------------------------------
# paths/endpoints urls lookup
get_base_url <- function(endpoint = "https://api.kucoin.com") {
    # https://openapi-sandbox.kucoin.com
    # https://api.kucoin.com/

    if (nchar(Sys.getenv("KC-API-ENDPOINT")) != 0) {
        return(Sys.getenv("KC-API-ENDPOINT"))
    }

    return(endpoint)
}

# paths/endpoints urls lookup
get_paths <- function(x, type = "path", append = NULL) {
    this.x <- x

    # --------------------
    # TODO: Get Symbols List(deprecated) - GET /api/v1/symbols

    # https://docs.kucoin.com/#get-klines

    # lookup table
    lkp <- data.table::fread(
        '"x", "endpoint", "path"
        "accounts", "/api/v1/accounts", "api/v1/accounts"
        "klines", "/api/v1/market/candles", "api/v1/market/candles"
        "orders", "/api/v1/orders", "api/v1/orders"
        "symbols", "/api/v2/symbols", "api/v2/symbols"
        "symbols-deprecated", "/api/v1/symbols", "api/v1/symbols"
        "time", "/api/v1/timestamp", "api/v1/timestamp"
        "currencies", "/api/v2/currencies", "api/v2/currencies"
        "deposit-addresses", "/api/v2/deposit-addresses", "api/v2/deposit-addresses"'
    )

    # convert to data frame
    # lkp <- as.data.frame(lkp)

    # get specified endpoint
    results <- lkp[x == this.x, ][[type]]

    # append if not null
    if (!is.null(append)) {
        results <- paste0(results, "/", append)
    }

    # return the result
    return(results)
}

# miscellaneous -----------------------------------------------------------
# convert names to snake case
# https://stackoverflow.com/questions/73203811/how-to-convert-any-string-to-snake-case-using-only-base-r
to_snake_case <- function(vector) {
    return(gsub(" ", "_", tolower(gsub("(.)([A-Z])", "\\1 \\2", vector))))
}

collapse <- function(vector) {
    if (length(vector) == 0) {
        return(vector)
    }

    return(paste0(vector, collapse = ","))
}
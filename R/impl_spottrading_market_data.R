# File: ./R/impl_spottrading_market_data.R

# box::use(
#     ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
#     ./utils[ build_query, get_api_keys, get_base_url ],
#     ./utils_time_convert_kucoin[ verify_symbol, time_convert_from_kucoin ],
#     coro[async, await],
#     data.table[as.data.table, data.table, rbindlist, setcolorder, setnames],
#     httr[GET, timeout],
#     rlang[abort],
#     utils[modifyList]
# )

#' Get Announcements (Implementation)
#'
#' Retrieves the latest announcements from the KuCoin API asynchronously, aggregating paginated results into a single `data.table`. This internal function is designed for use within a larger system and is not intended for direct end-user consumption.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Merges default parameters (`currentPage = 1`, `pageSize = 50`, `annType = "latest-announcements"`, `lang = "en_US"`) with user-supplied `query` using `utils::modifyList()`.
#' 2. **URL Assembly**: Combines `base_url` with `/api/v3/announcements` and the query string from `build_query()`.
#' 3. **Page Fetching**: Defines an async `fetch_page` function to send a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Pagination**: Utilises `auto_paginate` to fetch all pages up to `max_pages`, extracting `"items"` from each response.
#' 5. **Aggregation**: Combines results into a `data.table` with `data.table::rbindlist()`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/announcements`
#'
#' ### Usage
#' Utilised to gather KuCoin news announcements (e.g., updates, promotions) for market analysis or display.
#'
#' ### Official Documentation
#' [KuCoin Get Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param query Named list; additional query parameters to filter announcements. Supported:
#'   - `currentPage` (integer, optional): Page number to retrieve.
#'   - `pageSize` (integer, optional): Number of announcements per page.
#'   - `annType` (string, optional): Type of announcements (e.g., `"latest-announcements"`, `"activities"`, `"product-updates"`, `"vip"`, `"maintenance-updates"`, `"delistings"`, `"others"`, `"api-campaigns"`, `"new-listings"`).
#'   - `lang` (string, optional): Language (e.g., `"en_US"`, `"zh_HK"`, `"ja_JP"`).
#'   - `startTime` (integer, optional): Start time in milliseconds.
#'   - `endTime` (integer, optional): End time in milliseconds.
#' @param page_size Integer; number of results per page (default 50).
#' @param max_pages Numeric; maximum number of pages to fetch (default `Inf` for all pages).
#' @return Promise resolving to a `data.table` containing:
#'   - `annId` (integer): Unique announcement ID.
#'   - `annTitle` (character): Announcement title.
#'   - `annType` (list): List of announcement types.
#'   - `annDesc` (character): Announcement description.
#'   - `cTime` (integer): Release time in Unix milliseconds.
#'   - `language` (character): Language of the announcement.
#'   - `annUrl` (character): URL to the full announcement.
#'   - `currentPage` (integer): Current page number.
#'   - `pageSize` (integer): Records per page.
#'   - `totalNum` (integer): Total number of announcements.
#'   - `totalPage` (integer): Total pages available.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Default: latest announcements in English
#'   announcements <- await(get_announcements_impl())
#'   print(announcements)
#'   # Filtered by type and language
#'   activities <- await(get_announcements_impl(query = list(annType = "activities", lang = "en_US")))
#'   print(activities)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist
#' @importFrom utils modifyList
#' @importFrom rlang abort
#' @export
get_announcements_impl <- coro::async(function(
  base_url = get_base_url(),
  query = list(),
  page_size = 50,
  max_pages = Inf
) {
    tryCatch({
        # Merge default pagination parameters with user-supplied query parameters.
        default_query <- list(currentPage = 1, pageSize = page_size, annType = "latest-announcements", lang = "en_US")
        query <- utils::modifyList(default_query, query)

        # Define a function to fetch a single page of announcements.
        fetch_page <- coro::async(function(q) {
            endpoint <- "/api/v3/announcements"
            qs <- build_query(q)
            url <- paste0(base_url, endpoint, qs)
            response <- httr::GET(url, httr::timeout(10))
            parsed_response <- process_kucoin_response(response, url)
            return(parsed_response$data)
        })
        
        # Use the auto_paginate helper to fetch and aggregate all pages.
        aggregated <- await(auto_paginate(
            fetch_page = fetch_page,
            query = query,
            items_field = "items",
            paginate_fields = list(currentPage = "currentPage", totalPage = "totalPage"),
            aggregate_fn = function(acc) {
                return(data.table::rbindlist(acc, fill = TRUE))
            },
            max_pages = max_pages
        ))
        
        return(aggregated)
    }, error = function(e) {
        rlang::abort(paste("Error in get_announcements_impl:", conditionMessage(e)))
    })
})

#' Get Currency Details (Implementation)
#'
#' Retrieves detailed information for a specified currency from the KuCoin API asynchronously, including chain-specific details for multi-chain currencies.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Builds a query string with the optional `chain` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v3/currencies/`, the `currency` code, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Conversion**: Splits `"data"` into summary fields and `chains` data, combining them into a `data.table`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/currencies/{currency}`
#'
#' ### Usage
#' Utilised to obtain metadata (e.g., precision, chain support) for a specific currency on KuCoin.
#'
#' ### Official Documentation
#' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param currency Character string; currency code (e.g., `"BTC"`, `"USDT"`).
#' @param chain Character string (optional); specific chain for multi-chain currencies (e.g., `"ERC20"`, `"TRC20"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `currency` (character): Unique currency code.
#'   - `name` (character): Short name of the currency.
#'   - `fullName` (character): Full name of the currency.
#'   - `precision` (integer): Decimal places for the currency.
#'   - `confirms` (integer or NULL): Block confirmations required.
#'   - `contractAddress` (character or NULL): Contract address for tokenized currencies.
#'   - `isMarginEnabled` (logical): Margin trading enabled status.
#'   - `isDebitEnabled` (logical): Debit enabled status.
#'   - Chain-specific fields (e.g., `chainName`, `withdrawalMinSize`) from the `chains` list.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Bitcoin details
#'   btc <- await(get_currency_impl(currency = "BTC"))
#'   print(btc)
#'   # USDT on ERC20 chain
#'   usdt_erc20 <- await(get_currency_impl(currency = "USDT", chain = "ERC20"))
#'   print(usdt_erc20)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
get_currency_impl <- coro::async(function(
    base_url = get_base_url(),
    currency,
    chain = NULL
) {
    tryCatch({
        endpoint <- "/api/v3/currencies/"

        # Build query string from the optional chain parameter
        qs <- build_query(list(chain = chain))

        # Construct the full URL by appending the currency code to the endpoint
        endpoint <- paste0(endpoint, currency)
        url <- paste0(base_url, endpoint, qs)

        # Send the GET request with a 10-second timeout
        response <- httr::GET(url, httr::timeout(10))

        # Process the response and extract the 'data' field
        parsed_response <- process_kucoin_response(response, url)

        # Convert the resulting data (a named list) into a data.table and return it
        summary_fields <- c(
            "currency", "name", "fullName", "precision", "confirms",
            "contractAddress", "isMarginEnabled", "isDebitEnabled"
        )

        summary_dt <- data.table::as.data.table(parsed_response$data[summary_fields])
        currency_dt <- data.table::as.data.table(parsed_response$data$chains)

        return(cbind(
            summary_dt,
            currency_dt
        ))
    }, error = function(e) {
        rlang::abort(paste("Error in get_currency_impl:", conditionMessage(e)))
    })
})

#' Get All Currencies (Implementation)
#'
#' Retrieves a list of all currencies available on KuCoin asynchronously, combining summary and chain-specific details into a `data.table`.
#'
#' ### Workflow Overview
#' 1. **URL Assembly**: Combines `base_url` with `/api/v3/currencies`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 4. **Data Iteration**: Loops through each currency, extracting summary fields and chain data (if present).
#' 5. **Result Assembly**: Combines summary and chain data into a `data.table`, adding dummy chain columns with `NA` if no chains exist.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/currencies`
#'
#' ### Usage
#' Utilised to fetch comprehensive currency details, including multi-chain support, for market analysis or configuration.
#'
#' ### Official Documentation
#' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - **Summary Fields**:
#'     - `currency` (character): Unique currency code.
#'     - `name` (character): Short name.
#'     - `fullName` (character): Full name.
#'     - `precision` (integer): Decimal places.
#'     - `confirms` (integer or NA): Block confirmations.
#'     - `contractAddress` (character or NA): Primary contract address.
#'     - `isMarginEnabled` (logical): Margin trading status.
#'     - `isDebitEnabled` (logical): Debit status.
#'   - **Chain-Specific Fields**:
#'     - `chainName` (character or NA): Blockchain name.
#'     - `withdrawalMinSize` (character or NA): Minimum withdrawal amount.
#'     - `depositMinSize` (character or NA): Minimum deposit amount.
#'     - `withdrawFeeRate` (character or NA): Withdrawal fee rate.
#'     - `withdrawalMinFee` (character or NA): Minimum withdrawal fee.
#'     - `isWithdrawEnabled` (logical or NA): Withdrawal enabled status.
#'     - `isDepositEnabled` (logical or NA): Deposit enabled status.
#'     - `confirms` (integer or NA): Chain-specific confirmations.
#'     - `preConfirms` (integer or NA): Pre-confirmations.
#'     - `chain_contractAddress` (character or NA): Chain-specific contract address.
#'     - `withdrawPrecision` (integer or NA): Withdrawal precision.
#'     - `maxWithdraw` (character or NA): Maximum withdrawal amount.
#'     - `maxDeposit` (character or NA): Maximum deposit amount.
#'     - `needTag` (logical or NA): Memo/tag requirement.
#'     - `chainId` (character or NA): Blockchain identifier.
#'     - `depositFeeRate` (character or NA): Deposit fee rate.
#'     - `withdrawMaxFee` (character or NA): Maximum withdrawal fee.
#'     - `depositTierFee` (character or NA): Tiered deposit fee.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   currencies <- await(get_all_currencies_impl())
#'   print(currencies)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table data.table rbindlist
#' @importFrom rlang abort
#' @export
get_all_currencies_impl <- coro::async(function(
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v3/currencies"
        url <- paste0(base_url, endpoint)

        # Send a GET request to the endpoint with a timeout of 10 seconds.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Iterate over each row (currency) in the returned data.frame.
        result_list <- lapply(seq_len(nrow(parsed_response$data)), function(i) {
            # Extract the i-th row as a one-row data.frame.
            curr <- parsed_response$data[i, , drop = FALSE]

            # Build a summary data.table from the currency row.
            summary_dt <- data.table::data.table(
                currency = curr$currency,
                name = curr$name,
                fullName = curr$fullName,
                precision = curr$precision,
                confirms = curr$confirms,
                contractAddress = curr$contractAddress,
                isMarginEnabled = curr$isMarginEnabled,
                isDebitEnabled = curr$isDebitEnabled
            )

            # Attempt to extract the chains data.
            chains_data <- curr$chains[[1]]

            # Check if chains_data is a data.frame with at least one row.
            if (is.data.frame(chains_data) && nrow(chains_data) > 0) {
                chains_dt <- data.table::as.data.table(chains_data, fill = TRUE)
                # Rename the chain-level 'contractAddress' to avoid conflicts.
                if ("contractAddress" %in% names(chains_dt)) {
                    data.table::setnames(chains_dt, "contractAddress", "chain_contractAddress")
                }
                # Replicate the summary row for each chain.
                summary_dt <- summary_dt[rep(1, nrow(chains_dt))]
                return(cbind(summary_dt, chains_dt))
            } else {
                # If no chains exist, create dummy chain columns (all NA).
                dummy_chain <- data.table::data.table(
                    chainName = NA_character_,
                    withdrawalMinSize = NA_character_,
                    depositMinSize = NA_character_,
                    withdrawFeeRate = NA_character_,
                    withdrawalMinFee = NA_character_,
                    isWithdrawEnabled = NA,
                    isDepositEnabled = NA,
                    confirms = NA_integer_,
                    preConfirms = NA_integer_,
                    chain_contractAddress = NA_character_,
                    withdrawPrecision = NA_integer_,
                    maxWithdraw = NA_character_,
                    maxDeposit = NA_character_,
                    needTag = NA,
                    chainId = NA_character_,
                    depositFeeRate = NA_character_,
                    withdrawMaxFee = NA_character_,
                    depositTierFee = NA_character_
                )
                return(cbind(summary_dt, dummy_chain))
            }
        })

        final_dt <- data.table::rbindlist(result_list, fill = TRUE)
        return(final_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_currencies_impl:", conditionMessage(e)))
    })
})

#' Get Symbol (Implementation)
#'
#' Retrieves detailed information about a specified trading symbol from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **URL Assembly**: Combines `base_url`, `/api/v2/symbols/`, and the `symbol`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 4. **Data Conversion**: Converts `"data"` into a `data.table` without filtering.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v2/symbols/{symbol}`
#'
#' ### Usage
#' Utilised to fetch metadata for a specific trading symbol, such as price increments and trading limits.
#'
#' ### Official Documentation
#' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Unique trading symbol code.
#'   - `name` (character): Name of the trading pair.
#'   - `baseCurrency` (character): Base currency.
#'   - `quoteCurrency` (character): Quote currency.
#'   - `feeCurrency` (character): Currency for fees.
#'   - `market` (character): Trading market (e.g., `"USDS"`).
#'   - `baseMinSize` (character): Minimum order quantity.
#'   - `quoteMinSize` (character): Minimum order funds.
#'   - `baseMaxSize` (character): Maximum order size.
#'   - `quoteMaxSize` (character): Maximum order funds.
#'   - `baseIncrement` (character): Quantity increment.
#'   - `quoteIncrement` (character): Quote increment.
#'   - `priceIncrement` (character): Price increment.
#'   - `priceLimitRate` (character): Price protection threshold.
#'   - `minFunds` (character): Minimum trading amount.
#'   - `isMarginEnabled` (logical): Margin trading status.
#'   - `enableTrading` (logical): Trading enabled status.
#'   - `feeCategory` (integer): Fee category.
#'   - `makerFeeCoefficient` (character): Maker fee coefficient.
#'   - `takerFeeCoefficient` (character): Taker fee coefficient.
#'   - `st` (logical): Special treatment flag.
#'   - `callauctionIsEnabled` (logical): Call auction enabled status.
#'   - `callauctionPriceFloor` (character): Call auction price floor.
#'   - `callauctionPriceCeiling` (character): Call auction price ceiling.
#'   - `callauctionFirstStageStartTime` (integer): First stage start time.
#'   - `callauctionSecondStageStartTime` (integer): Second stage start time.
#'   - `callauctionThirdStageStartTime` (integer): Third stage start time.
#'   - `tradingStartTime` (integer): Trading start time.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   symbol_data <- await(get_symbol_impl(symbol = "BTC-USDT"))
#'   print(symbol_data)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
get_symbol_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        endpoint <- "/api/v2/symbols/"
        url <- paste0(base_url, endpoint, symbol)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the entire 'data' field from the response into a data.table.
        symbol_dt <- data.table::as.data.table(parsed_response$data)

        return(symbol_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_symbol_impl:", conditionMessage(e)))
    })
})

#' Get All Symbols (Implementation)
#'
#' Retrieves a list of all available trading symbols from the KuCoin API asynchronously, optionally filtered by market.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Builds a query string with the optional `market` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v2/symbols`, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Conversion**: Converts `"data"` into a `data.table`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v2/symbols`
#'
#' ### Usage
#' Utilised to obtain a comprehensive list of trading symbols for market exploration or filtering.
#'
#' ### Official Documentation
#' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param market Character string (optional); trading market to filter symbols (e.g., `"ALTS"`, `"USDS"`, `"ETF"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Unique trading symbol code.
#'   - `name` (character): Name of the trading pair.
#'   - `baseCurrency` (character): Base currency.
#'   - `quoteCurrency` (character): Quote currency.
#'   - `feeCurrency` (character): Currency for fees.
#'   - `market` (character): Trading market.
#'   - `baseMinSize` (character): Minimum order quantity.
#'   - `quoteMinSize` (character): Minimum order funds.
#'   - `baseMaxSize` (character): Maximum order size.
#'   - `quoteMaxSize` (character): Maximum order funds.
#'   - `baseIncrement` (character): Quantity increment.
#'   - `quoteIncrement` (character): Quote increment.
#'   - `priceIncrement` (character): Price increment.
#'   - `priceLimitRate` (character): Price protection threshold.
#'   - `minFunds` (character): Minimum trading amount.
#'   - `isMarginEnabled` (logical): Margin trading status.
#'   - `enableTrading` (logical): Trading enabled status.
#'   - `feeCategory` (integer): Fee category.
#'   - `makerFeeCoefficient` (character): Maker fee coefficient.
#'   - `takerFeeCoefficient` (character): Taker fee coefficient.
#'   - `st` (logical): Special treatment flag.
#'   - `callauctionIsEnabled` (logical): Call auction enabled status.
#'   - `callauctionPriceFloor` (character): Call auction price floor.
#'   - `callauctionPriceCeiling` (character): Call auction price ceiling.
#'   - `callauctionFirstStageStartTime` (integer): First stage start time.
#'   - `callauctionSecondStageStartTime` (integer): Second stage start time.
#'   - `callauctionThirdStageStartTime` (integer): Third stage start time.
#'   - `tradingStartTime` (integer): Trading start time.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   all_symbols <- await(get_all_symbols_impl())
#'   print(all_symbols)
#'   alts_symbols <- await(get_all_symbols_impl(market = "ALTS"))
#'   print(alts_symbols)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
get_all_symbols_impl <- coro::async(function(
    base_url = get_base_url(),
    market = NULL
) {
    tryCatch({
        # Build query string from the optional market parameter.
        qs <- build_query(list(market = market))
        endpoint <- "/api/v2/symbols"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the entire 'data' field (an array of symbol objects) into a data.table.
        symbols_dt <- data.table::as.data.table(parsed_response$data)

        return(symbols_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_symbols_impl:", conditionMessage(e)))
    })
})

#' Get Ticker (Implementation)
#'
#' Retrieves Level 1 market data (ticker information) for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level1`, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Conversion**: Converts `"data"` to a `data.table`, adds `symbol`, renames `time` to `time_ms`, and adds a `timestamp` column via `time_convert_from_kucoin()`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/orderbook/level1`
#'
#' ### Usage
#' Utilised to obtain real-time ticker data (e.g., best bid/ask, last price) for a trading symbol.
#'
#' ### Official Documentation
#' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Trading symbol.
#'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
#'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
#'   - `sequence` (character): Update sequence identifier.
#'   - `price` (character): Last traded price.
#'   - `size` (character): Last traded size.
#'   - `bestBid` (character): Best bid price.
#'   - `bestBidSize` (character): Best bid size.
#'   - `bestAsk` (character): Best ask price.
#'   - `bestAskSize` (character): Best ask size.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   ticker <- await(get_ticker_impl(symbol = "BTC-USDT"))
#'   print(ticker)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table setnames setcolorder
#' @importFrom rlang abort
#' @export
get_ticker_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/orderbook/level1"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the 'data' field (a named list) to a data.table.
        ticker_dt <- data.table::as.data.table(parsed_response$data)
        ticker_dt[, symbol := symbol]

        # convert kucoin time to POSIXct
        ticker_dt[, timestamp := time_convert_from_kucoin(time, "ms")]
        # rename the time col to time_ms
        data.table::setnames(ticker_dt, "time", "time_ms")

        move_cols <- c("symbol", "timestamp", "time_ms")
        data.table::setcolorder(ticker_dt, c(move_cols, setdiff(names(ticker_dt), move_cols)))
        return(ticker_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_ticker_impl:", conditionMessage(e)))
    })
})

#' Get All Tickers (Implementation)
#'
#' Retrieves market tickers for all trading pairs from the KuCoin API asynchronously, including 24-hour volume data.
#'
#' ### Workflow Overview
#' 1. **URL Assembly**: Combines `base_url` with `/api/v1/market/allTickers`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 4. **Data Conversion**: Converts the `"ticker"` array to a `data.table`, adding `globalTime_ms` and `globalTime_datetime` from the `"time"` field.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/allTickers`
#'
#' ### Usage
#' Utilised to fetch a snapshot of market data across all KuCoin trading pairs for monitoring or analysis.
#'
#' ### Official Documentation
#' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Trading symbol.
#'   - `symbolName` (character): Symbol name.
#'   - `buy` (character): Best bid price.
#'   - `bestBidSize` (character): Best bid size.
#'   - `sell` (character): Best ask price.
#'   - `bestAskSize` (character): Best ask size.
#'   - `changeRate` (character): 24-hour change rate.
#'   - `changePrice` (character): 24-hour price change.
#'   - `high` (character): 24-hour high price.
#'   - `low` (character): 24-hour low price.
#'   - `vol` (character): 24-hour trading volume.
#'   - `volValue` (character): 24-hour turnover.
#'   - `last` (character): Last traded price.
#'   - `averagePrice` (character): 24-hour average price.
#'   - `takerFeeRate` (character): Taker fee rate.
#'   - `makerFeeRate` (character): Maker fee rate.
#'   - `takerCoefficient` (character): Taker fee coefficient.
#'   - `makerCoefficient` (character): Maker fee coefficient.
#'   - `globalTime_ms` (integer): Snapshot timestamp in milliseconds.
#'   - `globalTime_datetime` (POSIXct): Snapshot timestamp in UTC.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   tickers <- await(get_all_tickers_impl())
#'   print(tickers)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
get_all_tickers_impl <- coro::async(function(
    base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v1/market/allTickers"
        url <- paste0(base_url, endpoint)

        # Send a GET request to the endpoint with a timeout of 10 seconds.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Extract the global snapshot time and the ticker array.
        global_time <- parsed_response$data$time
        ticker_list <- parsed_response$data$ticker

        # Convert the ticker array into a data.table.
        ticker_dt <- data.table::as.data.table(ticker_list)

        # Add the snapshot time information.
        ticker_dt[, globalTime_ms := global_time]
        ticker_dt[, globalTime_datetime := time_convert_from_kucoin(global_time, "ms")]

        return(ticker_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_tickers_impl:", conditionMessage(e)))
    })
})

#' Get Trade History (Implementation)
#'
#' Retrieves the most recent 100 trade records for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/histories`, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Conversion**: Converts `"data"` to a `data.table`, adding a `timestamp` column via `time_convert_from_kucoin()`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/histories`
#'
#' ### Usage
#' Utilised to fetch recent trade history for a trading symbol, useful for tracking market activity.
#'
#' ### Official Documentation
#' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `sequence` (character): Trade sequence number.
#'   - `price` (character): Filled price.
#'   - `size` (character): Filled amount.
#'   - `side` (character): Trade side (`"buy"` or `"sell"`).
#'   - `time` (integer): Trade timestamp in nanoseconds.
#'   - `timestamp` (POSIXct): Converted trade timestamp in UTC.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   trades <- await(get_trade_history_impl(symbol = "BTC-USDT"))
#'   print(trades)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table
#' @importFrom rlang abort
#' @export
get_trade_history_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/histories"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)

        # Convert the 'data' field (an array of trade history objects) into a data.table.
        trade_history_dt <- data.table::as.data.table(parsed_response$data)

        # Convert the trade timestamp from nanoseconds to a POSIXct datetime.
        trade_history_dt[, timestamp := time_convert_from_kucoin(time, "ns")]

        return(trade_history_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_trade_history_impl:", conditionMessage(e)))
    })
})

#' Get Part OrderBook (Implementation)
#'
#' Retrieves partial orderbook depth data (20 or 100 levels) for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **Input Validation**: Ensures `size` is 20 or 100, aborting if invalid.
#' 2. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level2_{size}`, and the query string.
#' 4. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 5. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 6. **Data Conversion**: Converts bids and asks into separate `data.table`s, adds `side`, combines them, and appends snapshot fields.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/orderbook/level2_{size}`
#'
#' ### Usage
#' Utilised to obtain a snapshot of the orderbook for a trading symbol, showing aggregated bid and ask levels.
#'
#' ### Official Documentation
#' [KuCoin Get Part OrderBook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @param size Integer; orderbook depth (20 or 100).
#' @return Promise resolving to a `data.table` containing:
#'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
#'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
#'   - `sequence` (character): Orderbook update sequence.
#'   - `side` (character): Order side (`"bid"` or `"ask"`).
#'   - `price` (character): Aggregated price level.
#'   - `size` (character): Aggregated size at that price.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   orderbook_20 <- await(get_part_orderbook_impl(symbol = "BTC-USDT", size = 20))
#'   print(orderbook_20)
#'   orderbook_100 <- await(get_part_orderbook_impl(symbol = "BTC-USDT", size = 100))
#'   print(orderbook_100)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table data.table rbindlist setcolorder setorder
#' @importFrom rlang abort
#' @export
get_part_orderbook_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol,
    size
) {
    tryCatch({
        # Validate the size parameter.
        requested_size <- as.integer(size)
        if (!(requested_size %in% c(20, 100))) {
            rlang::abort("Invalid size. Allowed values are 20 and 100.")
        }

        # Construct query string and full URL.
        qs <- build_query(list(symbol = symbol))
        endpoint <- paste0("/api/v1/market/orderbook/level2_", requested_size)
        url <- paste0(base_url, endpoint, qs)

        # Send the GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        data_obj <- parsed_response$data

        # Extract global snapshot fields.
        global_time <- data_obj$time   # in milliseconds
        sequence <- data_obj$sequence

        # Create a data.table for bids.
        bids_dt <- data.table::data.table(
            price = data_obj$bids[, 1],
            size  = data_obj$bids[, 2],
            side  = "bid"
        )

        # Create a data.table for asks.
        asks_dt <- data.table::data.table(
            price = data_obj$asks[, 1],
            size  = data_obj$asks[, 2],
            side  = "ask"
        )

        # Combine the bids and asks into a single data.table.
        orderbook_dt <- data.table::rbindlist(list(bids_dt, asks_dt))

        # Append global snapshot fields.
        orderbook_dt[, time_ms := global_time]
        orderbook_dt[, sequence := sequence]
        orderbook_dt[, timestamp := time_convert_from_kucoin(global_time, "ms")]

        # Reorder columns to move global fields to the front.
        data.table::setcolorder(orderbook_dt, c("timestamp", "time_ms", "sequence", "side", "price", "size"))
        data.table::setorder(orderbook_dt, price, size)

        return(orderbook_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_part_orderbook_impl:", conditionMessage(e)))
    })
})

#' Get Full OrderBook (Implementation, Authenticated)
#'
#' Retrieves the full orderbook depth data for a specified trading symbol from the KuCoin API asynchronously, requiring authentication.
#'
#' ### Workflow Overview
#' 1. **Header Preparation**: Constructs authentication headers with `build_headers()` using `keys`.
#' 2. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url`, `/api/v3/market/orderbook/level2`, and the query string.
#' 4. **HTTP Request**: Sends a GET request with headers and a 10-second timeout via `httr::GET()`.
#' 5. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 6. **Data Conversion**: Converts bids and asks into `data.table`s, adds `side`, combines them, and appends snapshot fields.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v3/market/orderbook/level2`
#'
#' ### Usage
#' Utilised to fetch the complete orderbook for a trading symbol, requiring API authentication for detailed depth data.
#'
#' ### Official Documentation
#' [KuCoin Get Full OrderBook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-full-orderbook)
#'
#' @param keys List; API configuration parameters from `get_api_keys()`, including:
#'   - `api_key` (character): KuCoin API key.
#'   - `api_secret` (character): KuCoin API secret.
#'   - `api_passphrase` (character): KuCoin API passphrase.
#'   - `key_version` (character): API key version (e.g., `"2"`).
#'   Defaults to `get_api_keys()`.
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
#'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
#'   - `sequence` (character): Orderbook update sequence.
#'   - `side` (character): Order side (`"bid"` or `"ask"`).
#'   - `price` (character): Aggregated price level.
#'   - `size` (character): Aggregated size at that price.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   keys <- get_api_keys()
#'   orderbook <- await(get_full_orderbook_impl(keys = keys, symbol = "BTC-USDT"))
#'   print(orderbook)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table data.table rbindlist setcolorder setorder
#' @importFrom rlang abort
#' @export
get_full_orderbook_impl <- coro::async(function(
    keys = get_api_keys(),
    base_url = get_base_url(),
    symbol
) {
    tryCatch({
        # Construct the query string with the required symbol.
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v3/market/orderbook/level2"
        full_endpoint <- paste0(endpoint, qs)

        # Prepare authentication headers.
        method <- "GET"
        body <- ""
        headers <- await(build_headers(method, full_endpoint, body, keys))

        # Construct the full URL.
        url <- paste0(base_url, full_endpoint)

        # Send the GET request with a 10-second timeout.
        response <- httr::GET(url, headers, httr::timeout(10))

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        data_obj <- parsed_response$data

        # Extract global snapshot fields.
        global_time <- data_obj$time   # in milliseconds
        sequence <- data_obj$sequence

        # Create data.tables for bids and asks from their matrices.
        bids_dt <- data.table::data.table(
            price = data_obj$bids[, 1],
            size  = data_obj$bids[, 2],
            side  = "bid"
        )
        asks_dt <- data.table::data.table(
            price = data_obj$asks[, 1],
            size  = data_obj$asks[, 2],
            side  = "ask"
        )

        # Combine bids and asks into a single data.table.
        orderbook_dt <- data.table::rbindlist(list(bids_dt, asks_dt))

        # Append global snapshot fields.
        orderbook_dt[, time_ms := global_time]
        orderbook_dt[, sequence := sequence]
        orderbook_dt[, timestamp := time_convert_from_kucoin(global_time, "ms")]

        # Reorder columns so that global fields appear first.
        data.table::setcolorder(orderbook_dt, c("timestamp", "time_ms", "sequence", "side", "price", "size"))
        data.table::setorder(orderbook_dt, price, size)

        return(orderbook_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_full_orderbook_impl:", conditionMessage(e)))
    })
})

#' Get 24-Hour Statistics (Implementation)
#'
#' Retrieves 24-hour market statistics for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v1/market/stats`, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 5. **Data Conversion**: Converts `"data"` to a `data.table`, renames `time` to `time_ms`, and adds a `timestamp` column via `time_convert_from_kucoin()`.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/stats`
#'
#' ### Usage
#' Utilised to fetch a 24-hour snapshot of market statistics for a trading symbol, including volume and price changes.
#'
#' ### Official Documentation
#' [KuCoin Get 24hr Stats](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `timestamp` (POSIXct): Snapshot timestamp in UTC.
#'   - `time_ms` (integer): Snapshot timestamp in milliseconds.
#'   - `symbol` (character): Trading symbol.
#'   - `buy` (character): Best bid price.
#'   - `sell` (character): Best ask price.
#'   - `changeRate` (character): 24-hour change rate.
#'   - `changePrice` (character): 24-hour price change.
#'   - `high` (character): 24-hour high price.
#'   - `low` (character): 24-hour low price.
#'   - `vol` (character): 24-hour trading volume.
#'   - `volValue` (character): 24-hour turnover.
#'   - `last` (character): Last traded price.
#'   - `averagePrice` (character): 24-hour average price.
#'   - `takerFeeRate` (character): Taker fee rate.
#'   - `makerFeeRate` (character): Maker fee rate.
#'   - `takerCoefficient` (character): Taker fee coefficient.
#'   - `makerCoefficient` (character): Maker fee coefficient.
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   stats <- await(get_24hr_stats_impl(symbol = "BTC-USDT"))
#'   print(stats)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table setnames setcolorder
#' @importFrom rlang abort
#' @export
get_24hr_stats_impl <- coro::async(function(
  base_url = get_base_url(),
  symbol
) {
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/stats"
        url <- paste0(base_url, endpoint, qs)

        response <- httr::GET(url, httr::timeout(10))
        parsed_response <- process_kucoin_response(response, url)
        data_obj <- parsed_response$data

        stats_dt <- data.table::as.data.table(data_obj)
        stats_dt[, timestamp := time_convert_from_kucoin(time, "ms")]

        data.table::setnames(stats_dt, "time", "time_ms")
        data.table::setcolorder(stats_dt, c("timestamp", "time_ms", setdiff(names(stats_dt), c("timestamp", "time_ms"))))

        return(stats_dt)
    }, error = function(e) {
        rlang::abort(paste("Error in get_24hr_stats_impl:", conditionMessage(e)))
    })
})

#' Get Market List (Implementation)
#'
#' Retrieves the list of all available trading markets from the KuCoin API asynchronously.
#'
#' ### Workflow Overview
#' 1. **URL Assembly**: Combines `base_url` with `/api/v1/markets`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field as a character vector.
#'
#' ### API Endpoint
#' `GET https://api.kucoin.com/api/v1/markets`
#'
#' ### Usage
#' Utilised to identify available trading markets on KuCoin for filtering or querying market-specific data.
#'
#' ### Official Documentation
#' [KuCoin Get Market List](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-market-list)
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a character vector of trading market identifiers (e.g., `"USDS"`, `"TON"`).
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   markets <- await(get_market_list_impl())
#'   print(markets)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom rlang abort
#' @export
get_market_list_impl <- coro::async(function(
  base_url = get_base_url()
) {
    tryCatch({
        endpoint <- "/api/v1/markets"
        url <- paste0(base_url, endpoint)
        
        # Send the GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))
        
        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        
        return(parsed_response$data)
    }, error = function(e) {
        rlang::abort(paste("Error in get_market_list_impl:", conditionMessage(e)))
    })
})

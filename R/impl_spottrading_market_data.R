# File: ./R/impl_spottrading_market_data.R

box::use(
    ./helpers_api[ auto_paginate, build_headers, process_kucoin_response ],
    ./utils[ verify_symbol, build_query, get_api_keys, get_base_url ],
    ./utils_time_convert_kucoin[ time_convert_from_kucoin, time_convert_to_kucoin ],
    coro[async, await],
    data.table[as.data.table, data.table, rbindlist, setcolorder, setnames],
    httr[GET, timeout],
    rlang[abort],
    utils[modifyList]
)

#' Get Announcements
#'
#' Retrieves the latest announcements from the KuCoin API asynchronously by sending a GET request to the `/api/v3/announcements` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## API Details
#'
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 20
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getAnnouncements`
#'
#' ## Description
#' This function retrieves the latest news announcements from KuCoin, with the default search being for announcements within a month. It automatically handles pagination to aggregate all results into a single data structure, converting millisecond timestamps to human-readable datetime objects.
#'
#' ## Workflow Overview
#' 1. **Query Construction**: Merges default parameters (`currentPage = 1`, `pageSize = 50`, `annType = "latest-announcements"`, `lang = "en_US"`) with user-supplied `query` parameters.
#' 2. **Time Conversion**: Converts POSIXct datetime objects for `startAt` and `endAt` to millisecond timestamps required by the KuCoin API.
#' 3. **URL Assembly**: Combines the base URL with the endpoint `/api/v3/announcements` and appends the query string.
#' 4. **API Request**: Sends a GET request using `httr::GET()` with the constructed URL, applying a 10-second timeout.
#' 5. **Pagination Handling**: Uses `auto_paginate()` to retrieve multiple pages of results until all pages are fetched or `max_pages` is reached.
#' 6. **Data Processing**: Aggregates all pages into a single `data.table`, converting array fields like `annType` to semicolon-delimited strings.
#' 7. **Datetime Conversion**: Adds a human-readable `cTime_datetime` column by converting the UNIX timestamp.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v3/announcements`
#'
#' ## Usage
#' This function is used internally to gather KuCoin news announcements (e.g., updates, promotions, new listings, maintenance notices) for market analysis, notifications, or display purposes.
#'
#' ## Official Documentation
#' [KuCoin Get Announcements](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-announcements)
#'
#' ## Function Validated
#' - Last validated: 2025-02-25 21h32
#'
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param query Named list; additional query parameters to filter announcements. Supported parameters:
#'   - `currentPage` (integer, optional): Page number to retrieve. Default is 1.
#'   - `pageSize` (integer, optional): Number of announcements per page. Default is 50.
#'   - `annType` (string, optional): Type of announcements. Default is `"latest-announcements"`. 
#'     Allowed values: `"latest-announcements"`, `"activities"`, `"new-listings"`, `"product-updates"`, 
#'     `"vip"`, `"maintenance-updates"`, `"delistings"`, `"others"`, `"api-campaigns"`.
#'   - `lang` (string, optional): Language code. Default is `"en_US"`. 
#'     Allowed values: `"en_US"`, `"zh_HK"`, `"ja_JP"`, `"ko_KR"`, `"pl_PL"`, `"es_ES"`, `"fr_FR"`, 
#'     `"ar_AE"`, `"it_IT"`, `"id_ID"`, `"nl_NL"`, `"pt_PT"`, `"vi_VN"`, `"de_DE"`, `"tr_TR"`, 
#'     `"ms_MY"`, `"ru_RU"`, `"th_TH"`, `"hi_IN"`, `"bn_BD"`, `"fil_PH"`, `"ur_PK"`.
#' @param page_size Integer; number of results per page. Default is 50.
#' @param max_pages Numeric; maximum number of pages to fetch. Default is `Inf` (all available pages).
#' @param startAt POSIXct/POSIXlt datetime object (optional); the start time for filtering announcements by publication time.
#' @param endAt POSIXct/POSIXlt datetime object (optional); the end time for filtering announcements by publication time.
#'
#' @return A promise resolving to a `data.table` containing announcement information with the following columns:
#'   - `annId` (numeric): Unique announcement ID.
#'   - `annTitle` (character): Announcement title.
#'   - `annType` (character): Semicolon-delimited list of announcement types (e.g., `"latest-announcements;new-listings"`).
#'   - `annDesc` (character): Announcement description or summary.
#'   - `cTime` (numeric): Release timestamp in milliseconds since epoch.
#'   - `cTime_datetime` (POSIXct): Human-readable datetime converted from `cTime`.
#'   - `language` (character): Language code of the announcement (e.g., `"en_US"`, `"zh_HK"`).
#'   - `annUrl` (character): URL to the full announcement on KuCoin's website.
#'   - `page_currentPage` (numeric): Current page number in the pagination.
#'   - `page_pageSize` (numeric): Number of results per page.
#'   - `page_totalNum` (numeric): Total number of announcements matching the criteria.
#'   - `page_totalPage` (numeric): Total number of pages available.
#'
#'   If no announcements are found for the specified criteria, an empty `data.table` with these columns is returned.
#'
#' ## Details
#'
#' ### Query Parameters
#' - `currentPage` (integer, optional): Page number to retrieve. Default is 1.
#' - `pageSize` (integer, optional): Number of announcements per page. Default is 50.
#' - `annType` (string, optional): Type of announcements. Default is `"latest-announcements"`. Multiple types can be specified.
#'   - `"latest-announcements"`: All latest announcements
#'   - `"activities"`: Latest activities
#'   - `"new-listings"`: New currency listings
#'   - `"product-updates"`: Product updates
#'   - `"vip"`: Institutions and VIPs
#'   - `"maintenance-updates"`: System maintenance
#'   - `"delistings"`: Currency delistings
#'   - `"others"`: Other announcements
#'   - `"api-campaigns"`: API user activities
#' - `lang` (string, optional): Language code. Default is `"en_US"`.
#' - `startTime` (integer, optional): Start time in milliseconds since epoch.
#' - `endTime` (integer, optional): End time in milliseconds since epoch.
#'
#' **Example Request URL**:
#' ```http
#' GET https://api.kucoin.com/api/v3/announcements?currentPage=1&pageSize=50&annType=latest-announcements&lang=en_US&startTime=1729594043000&endTime=1729697729000
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains:
#'   - `totalNum` (integer): Total number of announcements matching the criteria.
#'   - `totalPage` (integer): Total number of pages available.
#'   - `currentPage` (integer): Current page number.
#'   - `pageSize` (integer): Number of results per page.
#'   - `items` (array of objects): Each object contains:
#'     - `annId` (integer): Unique announcement ID.
#'     - `annTitle` (string): Announcement title.
#'     - `annType` (array of strings): Array of announcement types.
#'     - `annDesc` (string): Announcement description.
#'     - `cTime` (integer): Release timestamp in milliseconds.
#'     - `language` (string): Language code of the announcement.
#'     - `annUrl` (string): URL to the full announcement.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "totalNum": 195,
#'     "totalPage": 13,
#'     "currentPage": 1,
#'     "pageSize": 15,
#'     "items": [
#'       {
#'         "annId": 129045,
#'         "annTitle": "KuCoin Isolated Margin Adds the Scroll (SCR) Trading Pair",
#'         "annType": [
#'           "latest-announcements"
#'         ],
#'         "annDesc": "To enrich the variety of assets available, KuCoin's Isolated Margin Trading platform has added the Scroll (SCR) asset and trading pair.",
#'         "cTime": 1729594043000,
#'         "language": "en_US",
#'         "annUrl": "https://www.kucoin.com/announcement/kucoin-isolated-margin-adds-scr?lang=en_US"
#'       },
#'       {
#'         "annId": 129001,
#'         "annTitle": "DAPP-30D Fixed Promotion, Enjoy an APR of 200%!",
#'         "annType": [
#'           "latest-announcements",
#'           "activities"
#'         ],
#'         "annDesc": "KuCoin Earn will be launching the DAPP Fixed Promotion at 10:00:00 on October 22, 2024 (UTC). The available product is "DAPP-30D'' with an APR of 200%.",
#'         "cTime": 1729588460000,
#'         "language": "en_US",
#'         "annUrl": "https://www.kucoin.com/announcement/dapp-30d-fixed-promotion-enjoy?lang=en_US"
#'       }
#'     ]
#'   }
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the `"items"` array from the `"data"` object.
#' - Converting the `annType` array to a semicolon-delimited string for tabular representation.
#' - Adding a `cTime_datetime` column by converting the UNIX timestamp to a human-readable datetime.
#' - Ensuring proper column types for all fields.
#'
#' ## Notes
#' - **Default Search Period**: By default, the API returns announcements from within the last month.
#' - **Language Support**: The function supports multiple languages through the `lang` parameter, with `"en_US"` as the default.
#' - **Announcement Types**: An announcement can belong to multiple types (e.g., both `"latest-announcements"` and `"new-listings"`).
#' - **Pagination**: Results are paginated with a default of 50 results per page. The function automatically handles pagination by default.
#' - **Array Conversion**: The `annType` array in the API response is converted to a semicolon-delimited string for easier tabular representation.
#' - **Rate Limiting**: This endpoint has a weight of 20 in the API rate limit pool (Public). Plan request frequency accordingly.
#' - **Time Parameters**: The function accepts standard R datetime objects (`POSIXct`/`POSIXlt`) for time ranges and converts them to the millisecond format required by the API.
#'
#' ## Use Cases
#' - **Market News Monitoring**: Keeping track of new listings, delistings, and other market-affecting announcements.
#' - **Maintenance Awareness**: Monitoring system maintenance updates to plan trading activities accordingly.
#' - **Promotional Tracking**: Following promotional activities and campaigns.
#' - **Multi-language Support**: Retrieving announcements in different languages for global user bases.
#' - **Historical Analysis**: Analyzing announcement patterns over time by using `startAt` and `endAt` parameters.
#'
#' ## Advice for Automated Trading Systems
#' - **Regular Polling**: Implement periodic polling to stay updated on new announcements, particularly for maintenance notices that might affect trading.
#' - **Event-Driven Logic**: Use new listing/delisting announcements to trigger trading strategy adjustments.
#' - **Language Targeting**: Specify appropriate language codes when targeting specific regions or user groups.
#' - **Efficient Date Filtering**: Use `startAt` and `endAt` to retrieve only new announcements since the last check.
#' - **Rate Limit Awareness**: With a weight of 20 per request, monitor and throttle usage in high-frequency systems to stay within KuCoin's limits.
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve latest announcements in English (default behavior)
#' main_async <- coro::async(function() {
#'   announcements <- await(get_announcements_impl())
#'   print(announcements)
#'   
#'   # Example: Filtered by type (new coin listings) and language (Japanese)
#'   new_listings_jp <- await(get_announcements_impl(
#'     query = list(
#'       annType = "new-listings", 
#'       lang = "ja_JP"
#'     )
#'   ))
#'   print(new_listings_jp)
#'   
#'   # Example: Retrieve announcements within a specific time range using POSIXct objects
#'   one_week_ago <- lubridate::now() - lubridate::days(7)
#'   current_time <- lubridate::now()
#'   recent_announcements <- await(get_announcements_impl(
#'     startAt = one_week_ago,
#'     endAt = current_time
#'   ))
#'   print(recent_announcements)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table rbindlist
#' @importFrom utils modifyList
#' @importFrom rlang abort
#' @export
get_announcements_impl <- coro::async(function(
    base_url = get_base_url(),
    query = list(),
    startAt = lubridate::now() - lubridate::hours(48),
    endAt = lubridate::now(),
    page_size = 50,
    max_pages = Inf
) {
    tryCatch({
        # Merge default pagination parameters with user-supplied query parameters.
        default_query <- list(currentPage = 1, pageSize = page_size, annType = "latest-announcements", lang = "en_US")
        query <- utils::modifyList(default_query, query)

        # Process datetime inputs if provided
        if (!inherits(startAt, c("POSIXct", "POSIXlt", "Date"))) {
            rlang::abort("startAt must be a POSIXct/POSIXlt datetime object")
        }
        start_ms <- time_convert_to_kucoin(startAt, "ms")
        query$startTime <- as.character(round(start_ms))

        if (!inherits(endAt, c("POSIXct", "POSIXlt", "Date"))) {
            rlang::abort("endAt must be a POSIXct/POSIXlt datetime object")
        }
        end_ms <- time_convert_to_kucoin(endAt, "ms")
        query$endTime <- as.character(round(end_ms))

        # Define a function to fetch a single page of announcements.
        fetch_page <- coro::async(function(q) {
            endpoint <- "/api/v3/announcements"
            qs <- build_query(q)
            url <- paste0(base_url, endpoint, qs)
            response <- httr::GET(url, httr::timeout(10))
            # file_name <- paste0("get_announcements_impl_", q$currentPage)
            # saveRDS(response, paste0("../../api-responses/impl_spottrading_market_data/response-", file_name, ".ignore.Rds"))
            parsed_response <- process_kucoin_response(response, url)
            # saveRDS(parsed_response, paste0("../../api-responses/impl_spottrading_market_data/parsed_response-", file_name, ".Rds"))
            return(parsed_response$data)
        })

        result <- await(auto_paginate(
            fetch_page = fetch_page,
            query = query,
            items_field = "items",
            paginate_fields = list(currentPage = "currentPage", totalPage = "totalPage"),
            aggregate_fn = function(acc) {
                # Handle empty results case
                if (length(acc) == 0 || all(sapply(acc, length) == 0)) {
                    return(data.table::data.table(
                        annId = numeric(0),
                        annTitle = character(0),
                        annType = character(0),
                        annDesc = character(0),
                        cTime = numeric(0),
                        cTime_datetime = lubridate::as_datetime(character(0)),
                        language = character(0),
                        annUrl = character(0),
                        # Pagination fields
                        page_currentPage = numeric(0),
                        page_pageSize = numeric(0),
                        page_totalNum = numeric(0),
                        page_totalPage = numeric(0)
                    ))
                }

                # Convert annType arrays to semicolon-delimited strings
                acc2 <- lapply(acc, function(el) {
                    el$annType <- paste(el$annType, collapse = ";")
                    return(el)
                })
                return(data.table::rbindlist(acc2))
            },
            max_pages = max_pages
        ))

        agg <- result$aggregate

        # Ensure proper column types and add datetime conversion
        agg[, `:=`(
            annId = as.numeric(annId),
            annTitle = as.character(annTitle),
            annType = as.character(annType),
            annDesc = as.character(annDesc),
            cTime = as.numeric(cTime),
            cTime_datetime = time_convert_from_kucoin(cTime, "ms"),
            language = as.character(language),
            annUrl = as.character(annUrl),
            # Pagination fields
            page_currentPage = as.numeric(result$pagination$currentPage),
            page_pageSize = as.numeric(result$pagination$pageSize),
            page_totalNum = as.numeric(result$pagination$totalNum),
            page_totalPage = as.numeric(result$pagination$totalPage)
        )]

        return(agg[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_announcements_impl:", conditionMessage(e)))
    })
})

#' Get Currency Details
#'
#' Retrieves detailed information for a specified currency from the KuCoin API asynchronously by sending a GET request to the `/api/v3/currencies/{currency}` endpoint. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption.
#'
#' ## API Details
#'
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getCurrency`
#'
#' ## Description
#' This function retrieves comprehensive details about a specified cryptocurrency, including its precision, confirmation requirements, chain support, and transaction limits. For multi-chain currencies, it can provide chain-specific details when the optional `chain` parameter is specified.
#'
#' ## Workflow Overview
#' 1. **Query Construction**: Builds a query string with the optional `chain` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines the base URL with `/api/v3/currencies/`, the `currency` code, and the query string.
#' 3. **API Request**: Sends a GET request using `httr::GET()` with the constructed URL, applying a 10-second timeout.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Transformation**: Splits the response into currency summary fields and chain-specific details, processing and combining them into a structured `data.table`.
#' 6. **Type Conversion**: Ensures proper data types for all fields (e.g., numeric for balances, logical for boolean flags).
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v3/currencies/{currency}`
#'
#' ## Usage
#' This function is used internally to obtain detailed metadata (e.g., precision, chain support, minimum withdrawal amounts) for a specific currency on KuCoin, which is essential for operations like deposits, withdrawals, and trading.
#'
#' ## Official Documentation
#' [KuCoin Get Currency](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-currency)
#'
#' ## Function Validated
#' - Last validated: 2025-02-26 11h31
#'
#' @param base_url Character string representing the base URL for the API. Defaults to `get_base_url()`.
#' @param currency Character string; the currency code for which to retrieve details (e.g., `"BTC"`, `"ETH"`, `"USDT"`).
#' @param chain Character string (optional); specific blockchain network for multi-chain currencies. Examples:
#'   - For USDT: `"eth"` (ERC20), `"trx"` (TRC20), `"bsc"` (BEP20), etc.
#'   - For BTC: `"btc"` (Native), `"bech32"` (Segwit), etc.
#'   - This parameter can be omitted for single-chain currencies.
#'
#' @return A promise resolving to a `data.table` containing currency details with the following columns:
#'   - **General Currency Fields**:
#'     - `currency` (character): Unique currency code.
#'     - `name` (character): Short name of the currency.
#'     - `fullName` (character): Full name of the currency.
#'     - `precision` (numeric): Decimal places supported for the currency.
#'     - `isMarginEnabled` (logical): Whether margin trading is enabled for this currency.
#'     - `isDebitEnabled` (logical): Whether debit is enabled for this currency.
#'   - **Chain-Specific Fields** (one row per chain):
#'     - `chainName` (character): Name of the blockchain network (e.g., `"BTC"`, `"ERC20"`, `"TRC20"`).
#'     - `withdrawalMinSize` (numeric): Minimum amount that can be withdrawn.
#'     - `depositMinSize` (numeric): Minimum amount that can be deposited.
#'     - `withdrawFeeRate` (numeric): Fee rate for withdrawals.
#'     - `withdrawalMinFee` (numeric): Minimum fee charged for withdrawals.
#'     - `isWithdrawEnabled` (logical): Whether withdrawals are currently enabled.
#'     - `isDepositEnabled` (logical): Whether deposits are currently enabled.
#'     - `confirms` (numeric): Number of block confirmations required.
#'     - `preConfirms` (numeric): Number of confirmations required for advance verification.
#'     - `contractAddress` (character): Contract address for token currencies.
#'     - `withdrawPrecision` (numeric): Decimal precision for withdrawal amounts.
#'     - `maxWithdraw` (numeric): Maximum amount for a single withdrawal.
#'     - `maxDeposit` (numeric): Maximum amount for a single deposit.
#'     - `needTag` (logical): Whether a memo/tag is required for deposits.
#'     - `chainId` (character): Chain identifier used in API requests.
#'
#'   If the specified currency does not exist or no chain data is available, an empty `data.table` with these columns is returned.
#'
#' ## Details
#'
#' ### Path Parameters
#' - `currency` (string, **required**): The currency code for which to retrieve details (e.g., `"BTC"`, `"ETH"`, `"USDT"`).
#'
#' ### Query Parameters
#' - `chain` (string, optional): The blockchain network for multi-chain currencies. Examples:
#'   - For USDT: `"eth"` (ERC20), `"trx"` (TRC20), `"bsc"` (BEP20), etc.
#'   - For BTC: `"btc"` (Native), `"bech32"` (Segwit), etc.
#'   - This parameter can be omitted for single-chain currencies.
#'
#' **Example Request URL**:
#' ```http
#' GET https://api.kucoin.com/api/v3/currencies/BTC?chain=bech32
#' ```
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains:
#'   - `currency` (string): Unique currency code.
#'   - `name` (string): Short name of the currency.
#'   - `fullName` (string): Full name of the currency.
#'   - `precision` (integer): Decimal places supported for the currency.
#'   - `confirms` (integer, nullable): Number of block confirmations required.
#'   - `contractAddress` (string, nullable): Contract address for token currencies.
#'   - `isMarginEnabled` (boolean): Whether margin trading is enabled.
#'   - `isDebitEnabled` (boolean): Whether debit is enabled.
#'   - `chains` (array of objects): Each object contains chain-specific details:
#'     - `chainName` (string): Name of the blockchain network.
#'     - `withdrawalMinSize` (string): Minimum withdrawal amount.
#'     - `depositMinSize` (string): Minimum deposit amount.
#'     - `withdrawFeeRate` (string): Withdrawal fee rate.
#'     - `withdrawalMinFee` (string): Minimum withdrawal fee.
#'     - `isWithdrawEnabled` (boolean): Whether withdrawals are enabled.
#'     - `isDepositEnabled` (boolean): Whether deposits are enabled.
#'     - `confirms` (integer): Required confirmations.
#'     - `preConfirms` (integer): Confirmations for advance verification.
#'     - `contractAddress` (string): Contract address.
#'     - `withdrawPrecision` (integer): Withdrawal precision.
#'     - `maxWithdraw` (number, nullable): Maximum withdrawal amount.
#'     - `maxDeposit` (string, nullable): Maximum deposit amount.
#'     - `needTag` (boolean): Whether memo/tag is required.
#'     - `chainId` (string): Chain identifier.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'     "code": "200000",
#'     "data": {
#'         "currency": "BTC",
#'         "name": "BTC",
#'         "fullName": "Bitcoin",
#'         "precision": 8,
#'         "confirms": null,
#'         "contractAddress": null,
#'         "isMarginEnabled": true,
#'         "isDebitEnabled": true,
#'         "chains": [
#'             {
#'                 "chainName": "BTC",
#'                 "withdrawalMinSize": "0.001",
#'                 "depositMinSize": "0.0002",
#'                 "withdrawFeeRate": "0",
#'                 "withdrawalMinFee": "0.0005",
#'                 "isWithdrawEnabled": true,
#'                 "isDepositEnabled": true,
#'                 "confirms": 3,
#'                 "preConfirms": 1,
#'                 "contractAddress": "",
#'                 "withdrawPrecision": 8,
#'                 "maxWithdraw": null,
#'                 "maxDeposit": null,
#'                 "needTag": false,
#'                 "chainId": "btc"
#'             },
#'             {
#'                 "chainName": "Lightning Network",
#'                 "withdrawalMinSize": "0.00001",
#'                 "depositMinSize": "0.00001",
#'                 "withdrawFeeRate": "0",
#'                 "withdrawalMinFee": "0.000015",
#'                 "isWithdrawEnabled": true,
#'                 "isDepositEnabled": true,
#'                 "confirms": 1,
#'                 "preConfirms": 1,
#'                 "contractAddress": "",
#'                 "withdrawPrecision": 8,
#'                 "maxWithdraw": null,
#'                 "maxDeposit": "0.03",
#'                 "needTag": false,
#'                 "chainId": "btcln"
#'             },
#'             {
#'                 "chainName": "KCC",
#'                 "withdrawalMinSize": "0.0008",
#'                 "depositMinSize": null,
#'                 "withdrawFeeRate": "0",
#'                 "withdrawalMinFee": "0.00002",
#'                 "isWithdrawEnabled": true,
#'                 "isDepositEnabled": true,
#'                 "confirms": 20,
#'                 "preConfirms": 20,
#'                 "contractAddress": "0xfa93c12cd345c658bc4644d1d4e1b9615952258c",
#'                 "withdrawPrecision": 8,
#'                 "maxWithdraw": null,
#'                 "maxDeposit": null,
#'                 "needTag": false,
#'                 "chainId": "kcc"
#'             },
#'             {
#'                 "chainName": "BTC-Segwit",
#'                 "withdrawalMinSize": "0.0008",
#'                 "depositMinSize": "0.0002",
#'                 "withdrawFeeRate": "0",
#'                 "withdrawalMinFee": "0.0005",
#'                 "isWithdrawEnabled": false,
#'                 "isDepositEnabled": true,
#'                 "confirms": 2,
#'                 "preConfirms": 2,
#'                 "contractAddress": "",
#'                 "withdrawPrecision": 8,
#'                 "maxWithdraw": null,
#'                 "maxDeposit": null,
#'                 "needTag": false,
#'                 "chainId": "bech32"
#'             }
#'         ]
#'     }
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the general currency fields from the top level of the `data` object.
#' - Processing each entry in the `chains` array, converting it to a row in the resulting `data.table`.
#' - Adding the general currency fields to each row.
#' - Converting string numeric values to proper numeric types and string boolean values to logical types.
#'
#' ## Notes
#' - **Multi-Chain Support**: Many cryptocurrencies exist on multiple blockchain networks with different characteristics. The `chain` parameter allows querying details for a specific network.
#' - **Chain IDs**: The `chainId` field in the response is the value you should use when specifying the `chain` parameter in this and other API calls.
#' - **Null Values**: The API may return `null` for some fields (e.g., `maxWithdraw` for chains with no maximum). These are converted to `NA` in the resulting `data.table`.
#' - **Empty Fields**: Some fields like `contractAddress` may be empty strings for native coins. These are preserved as empty strings in the result.
#' - **Rate Limiting**: This endpoint has a weight of 3 in the API rate limit pool (Public). Plan request frequency accordingly.
#' - **Chain Selection**: If a `chain` parameter is provided, the API will return details only for that specific chain. Otherwise, it returns details for all supported chains.
#'
#' ## Use Cases
#' - **Deposit Configuration**: Determining minimum deposit amounts and required confirmations for user deposits.
#' - **Withdrawal Planning**: Checking withdrawal fees, minimums, and maximums before initiating withdrawals.
#' - **Chain Selection**: Comparing different blockchain options for multi-chain currencies to choose the most cost-effective or fastest network.
#' - **Feature Support**: Determining if a currency supports specific features like margin trading or debit.
#' - **Status Monitoring**: Checking if deposits or withdrawals are currently enabled for specific chains.
#'
#' ## Advice for Automated Trading Systems
#' - **Chain Availability**: Always check `isWithdrawEnabled` and `isDepositEnabled` before attempting transactions, as chains may be temporarily disabled for maintenance.
#' - **Fee Optimization**: Compare `withdrawalMinFee` and `withdrawFeeRate` across chains to select the most cost-effective option for withdrawals.
#' - **Precision Handling**: Use the `precision` and `withdrawPrecision` fields to correctly format amounts in your transactions.
#' - **Tag Requirements**: Check the `needTag` field for currencies that require a memo or destination tag (e.g., XRP, XLM) to avoid lost funds.
#' - **Minimum Validation**: Ensure transaction amounts meet `withdrawalMinSize` and `depositMinSize` to avoid failed transactions.
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve Bitcoin details with all supported chains
#' main_async <- coro::async(function() {
#'   btc <- await(get_currency_impl(currency = "BTC"))
#'   print(btc)
#'   
#'   # Example: Retrieve USDT details specifically for the ERC20 chain
#'   usdt_erc20 <- await(get_currency_impl(currency = "USDT", chain = "eth"))
#'   print(usdt_erc20)
#'   
#'   # Example: Check if withdrawals are enabled for TON on its native chain
#'   ton <- await(get_currency_impl(currency = "TON", chain = "ton"))
#'   withdrawal_enabled <- ton[, unique(isWithdrawEnabled)]
#'   print(paste("TON withdrawals enabled:", withdrawal_enabled))
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#'
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
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_currency_impl.Rds")

        # Process the response and extract the 'data' field
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_currency_impl.Rds")

        data_obj <- parsed_response$data

        chains <- lapply(data_obj$chains, function(el) {
            # Loop through each element in the chain and replace zero-length items with NA
            for (nm in names(el)) {
                if (length(el[[nm]]) == 0) {
                    el[[nm]] <- NA  # or use NA_character_ / NA_real_ based on expected type
                }
            }
            return(el)
        })
        result_dt <- data.table::rbindlist(chains)

        # "confirms", "contractAddress", use the confirms/contractAddress from chain items
        summary_fields <- c(
            "currency", "name", "fullName", "precision",
            "isMarginEnabled", "isDebitEnabled"
        )
        # Convert the resulting data (a named list) into a data.table and return it
        summary_fields_vals <- data_obj[summary_fields]

        # Replace NULL with NA for each element in summary_fields_vals
        summary_fields_vals <- lapply(summary_fields_vals, function(x) {
            if (is.null(x)) {
                return(NA)
            } else {
                return(x)
            }
        })

        # coerce types and add summary fields
        result_dt[, `:=`(
            # summary fields
            currency = as.character(summary_fields_vals$currency),
            name = as.character(summary_fields_vals$name),
            fullName = as.character(summary_fields_vals$fullName),
            precision = as.numeric(summary_fields_vals$precision),
            isMarginEnabled = as.logical(summary_fields_vals$isMarginEnabled),
            isDebitEnabled = as.logical(summary_fields_vals$isDebitEnabled),
            # chain-specific fields
            chainName = as.character(chainName),
            withdrawalMinSize = as.numeric(withdrawalMinSize),
            depositMinSize = as.numeric(depositMinSize),
            withdrawFeeRate = as.numeric(withdrawFeeRate),
            withdrawalMinFee = as.numeric(withdrawalMinFee),
            isWithdrawEnabled = as.logical(isWithdrawEnabled),
            isDepositEnabled = as.logical(isDepositEnabled),
            confirms = as.numeric(confirms),
            preConfirms = as.numeric(preConfirms),
            contractAddress = as.character(contractAddress),
            withdrawPrecision = as.numeric(withdrawPrecision),
            maxWithdraw = as.numeric(maxWithdraw),
            maxDeposit = as.numeric(maxDeposit),
            needTag = as.logical(needTag),
            chainId = as.character(chainId)
        )]

        data.table::setcolorder(result_dt, c(summary_fields, setdiff(colnames(result_dt), summary_fields)))

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_currency_impl:", conditionMessage(e)))
    })
})

#' Process Currency Object
#'
#' Transforms a currency object from the KuCoin API into a structured `data.table`, flattening nested chain information
#' and ensuring consistent data types across all fields. This internal helper function is designed to support
#' `get_all_currencies_impl()`.
#'
#' ### Workflow Overview
#' 1. **Empty Check**: If the input is `NULL` or contains no chains, returns an empty `data.table` with predefined structure.
#' 2. **Chain Processing**: Processes each chain, replacing zero-length items with `NA`.
#' 3. **Summary Field Extraction**: Extracts and handles currency summary fields (e.g., `currency`, `name`, `fullName`).
#' 4. **Data Type Coercion**: Converts all values to appropriate R data types (character, numeric, logical).
#' 5. **Column Ordering**: Sets column order to prioritize summary fields followed by chain-specific fields.
#'
#' @param currency_obj List containing currency data from the KuCoin API, with summary fields and a `chains` array.
#' @return `data.table` containing flattened currency data with one row per chain, including:
#'   - **Summary Fields**:
#'     - `currency` (character): Unique currency code.
#'     - `name` (character): Short name.
#'     - `fullName` (character): Full name.
#'     - `precision` (numeric): Decimal places.
#'     - `isMarginEnabled` (logical): Margin trading status.
#'     - `isDebitEnabled` (logical): Debit status.
#'   - **Chain-Specific Fields**:
#'     - `chainName` (character): Blockchain name.
#'     - `withdrawalMinSize` (numeric): Minimum withdrawal amount.
#'     - `depositMinSize` (numeric): Minimum deposit amount.
#'     - `withdrawFeeRate` (numeric): Withdrawal fee rate.
#'     - `withdrawalMinFee` (numeric): Minimum withdrawal fee.
#'     - `isWithdrawEnabled` (logical): Withdrawal enabled status.
#'     - `isDepositEnabled` (logical): Deposit enabled status.
#'     - `confirms` (numeric): Chain-specific confirmations.
#'     - `preConfirms` (numeric): Pre-confirmations.
#'     - `contractAddress` (character): Chain-specific contract address.
#'     - `withdrawPrecision` (numeric): Withdrawal precision.
#'     - `maxWithdraw` (numeric): Maximum withdrawal amount.
#'     - `maxDeposit` (numeric): Maximum deposit amount.
#'     - `needTag` (logical): Memo/tag requirement.
#'     - `chainId` (character): Blockchain identifier.
#'
#' @importFrom data.table data.table rbindlist setcolorder
#' @keywords internal
process_currency <- function(currency_obj) {
    # if no data return empty data.table
    if (is.null(currency_obj) || length(currency_obj$chains) == 0) {
        return(data.table::data.table(
            # summary fields
            currency = character(0),
            name = character(0),
            fullName = character(0),
            precision = numeric(0),
            # will ignore these summary level fields as the information is also present in the chain level
            # confirms = numeric(0),
            # contractAddress = character(0),
            isMarginEnabled = logical(0),
            isDebitEnabled = logical(0),
            # chain-specific fields
            chainName = character(0),
            withdrawalMinSize = numeric(0),
            depositMinSize = numeric(0),
            withdrawFeeRate = numeric(0),
            withdrawalMinFee = numeric(0),
            isWithdrawEnabled = logical(0),
            isDepositEnabled = logical(0),
            confirms = numeric(0),
            preConfirms = numeric(0),
            contractAddress = character(0),
            withdrawPrecision = numeric(0),
            maxWithdraw = numeric(0),
            maxDeposit = numeric(0),
            needTag = logical(0),
            chainId = character(0)
        ))
    }

    # process to convert any length(0) NULL items to NA
    chains <- lapply(currency_obj$chains, function(el) {
        # Loop through each element in the chain and replace zero-length items with NA
        for (nm in names(el)) {
            if (length(el[[nm]]) == 0) {
                el[[nm]] <- NA  # or use NA_character_ / NA_real_ based on expected type
            }
        }
        return(el)
    })
    chain_dt <- data.table::rbindlist(chains, fill = TRUE)

    # "confirms", "contractAddress", use the confirms/contractAddress from chain items
    summary_fields <- c(
        "currency", "name", "fullName", "precision",
        "isMarginEnabled", "isDebitEnabled"
    )
    # Replace NULL with NA for each element in summary_fields_vals
    summary_fields_vals <- currency_obj[summary_fields]
    summary_fields_vals <- lapply(summary_fields_vals, function(x) {
        if (is.null(x)) {
            return(NA)
        } else {
            return(x)
        }
    })
    # # address cols that are sometimes missing
    # if (is.null(chain_dt$withdrawalMinSize)) {
    #     chain_dt$withdrawalMinSize <- NA_real_
    # }
    # if (is.null(chain_dt$chainName)) {
    #     chain_dt$chainName <- NA_character_
    # }
    # if (is.null(chain_dt$depositMinSize)) {
    #     chain_dt$depositMinSize <- NA_real_
    # }
    if (is.null(chain_dt$withdrawFeeRate)) {
        chain_dt$withdrawFeeRate <- NA_real_
    }
    # if (is.null(chain_dt$withdrawalMinFee)) {
    #     chain_dt$withdrawalMinFee <- NA_real_
    # }
    # coerce types and add summary fields
    chain_dt[, `:=`(
        # summary fields
        currency = as.character(summary_fields_vals$currency),
        name = as.character(summary_fields_vals$name),
        fullName = as.character(summary_fields_vals$fullName),
        precision = as.numeric(summary_fields_vals$precision),
        isMarginEnabled = as.logical(summary_fields_vals$isMarginEnabled),
        isDebitEnabled = as.logical(summary_fields_vals$isDebitEnabled),
        # chain-specific fields
        chainName = as.character(chainName),
        withdrawalMinSize = as.numeric(withdrawalMinSize),
        depositMinSize = as.numeric(depositMinSize),
        withdrawFeeRate = as.numeric(withdrawFeeRate),
        withdrawalMinFee = as.numeric(withdrawalMinFee),
        isWithdrawEnabled = as.logical(isWithdrawEnabled),
        isDepositEnabled = as.logical(isDepositEnabled),
        confirms = as.numeric(confirms),
        preConfirms = as.numeric(preConfirms),
        contractAddress = as.character(contractAddress),
        withdrawPrecision = as.numeric(withdrawPrecision),
        maxWithdraw = as.numeric(maxWithdraw),
        maxDeposit = as.numeric(maxDeposit),
        needTag = as.logical(needTag),
        chainId = as.character(chainId)
    )]

    data.table::setcolorder(chain_dt, c(summary_fields, setdiff(colnames(chain_dt), summary_fields)))

    return(chain_dt[])
}

#' Get All Currencies
#'
#' Retrieves a list of all currencies available on KuCoin asynchronously, combining summary and chain-specific details into a `data.table`.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getAllCurrencies`
#'
#' ## Description
#' This function requests a comprehensive list of currencies supported by KuCoin, including their associated chains. 
#' Not all currencies returned can be used for trading. For multi-chain currencies (like BTC), this endpoint provides 
#' detailed information about each supported chain, including deposit/withdrawal parameters and status.
#'
#' ## Workflow Overview
#' 1. **URL Assembly**: Combines `base_url` with `/api/v3/currencies`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 4. **Data Iteration**: Loops through each currency, extracting summary fields and chain data (if present).
#' 5. **Result Assembly**: Combines summary and chain data into a `data.table`, adding dummy chain columns with `NA` if no chains exist.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v3/currencies`
#'
#' ## Usage
#' Utilised to fetch comprehensive currency details, including multi-chain support, for market analysis or configuration.
#'
#' ## Official Documentation
#' [KuCoin Get All Currencies](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies)
#'
#' ## Function Validated
#' - Last validated: 2025-02-26 15h41
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - **Summary Fields**:
#'     - `currency` (character): Unique currency code that will never change (used as the primary identifier).
#'     - `name` (character): Short name (may change after renaming).
#'     - `fullName` (character): Full currency name (may change after renaming).
#'     - `precision` (numeric): Currency precision (decimal places).
#'     - `isMarginEnabled` (logical): Whether margin trading is supported.
#'     - `isDebitEnabled` (logical): Whether debit is supported.
#'   - **Chain-Specific Fields**:
#'     - `chainName` (character): Chain name of currency.
#'     - `withdrawalMinSize` (numeric): Minimum withdrawal amount (coerced from string).
#'     - `depositMinSize` (numeric): Minimum deposit amount (coerced from string).
#'     - `withdrawFeeRate` (numeric): Withdrawal fee rate (coerced from string).
#'     - `withdrawalMinFee` (numeric): Minimum fees charged for withdrawal (coerced from string).
#'     - `isWithdrawEnabled` (logical): Whether withdrawal is supported.
#'     - `isDepositEnabled` (logical): Whether deposit is supported.
#'     - `confirms` (numeric): Number of block confirmations.
#'     - `preConfirms` (numeric): Number of blocks for advance on-chain verification.
#'     - `contractAddress` (character): Contract address.
#'     - `withdrawPrecision` (numeric): Withdrawal precision bit (maximum decimal place length).
#'     - `maxWithdraw` (numeric): Maximum amount for single withdrawal (coerced from string).
#'     - `maxDeposit` (numeric): Maximum amount for single deposit (only for Lightning Network, coerced from string).
#'     - `needTag` (logical): Whether memo/tag is required.
#'     - `chainId` (character): Chain ID of the currency.
#'     - Optional fields that may be present for some currencies:
#'       - `depositFeeRate` (numeric): Deposit fee rate (coerced from string, may be NA).
#'       - `withdrawMaxFee` (numeric): Maximum withdrawal fee (coerced from string, may be NA).
#'       - `depositTierFee` (character): Tiered deposit fee information (may be NA).
#'
#' ## Details
#'
#' ### Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (array): Array of currency objects, each containing:
#'   - `currency` (string): Unique currency code.
#'   - `name` (string): Currency name.
#'   - `fullName` (string): Full currency name.
#'   - `precision` (integer): Currency precision.
#'   - `confirms` (integer or null): Number of block confirmations.
#'   - `contractAddress` (string or null): Contract address.
#'   - `isMarginEnabled` (boolean): Margin support status.
#'   - `isDebitEnabled` (boolean): Debit support status.
#'   - `chains` (array): Array of chain objects, each containing:
#'     - `chainName` (string): Chain name.
#'     - `withdrawalMinSize` (string): Minimum withdrawal amount as string.
#'     - `depositMinSize` (string or null): Minimum deposit amount as string.
#'     - `withdrawFeeRate` (string): Withdrawal fee rate as string.
#'     - `withdrawalMinFee` (string): Minimum withdrawal fee as string.
#'     - `isWithdrawEnabled` (boolean): Withdrawal support status.
#'     - `isDepositEnabled` (boolean): Deposit support status.
#'     - `confirms` (integer): Chain-specific confirmations.
#'     - `preConfirms` (integer): Pre-confirmations.
#'     - `contractAddress` (string): Chain-specific contract address.
#'     - `withdrawPrecision` (integer): Withdrawal precision.
#'     - `maxWithdraw` (string or null): Maximum withdrawal amount as string.
#'     - `maxDeposit` (string or null): Maximum deposit amount as string.
#'     - `needTag` (boolean): Memo/tag requirement.
#'     - `chainId` (string): Chain identifier.
#'     - `depositFeeRate` (string, optional): Deposit fee rate.
#'     - `withdrawMaxFee` (string, optional): Maximum withdrawal fee.
#'     - `depositTierFee` (string, optional): Tiered deposit fee.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "currency": "BTC",
#'       "name": "BTC",
#'       "fullName": "Bitcoin",
#'       "precision": 8,
#'       "confirms": null,
#'       "contractAddress": null,
#'       "isMarginEnabled": true,
#'       "isDebitEnabled": true,
#'       "chains": [
#'         {
#'           "chainName": "BTC",
#'           "withdrawalMinSize": "0.001",
#'           "depositMinSize": "0.0002",
#'           "withdrawFeeRate": "0",
#'           "withdrawalMinFee": "0.0005",
#'           "isWithdrawEnabled": true,
#'           "isDepositEnabled": true,
#'           "confirms": 3,
#'           "preConfirms": 1,
#'           "contractAddress": "",
#'           "withdrawPrecision": 8,
#'           "maxWithdraw": null,
#'           "maxDeposit": null,
#'           "needTag": false,
#'           "chainId": "btc"
#'         },
#'         {
#'           "chainName": "Lightning Network",
#'           "withdrawalMinSize": "0.00001",
#'           "depositMinSize": "0.00001",
#'           "withdrawFeeRate": "0",
#'           "withdrawalMinFee": "0.000015",
#'           "isWithdrawEnabled": true,
#'           "isDepositEnabled": true,
#'           "confirms": 1,
#'           "preConfirms": 1,
#'           "contractAddress": "",
#'           "withdrawPrecision": 8,
#'           "maxWithdraw": null,
#'           "maxDeposit": "0.03",
#'           "needTag": false,
#'           "chainId": "btcln"
#'         }
#'       ]
#'     },
#'     {
#'       "currency": "BTCP",
#'       "name": "BTCP",
#'       "fullName": "Bitcoin Private",
#'       "precision": 8,
#'       "confirms": null,
#'       "contractAddress": null,
#'       "isMarginEnabled": false,
#'       "isDebitEnabled": false,
#'       "chains": [
#'         {
#'           "chainName": "BTCP",
#'           "withdrawalMinSize": "0.100000",
#'           "depositMinSize": null,
#'           "withdrawFeeRate": "0",
#'           "withdrawalMinFee": "0.010000",
#'           "isWithdrawEnabled": false,
#'           "isDepositEnabled": false,
#'           "confirms": 6,
#'           "preConfirms": 6,
#'           "contractAddress": "",
#'           "withdrawPrecision": 8,
#'           "maxWithdraw": null,
#'           "maxDeposit": null,
#'           "needTag": false,
#'           "chainId": "btcp"
#'         }
#'       ]
#'     }
#'   ]
#' }
#' ```
#'
#' ### Notes
#' - **Currency Codes**: Currency codes conform to the ISO 4217 standard where possible. Currencies without ISO 4217 representation may use custom codes.
#' - **Currency Identification**: For a coin, the `currency` field is a fixed value and serves as the only recognized identifier. The `name` and `fullName` fields may change if the currency is renamed.
#' - **Example**: If XRB is renamed to "Nano", you would still use "XRB" (the currency code) to reference it.
#' - **Multi-Chain Support**: Many cryptocurrencies are available on multiple blockchains (e.g., BTC on native Bitcoin, Lightning Network, KCC, etc.), each with different parameters.
#' - **Optional Fields**: Some currencies may include additional fields like `depositFeeRate`, `withdrawMaxFee`, and `depositTierFee` which are not present for all currencies.
#' - **Rate Limiting**: This endpoint has a weight of 3 in the Public rate limit pool. Consider caching the results if multiple calls are needed.
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Fetch all currencies
#'   currencies <- await(get_all_currencies_impl())
#'   
#'   # Print the total number of currencies
#'   cat("Total currencies:", length(unique(currencies$currency)), "\n")
#'   
#'   # Filter for a specific currency to see all its chains
#'   btc_chains <- currencies[currency == "BTC"]
#'   print(btc_chains)
#'   
#'   # Find all currencies that support margin trading
#'   margin_currencies <- unique(currencies[isMarginEnabled == TRUE]$currency)
#'   cat("Margin-enabled currencies:", length(margin_currencies), "\n")
#'   
#'   # Find all chains that support deposits but not withdrawals
#'   deposit_only <- currencies[isDepositEnabled == TRUE & isWithdrawEnabled == FALSE]
#'   print(deposit_only[, .(currency, chainName, chainId)])
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
        saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_all_currencies_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_all_currencies_impl.Rds")

        data_obj <- parsed_response$data

        currencies_list <- vector("list", length(data_obj))

        for (i in seq_along(data_obj)) {
            curr_currency_obj <- data_obj[[i]]
            currencies_list[[i]] <- process_currency(curr_currency_obj)
        }

        unique(lapply(currencies_list, names))
        result_dt <- data.table::rbindlist(currencies_list, fill = TRUE)

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_currencies_impl:", conditionMessage(e)))
    })
})

#' Get Symbol
#'
#' Retrieves detailed information about a specified trading symbol from the KuCoin API asynchronously.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 4
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getSymbol`
#'
#' ## Description
#' This function requests detailed information for a specific trading pair (symbol) on KuCoin. It provides 
#' essential trading parameters including minimum and maximum order sizes, price and quantity increments, 
#' and fee information. The returned data defines trading rules and constraints for the specified symbol.
#' 
#' Note that this endpoint provides configuration data for the trading pair itself. For market information 
#' such as current price and volume, use Get All Tickers instead.
#'
#' ## Workflow Overview
#' 1. **URL Assembly**: Combines `base_url`, `/api/v2/symbols/`, and the `symbol`.
#' 2. **Input Validation**: Verifies that `symbol` is a non-empty character string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Type Conversion**: Converts string fields from the API response to appropriate R data types (numeric, logical).
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v2/symbols/{symbol}`
#'
#' ## Usage
#' Utilised to fetch metadata and trading rules for a specific trading symbol, such as price increments and trading limits.
#'
#' ## Official Documentation
#' [KuCoin Get Symbol](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-symbol)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 17h17
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Unique code of a symbol; it will not change after renaming (e.g., `"BTC-USDT"`).
#'   - `name` (character): Name of trading pair; it will change after renaming (e.g., `"BTC-USDT"`).
#'   - `baseCurrency` (character): Base currency (e.g., `"BTC"`).
#'   - `quoteCurrency` (character): Quote currency (e.g., `"USDT"`).
#'   - `feeCurrency` (character): The currency in which fees are charged.
#'   - `market` (character): The trading market (e.g., `"USDS"`, `"BTC"`, `"ALTS"`).
#'   - `baseMinSize` (numeric): The minimum order quantity required to place an order.
#'   - `quoteMinSize` (numeric): The minimum order funds required to place a market order.
#'   - `baseMaxSize` (numeric): The maximum order size required to place an order.
#'   - `quoteMaxSize` (numeric): The maximum order funds required to place a market order.
#'   - `baseIncrement` (numeric): Quantity increment; quantity must be a positive integer multiple of this value.
#'   - `quoteIncrement` (numeric): Quote increment; funds must be a positive integer multiple of this value.
#'   - `priceIncrement` (numeric): Price increment; price must be a positive integer multiple of this value.
#'   - `priceLimitRate` (numeric): Threshold for price protection.
#'   - `minFunds` (numeric): The minimum trading amount required for orders.
#'   - `isMarginEnabled` (logical): Whether margin trading is available for this symbol.
#'   - `enableTrading` (logical): Whether trading is enabled for this symbol.
#'   - `feeCategory` (numeric): Fee type category (1, 2, or 3).
#'   - `makerFeeCoefficient` (numeric): The maker fee coefficient; actual fee is multiplied by this value.
#'   - `takerFeeCoefficient` (numeric): The taker fee coefficient; actual fee is multiplied by this value.
#'   - `st` (logical): Whether it is a Special Treatment symbol.
#'   - `callauctionIsEnabled` (logical): Whether call auction is enabled for this symbol.
#'   - `callauctionPriceFloor` (character or NULL): The lowest price declared in the call auction.
#'   - `callauctionPriceCeiling` (character or NULL): The highest bid price in the call auction.
#'   - `callauctionFirstStageStartTime` (integer or NULL): Timestamp when first phase of call auction starts (allows adding and canceling orders).
#'   - `callauctionSecondStageStartTime` (integer or NULL): Timestamp when second phase of call auction starts (allows adding orders, disallows canceling orders).
#'   - `callauctionThirdStageStartTime` (integer or NULL): Timestamp when third phase of call auction starts (disallows adding and canceling orders).
#'   - `tradingStartTime` (integer or NULL): Official opening time (end time of the third phase of call auction).
#'
#' ## Details
#'
#' ### API Request Schema
#' - `symbol` (string, **required**): Path parameter, the trading pair symbol (e.g., `"BTC-USDT"`).
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): A single object containing trading pair details:
#'   - `symbol` (string): Unique code of the trading pair (will not change after renaming).
#'   - `name` (string): Name of the trading pair (may change after renaming).
#'   - `baseCurrency` (string): Base currency code.
#'   - `quoteCurrency` (string): Quote currency code.
#'   - `feeCurrency` (string): Currency in which fees are charged.
#'   - `market` (string): Trading market category.
#'   - `baseMinSize` (string): Minimum order quantity.
#'   - `quoteMinSize` (string): Minimum order funds for market orders.
#'   - `baseMaxSize` (string): Maximum order quantity.
#'   - `quoteMaxSize` (string): Maximum order funds for market orders.
#'   - `baseIncrement` (string): Quantity increment.
#'   - `quoteIncrement` (string): Quote increment.
#'   - `priceIncrement` (string): Price increment.
#'   - `priceLimitRate` (string): Price protection threshold.
#'   - `minFunds` (string): Minimum trading amount.
#'   - `isMarginEnabled` (boolean): Margin trading availability.
#'   - `enableTrading` (boolean): Trading availability.
#'   - `feeCategory` (integer): Fee type enum (1, 2, or 3).
#'   - `makerFeeCoefficient` (string): Maker fee coefficient.
#'   - `takerFeeCoefficient` (string): Taker fee coefficient.
#'   - `st` (boolean): Special Treatment flag.
#'   - `callauctionIsEnabled` (boolean): Call auction status.
#'   - `callauctionPriceFloor` (string or null): Lowest call auction price.
#'   - `callauctionPriceCeiling` (string or null): Highest call auction price.
#'   - `callauctionFirstStageStartTime` (integer or null): First stage start timestamp.
#'   - `callauctionSecondStageStartTime` (integer or null): Second stage start timestamp.
#'   - `callauctionThirdStageStartTime` (integer or null): Third stage start timestamp.
#'   - `tradingStartTime` (integer or null): Trading start timestamp.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "symbol": "BTC-USDT",
#'     "name": "BTC-USDT",
#'     "baseCurrency": "BTC",
#'     "quoteCurrency": "USDT",
#'     "feeCurrency": "USDT",
#'     "market": "USDS",
#'     "baseMinSize": "0.00001",
#'     "quoteMinSize": "0.1",
#'     "baseMaxSize": "10000000000",
#'     "quoteMaxSize": "99999999",
#'     "baseIncrement": "0.00000001",
#'     "quoteIncrement": "0.000001",
#'     "priceIncrement": "0.1",
#'     "priceLimitRate": "0.1",
#'     "minFunds": "0.1",
#'     "isMarginEnabled": true,
#'     "enableTrading": true,
#'     "feeCategory": 1,
#'     "makerFeeCoefficient": "1.00",
#'     "takerFeeCoefficient": "1.00",
#'     "st": false,
#'     "callauctionIsEnabled": false,
#'     "callauctionPriceFloor": null,
#'     "callauctionPriceCeiling": null,
#'     "callauctionFirstStageStartTime": null,
#'     "callauctionSecondStageStartTime": null,
#'     "callauctionThirdStageStartTime": null,
#'     "tradingStartTime": null
#'   }
#' }
#' ```
#'
#' ### Notes
#' - **Type Conversion**: While the API returns numeric values as strings, this function converts them to R numeric types for easier use.
#' - **Trading Rules**: The `baseMinSize` and `baseMaxSize` fields define the minimum and maximum order size.
#' - **Price Increments**: The `priceIncrement` field specifies the minimum order price as well as the price increment. 
#'   The order price must be a positive integer multiple of this value (e.g., if the increment is 0.01, prices like 
#'   0.001 and 0.021 will be rejected).
#' - **Quote Increments**: Similarly, `quoteIncrement` defines the increment for quote currency amounts.
#' - **Future Adjustments**: The `priceIncrement` and `quoteIncrement` values may be adjusted in the future. 
#'   KuCoin will notify users by email and site notifications before adjustments.
#' - **Minimum Funds Rules**: 
#'   - For limit buy orders: `[Order Amount * Order Price] >= minFunds`
#'   - For limit sell orders: `[Order Amount * Order Price] >= minFunds`
#'   - For market buy orders: `Order Value >= minFunds`
#'   - For market sell orders: `[Order Amount * Last Price of Base Currency] >= minFunds`
#' - **Order Rejections**: 
#'   - API market buy orders (by amount) valued at `(Order Amount * Last Price of Base Currency) < minFunds` will be rejected.
#'   - API market sell orders (by value) valued at `< minFunds` will be rejected.
#'   - Take profit and stop loss orders at market or limit prices will be rejected when triggered if they don't meet minimum funds requirements.
#' - **Rate Limiting**: This endpoint has a weight of 4 in the Public rate limit pool.
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get detailed information for BTC-USDT trading pair
#'   btc_usdt <- await(get_symbol_impl(symbol = "BTC-USDT"))
#'   
#'   # Calculate the minimum BTC amount that can be bought with 100 USDT at current price of 62000
#'   current_price <- 62000
#'   usdt_amount <- 100
#'   min_btc <- usdt_amount / current_price
#'   
#'   # Check if the amount is above minimum order size
#'   if (min_btc >= btc_usdt$baseMinSize) {
#'     cat("Can buy", min_btc, "BTC with 100 USDT\n")
#'   } else {
#'     cat("Cannot buy BTC with 100 USDT - minimum required:", 
#'         btc_usdt$baseMinSize, "BTC\n")
#'   }
#'   
#'   # Print information about price precision 
#'   cat("Price must be increments of", btc_usdt$priceIncrement, "USDT\n")
#'   cat("Quantity must be increments of", btc_usdt$baseIncrement, "BTC\n")
#'   
#'   # Check if margin trading is enabled
#'   if (btc_usdt$isMarginEnabled) {
#'     cat("Margin trading is enabled for BTC-USDT\n")
#'   } else {
#'     cat("Margin trading is not available for BTC-USDT\n")
#'   }
#'   
#'   # Calculate maker and taker fees for a 1 BTC purchase
#'   purchase_amount <- 1 * current_price  # 1 BTC at current price
#'   maker_fee <- purchase_amount * (btc_usdt$makerFeeCoefficient / 100)
#'   taker_fee <- purchase_amount * (btc_usdt$takerFeeCoefficient / 100)
#'   cat("Maker fee for 1 BTC purchase:", maker_fee, "USDT\n")
#'   cat("Taker fee for 1 BTC purchase:", taker_fee, "USDT\n")
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
    if (is.null(symbol) || !is.character(symbol)) {
        rlang::abort("The 'symbol' parameter must be a non-empty character string.")
    }
    tryCatch({
        endpoint <- "/api/v2/symbols/"
        url <- paste0(base_url, endpoint, symbol)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_symbol_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_symbol_impl.Rds")

        # Convert the entire 'data' field from the response into a data.table.
        result_dt <- data.table::as.data.table(parsed_response$data)

        # coerce types
        result_dt[, `:=`(
            symbol = as.character(symbol),
            name = as.character(name),
            baseCurrency = as.character(baseCurrency),
            quoteCurrency = as.character(quoteCurrency),
            feeCurrency = as.character(feeCurrency),
            market = as.character(market),
            baseMinSize = as.numeric(baseMinSize),
            quoteMinSize = as.numeric(quoteMinSize),
            baseMaxSize = as.numeric(baseMaxSize),
            quoteMaxSize = as.numeric(quoteMaxSize),
            baseIncrement = as.numeric(baseIncrement),
            quoteIncrement = as.numeric(quoteIncrement),
            priceIncrement = as.numeric(priceIncrement),
            priceLimitRate = as.numeric(priceLimitRate),
            minFunds = as.numeric(minFunds),
            isMarginEnabled = as.logical(isMarginEnabled),
            enableTrading = as.logical(enableTrading),
            feeCategory = as.numeric(feeCategory),
            makerFeeCoefficient = as.numeric(makerFeeCoefficient),
            takerFeeCoefficient = as.numeric(takerFeeCoefficient),
            st = as.logical(st), # this is a special treatment flag
            callauctionIsEnabled = as.logical(callauctionIsEnabled)
        )]

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_symbol_impl:", conditionMessage(e)))
    })
})

#' Get All Symbols
#'
#' Retrieves a list of all available trading symbols from the KuCoin API asynchronously, optionally filtered by market.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 4
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getAllSymbols`
#'
#' ## Description
#' This function requests a comprehensive list of all trading pairs (symbols) available on KuCoin, 
#' optionally filtered by market. It provides detailed information about each symbol, including 
#' trading parameters, fee structures, and market categorisation. The information returned defines 
#' the trading rules for each symbol.
#' 
#' Note that this endpoint provides configuration data for trading pairs; for current market information 
#' such as prices and volumes, use Get All Tickers instead.
#'
#' ## Workflow Overview
#' 1. **Query Construction**: Builds a query string with the optional `market` parameter using `build_query()`.
#' 2. **URL Assembly**: Combines `base_url`, `/api/v2/symbols`, and the query string.
#' 3. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 4. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 5. **Data Cleaning**: Processes each symbol object, replacing empty items with `NA`.
#' 6. **Type Conversion**: Converts string values in the API response to appropriate R data types (numeric, logical).
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v2/symbols`
#'
#' ## Usage
#' Utilised to obtain a comprehensive list of trading symbols for market exploration, filtering, or determining
#' trading parameters for specific pairs.
#'
#' ## Official Documentation
#' [KuCoin Get All Symbols](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-symbols)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 17h49
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param market Character string (optional); trading market to filter symbols (e.g., `"ALTS"`, `"USDS"`, `"ETF"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Unique code of a symbol; it will not change after renaming (e.g., `"BTC-USDT"`).
#'   - `name` (character): Name of trading pair; it will change after renaming (e.g., `"BTC-USDT"`).
#'   - `baseCurrency` (character): Base currency (e.g., `"BTC"`).
#'   - `quoteCurrency` (character): Quote currency (e.g., `"USDT"`).
#'   - `feeCurrency` (character): The currency in which fees are charged.
#'   - `market` (character): The trading market (e.g., `"USDS"`, `"BTC"`, `"ALTS"`).
#'   - `baseMinSize` (numeric): The minimum order quantity required to place an order.
#'   - `quoteMinSize` (numeric): The minimum order funds required to place a market order.
#'   - `baseMaxSize` (numeric): The maximum order size required to place an order.
#'   - `quoteMaxSize` (numeric): The maximum order funds required to place a market order.
#'   - `baseIncrement` (numeric): Quantity increment; quantity must be a positive integer multiple of this value.
#'   - `quoteIncrement` (numeric): Quote increment; funds must be a positive integer multiple of this value.
#'   - `priceIncrement` (numeric): Price increment; price must be a positive integer multiple of this value.
#'   - `priceLimitRate` (numeric): Threshold for price protection.
#'   - `minFunds` (numeric): The minimum trading amount required for orders.
#'   - `isMarginEnabled` (logical): Whether margin trading is available for this symbol.
#'   - `enableTrading` (logical): Whether trading is enabled for this symbol.
#'   - `feeCategory` (numeric): Fee type category (1, 2, or 3).
#'   - `makerFeeCoefficient` (numeric): The maker fee coefficient; actual fee is multiplied by this value.
#'   - `takerFeeCoefficient` (numeric): The taker fee coefficient; actual fee is multiplied by this value.
#'   - `st` (logical): Whether it is a Special Treatment symbol.
#'   - `callauctionIsEnabled` (logical): Whether call auction is enabled for this symbol.
#'   - `callauctionPriceFloor` (numeric): The lowest price declared in the call auction.
#'   - `callauctionPriceCeiling` (numeric): The highest bid price in the call auction.
#'   - `callauctionFirstStageStartTime` (numeric): Timestamp when first phase of call auction starts (allows adding and cancelling orders).
#'   - `callauctionSecondStageStartTime` (numeric): Timestamp when second phase of call auction starts (allows adding orders, disallows cancelling orders).
#'   - `callauctionThirdStageStartTime` (numeric): Timestamp when third phase of call auction starts (disallows adding and cancelling orders).
#'   - `tradingStartTime` (numeric): Official opening time (end time of the third phase of call auction).
#'
#' ## Details
#'
#' ### Request Parameters
#' - `market` (string, optional): The trading market to filter by (e.g., `"ALTS"`, `"USDS"`, `"ETF"`).
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (array): Array of symbol objects, each containing:
#'   - `symbol` (string): Unique code of a symbol; it will not change after renaming.
#'   - `name` (string): Name of trading pair; it will change after renaming.
#'   - `baseCurrency` (string): Base currency.
#'   - `quoteCurrency` (string): Quote currency.
#'   - `feeCurrency` (string): The currency in which fees are charged.
#'   - `market` (string): The trading market.
#'   - `baseMinSize` (string): Minimum order quantity (returned as string, converted to numeric).
#'   - `quoteMinSize` (string): Minimum order funds (returned as string, converted to numeric).
#'   - `baseMaxSize` (string): Maximum order size (returned as string, converted to numeric).
#'   - `quoteMaxSize` (string): Maximum order funds (returned as string, converted to numeric).
#'   - `baseIncrement` (string): Quantity increment (returned as string, converted to numeric).
#'   - `quoteIncrement` (string): Quote increment (returned as string, converted to numeric).
#'   - `priceIncrement` (string): Price increment (returned as string, converted to numeric).
#'   - `priceLimitRate` (string): Price protection threshold (returned as string, converted to numeric).
#'   - `minFunds` (string): Minimum trading amount (returned as string, converted to numeric).
#'   - `isMarginEnabled` (boolean): Margin trading availability.
#'   - `enableTrading` (boolean): Trading availability.
#'   - `feeCategory` (integer): Fee type enum (1, 2, or 3).
#'   - `makerFeeCoefficient` (string): Maker fee coefficient (returned as string, converted to numeric).
#'   - `takerFeeCoefficient` (string): Taker fee coefficient (returned as string, converted to numeric).
#'   - `st` (boolean): Special Treatment flag.
#'   - `callauctionIsEnabled` (boolean): Call auction status.
#'   - `callauctionPriceFloor` (string or null): Lowest call auction price (returned as string, converted to numeric if not null).
#'   - `callauctionPriceCeiling` (string or null): Highest call auction price (returned as string, converted to numeric if not null).
#'   - `callauctionFirstStageStartTime` (integer or null): First stage start timestamp.
#'   - `callauctionSecondStageStartTime` (integer or null): Second stage start timestamp.
#'   - `callauctionThirdStageStartTime` (integer or null): Third stage start timestamp.
#'   - `tradingStartTime` (integer or null): Trading start timestamp.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "symbol": "BTC-USDT",
#'       "name": "BTC-USDT",
#'       "baseCurrency": "BTC",
#'       "quoteCurrency": "USDT",
#'       "feeCurrency": "USDT",
#'       "market": "USDS",
#'       "baseMinSize": "0.00001",
#'       "quoteMinSize": "0.1",
#'       "baseMaxSize": "10000000000",
#'       "quoteMaxSize": "99999999",
#'       "baseIncrement": "0.00000001",
#'       "quoteIncrement": "0.000001",
#'       "priceIncrement": "0.1",
#'       "priceLimitRate": "0.1",
#'       "minFunds": "0.1",
#'       "isMarginEnabled": true,
#'       "enableTrading": true,
#'       "feeCategory": 1,
#'       "makerFeeCoefficient": "1.00",
#'       "takerFeeCoefficient": "1.00",
#'       "st": false,
#'       "callauctionIsEnabled": false,
#'       "callauctionPriceFloor": null,
#'       "callauctionPriceCeiling": null,
#'       "callauctionFirstStageStartTime": null,
#'       "callauctionSecondStageStartTime": null,
#'       "callauctionThirdStageStartTime": null,
#'       "tradingStartTime": null
#'     }
#'   ]
#' }
#' ```
#'
#' ### Notes
#' - **Type Conversion**: While the API returns numeric values as strings, this function converts them to R numeric types for easier use.
#' - **Market Filter**: Use the `market` parameter to filter for symbols in a specific market category (e.g., `"USDS"`, `"BTC"`, `"ALTS"`, `"ETF"`).
#' - **Price Increments**: The `priceIncrement` field specifies the minimum order price as well as the price increment. 
#'   The order price must be a positive integer multiple of this value (e.g., if the increment is 0.01, prices like 
#'   0.001 and 0.021 will be rejected).
#' - **Quote Increments**: Similarly, `quoteIncrement` defines the increment for quote currency amounts.
#' - **Future Adjustments**: The `priceIncrement` and `quoteIncrement` values may be adjusted in the future. 
#'   KuCoin will notify users by email and site notifications before adjustments.
#' - **Minimum Funds Rules**: 
#'   - For limit buy orders: `[Order Amount * Order Price] >= minFunds`
#'   - For limit sell orders: `[Order Amount * Order Price] >= minFunds`
#'   - For market buy orders: `Order Value >= minFunds`
#'   - For market sell orders: `[Order Amount * Last Price of Base Currency] >= minFunds`
#' - **Order Rejections**: 
#'   - API market buy orders (by amount) valued at `(Order Amount * Last Price of Base Currency) < minFunds` will be rejected.
#'   - API market sell orders (by value) valued at `< minFunds` will be rejected.
#'   - Take profit and stop loss orders at market or limit prices will be rejected when triggered if they don't meet minimum funds requirements.
#' - **Rate Limiting**: This endpoint has a weight of 4 in the Public rate limit pool.
#' - **Data Size**: This endpoint may return a large number of records (over 1000 symbols), so consider filtering by market if needed.
#'
#' ### Advice for Automated Traders
#' - **Fee Calculation Pipeline**: Implement a fee calculation pipeline that combines data from this endpoint with your trade volume data. For each symbol:
#'   ```r
#'   fee_amount <- trade_value * ifelse(is_maker, makerFeeCoefficient, takerFeeCoefficient)
#'   ```
#'   Store this data in a persistent cache with a regular refresh interval (e.g., hourly).
#'
#' - **Order Validation Engine**: Create a pre-validation layer for all orders that verifies:
#'   1. Order quantities meet `baseMinSize` and respect `baseIncrement` precision
#'   2. Order prices respect `priceIncrement` precision
#'   3. Total order value satisfies `minFunds` requirements
#'   This can prevent API rejections and improve system reliability.
#'
#' - **Dynamic Lot Sizing**: Implement smart lot sizing that adjusts trade sizes based on `baseMinSize`, `baseIncrement`, and `minFunds`:
#'   ```r
#'   valid_lot_size <- function(symbol_data, desired_size, current_price) {
#'     # Round to baseIncrement precision
#'     rounded_size <- floor(desired_size / symbol_data$baseIncrement) * symbol_data$baseIncrement
#'     # Ensure it meets minimum size
#'     size <- max(rounded_size, symbol_data$baseMinSize)
#'     # Verify it meets minFunds requirement
#'     if (size * current_price < symbol_data$minFunds) {
#'       size <- ceiling(symbol_data$minFunds / current_price / symbol_data$baseIncrement) * symbol_data$baseIncrement
#'     }
#'     return(size)
#'   }
#'   ```
#'
#' - **Market Selection Algorithm**: Develop a market selection algorithm that filters symbols based on specific criteria:
#'   ```r
#'   # Find liquid USDT pairs with margin capability and tight spreads
#'   tradable_universe <- symbols[
#'     quoteCurrency == "USDT" & 
#'     isMarginEnabled == TRUE & 
#'     priceIncrement/current_price < 0.001 &
#'     enableTrading == TRUE
#'   ]
#'   ```
#'
#' - **Price Normalisation Functions**: Create utility functions to normalise prices according to symbol requirements:
#'   ```r
#'   normalise_price <- function(symbol_data, raw_price) {
#'     floor(raw_price / symbol_data$priceIncrement) * symbol_data$priceIncrement
#'   }
#'   ```
#'
#' - **Trading Restrictions Monitoring**: Implement monitoring for `enableTrading` and `st` (Special Treatment) flags to automatically adjust your trading strategy when conditions change.
#'
#' - **Call Auction Handling**: For new listings or special markets, implement logic to detect and handle call auctions:
#'   ```r
#'   auction_symbols <- symbols[callauctionIsEnabled == TRUE]
#'   if (nrow(auction_symbols) > 0) {
#'     # Special auction handling strategies
#'   }
#'   ```
#'
#' - **Fee Efficiency Analysis**: Analyse fee structures across markets to optimise for lowest trading costs:
#'   ```r
#'   fee_comparison <- symbols[, .(
#'     symbol, 
#'     makerFeeCoefficient, 
#'     takerFeeCoefficient, 
#'     fee_diff = takerFeeCoefficient - makerFeeCoefficient
#'   )]
#'   # Find markets where maker/taker spread is highest
#'   high_fee_diff <- fee_comparison[order(-fee_diff)]
#'   ```
#'
#' - **Symbol Change Tracking**: Implement a monitoring system that tracks changes to symbol parameters over time, particularly focusing on price increments and minimum size requirements that could affect existing automated strategies.
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get all trading symbols
#'   all_symbols <- await(get_all_symbols_impl())
#'   cat("Total symbols:", nrow(all_symbols), "\n")
#'   
#'   # Get only USDS market symbols (USDT pairs etc.)
#'   usds_symbols <- await(get_all_symbols_impl(market = "USDS"))
#'   cat("USDS market symbols:", nrow(usds_symbols), "\n")
#'   
#'   # Find all BTC trading pairs
#'   btc_pairs <- all_symbols[quoteCurrency == "BTC"]
#'   cat("BTC trading pairs:", nrow(btc_pairs), "\n")
#'   
#'   # Find all symbols with margin trading enabled
#'   margin_symbols <- all_symbols[isMarginEnabled == TRUE]
#'   cat("Margin-enabled symbols:", nrow(margin_symbols), "\n")
#'   
#'   # Find symbols with the smallest minimum order size
#'   min_order_sizes <- all_symbols[, .(symbol, baseMinSize)]
#'   min_order_sizes <- min_order_sizes[order(baseMinSize)]
#'   print(head(min_order_sizes, 10))
#'   
#'   # Find symbols currently in call auction phase
#'   auction_symbols <- all_symbols[callauctionIsEnabled == TRUE]
#'   if (nrow(auction_symbols) > 0) {
#'     print(auction_symbols[, .(symbol, callauctionPriceFloor, callauctionPriceCeiling)])
#'   } else {
#'     cat("No symbols currently in call auction phase\n")
#'   }
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist
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
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_all_symbols_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_all_symbols_impl.Rds")

        data_obj <- parsed_response$data

        chains <- lapply(data_obj, function(el) {
            # Loop through each element in the chain and replace zero-length items with NA
            for (nm in names(el)) {
                if (length(el[[nm]]) == 0) {
                    el[[nm]] <- NA  # or use NA_character_ / NA_real_ based on expected type
                }
            }
            return(el)
        })
        result_dt <- data.table::rbindlist(chains)

        # coerce types
        result_dt[, `:=`(
            symbol = as.character(symbol),
            name = as.character(name),
            baseCurrency = as.character(baseCurrency),
            quoteCurrency = as.character(quoteCurrency),
            feeCurrency = as.character(feeCurrency),
            market = as.character(market),
            baseMinSize = as.numeric(baseMinSize),
            quoteMinSize = as.numeric(quoteMinSize),
            baseMaxSize = as.numeric(baseMaxSize),
            quoteMaxSize = as.numeric(quoteMaxSize),
            baseIncrement = as.numeric(baseIncrement),
            quoteIncrement = as.numeric(quoteIncrement),
            priceIncrement = as.numeric(priceIncrement),
            priceLimitRate = as.numeric(priceLimitRate),
            minFunds = as.numeric(minFunds),
            isMarginEnabled = as.logical(isMarginEnabled),
            enableTrading = as.logical(enableTrading),
            feeCategory = as.numeric(feeCategory),
            makerFeeCoefficient = as.numeric(makerFeeCoefficient),
            takerFeeCoefficient = as.numeric(takerFeeCoefficient),
            st = as.logical(st), # this is a special treatment flag
            callauctionIsEnabled = as.logical(callauctionIsEnabled),
            callauctionPriceFloor = as.numeric(callauctionPriceFloor),
            callauctionPriceCeiling = as.numeric(callauctionPriceCeiling),
            callauctionFirstStageStartTime = as.numeric(callauctionFirstStageStartTime),
            callauctionSecondStageStartTime = as.numeric(callauctionSecondStageStartTime),
            callauctionThirdStageStartTime = as.numeric(callauctionThirdStageStartTime),
            tradingStartTime = as.numeric(tradingStartTime)
        )]

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_symbols_impl:", conditionMessage(e)))
    })
})

#' Get Ticker
#'
#' Retrieves Level 1 market data (ticker information) for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getTicker`
#'
#' ## Description
#' This function requests real-time Level 1 market data for a specific trading symbol on KuCoin.
#' It provides the current best bid and ask prices and sizes, along with the most recent trade
#' price and size. This is essential market data for price monitoring, spread analysis, and
#' execution algorithms.
#'
#' ## Workflow Overview
#' 1. **Input Validation**: Verifies that `symbol` is a non-empty character string.
#' 2. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level1`, and the query string.
#' 4. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 5. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 6. **Data Enrichment**: Adds `symbol`, converts millisecond timestamp to POSIXct datetime, and reorders columns.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/orderbook/level1`
#'
#' ## Usage
#' Utilised to obtain real-time ticker data (e.g., best bid/ask, last price) for a trading symbol.
#' This is typically used for monitoring current prices, calculating spreads, and making trading decisions.
#'
#' ## Official Documentation
#' [KuCoin Get Ticker](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-ticker)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 18h14
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Trading symbol (e.g., `"BTC-USDT"`).
#'   - `time` (integer): Snapshot timestamp in milliseconds.
#'   - `time_datetime` (POSIXct): Converted snapshot timestamp as a POSIXct datetime object.
#'   - `sequence` (character): Sequence number for synchronising updates.
#'   - `price` (character): Last traded price.
#'   - `size` (character): Last traded size.
#'   - `bestBid` (character): Best bid price.
#'   - `bestBidSize` (character): Best bid size.
#'   - `bestAsk` (character): Best ask price.
#'   - `bestAskSize` (character): Best ask size.
#'
#' ## Details
#'
#' ### Request Parameters
#' - `symbol` (string, **required**): Trading symbol (e.g., `"BTC-USDT"`).
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): A single object containing ticker information:
#'   - `time` (integer <int64>): Timestamp in milliseconds.
#'   - `sequence` (string): Sequence number for updates.
#'   - `price` (string): Last traded price.
#'   - `size` (string): Last traded size.
#'   - `bestBid` (string): Best bid price.
#'   - `bestBidSize` (string): Best bid size.
#'   - `bestAsk` (string): Best ask price.
#'   - `bestAskSize` (string): Best ask size.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "time": 1729172965609,
#'     "sequence": "14609309753",
#'     "price": "67269",
#'     "size": "0.000025",
#'     "bestBid": "67267.5",
#'     "bestBidSize": "0.000025",
#'     "bestAsk": "67267.6",
#'     "bestAskSize": "1.24808993"
#'   }
#' }
#' ```
#'
#' ### Notes
#' - **Data Freshness**: This endpoint provides real-time data with minimal delay. The `time` field indicates when the snapshot was taken.
#' - **Sequence Number**: The `sequence` field can be used to order updates when polling frequently.
#' - **Price Representation**: All price and size values are returned as strings to preserve precision. You may need to convert them to numeric types for calculations.
#' - **Spread Calculation**: The spread can be calculated as `as.numeric(bestAsk) - as.numeric(bestBid)`.
#' - **Rate Limiting**: This endpoint has a weight of 2 in the Public rate limit pool.
#'
#' ### Advice for Automated Traders
#' - **Efficient Polling**: For high-frequency applications, implement a polling mechanism that respects rate limits:
#'   ```r
#'   poll_ticker <- function(symbol, interval_ms = 500) {
#'     last_poll <- Sys.time()
#'     coro::async(function() {
#'       while(TRUE) {
#'         current <- Sys.time()
#'         if (difftime(current, last_poll, units = "msecs") >= interval_ms) {
#'           ticker <- await(get_ticker_impl(symbol = symbol))
#'           process_ticker(ticker)
#'           last_poll <- Sys.time()
#'         }
#'         Sys.sleep(0.01)  # Small sleep to prevent CPU overuse
#'       }
#'     })
#'   }
#'   ```
#'
#' - **Smart Order Routing**: Use ticker data to make intelligent routing decisions:
#'   ```r
#'   determine_order_type <- function(ticker, target_price, tolerance = 0.0001) {
#'     bid <- as.numeric(ticker$bestBid)
#'     ask <- as.numeric(ticker$bestAsk)

#'     if (target_price <= bid * (1 + tolerance)) {
#'       return("limit_sell")  # Can sell at or above target with limit order
#'     } else if (target_price >= ask * (1 - tolerance)) {
#'       return("limit_buy")   # Can buy at or below target with limit order
#'     } else {
#'       # Price is inside the spread, may need market order or patience
#'       return("market_or_wait")
#'     }
#'   }
#'   ```
#'
#' - **Spread Monitoring**: Implement spread monitoring for trading signals:
#'   ```r
#'   is_spread_favourable <- function(ticker, max_spread_bps = 10) {
#'     bid <- as.numeric(ticker$bestBid)
#'     ask <- as.numeric(ticker$bestAsk)
#'     spread_bps <- (ask - bid) / bid * 10000

#'     return(spread_bps <= max_spread_bps)
#'   }
#'   ```
#'
#' - **Price Impact Estimation**: Use the best bid/ask sizes to estimate potential price impact:
#'   ```r
#'   estimate_impact <- function(ticker, order_size, side = "buy") {
#'     if (side == "buy") {
#'       size_ratio <- order_size / as.numeric(ticker$bestAskSize)
#'       return(ifelse(size_ratio <= 1, 0, log(size_ratio) * 0.01))  # Simplified impact model
#'     } else {
#'       size_ratio <- order_size / as.numeric(ticker$bestBidSize)
#'       return(ifelse(size_ratio <= 1, 0, log(size_ratio) * 0.01))
#'     }
#'   }
#'   ```
#'
#' - **Volatility Calculation**: Track price changes for volatility estimation:
#'   ```r
#'   update_volatility <- function(ticker, price_history, window = 20) {
#'     price_history <- c(price_history, as.numeric(ticker$price))
#'     if (length(price_history) > window) {
#'       price_history <- price_history[(length(price_history) - window + 1):length(price_history)]
#'     }

#'     if (length(price_history) >= 2) {
#'       returns <- diff(log(price_history))
#'       volatility <- sd(returns) * sqrt(252 * 24 * 60 * 60 / 300)  # Annualised from 5-min returns
#'       return(list(volatility = volatility, price_history = price_history))
#'     }

#'     return(list(volatility = NA, price_history = price_history))
#'   }
#'   ```
#'
#' - **Crossed Markets Detection**: Implement safety checks for unusual market conditions:
#'   ```r
#'   is_market_crossed <- function(ticker) {
#'     bid <- as.numeric(ticker$bestBid)
#'     ask <- as.numeric(ticker$bestAsk)

#'     return(bid >= ask)  # A crossed market (bid ≥ ask) indicates potential issues
#'   }
#'   ```
#'
#' - **Composite Price Calculation**: Calculate a composite mid-price weighted by order sizes:
#'   ```r
#'   weighted_mid_price <- function(ticker) {
#'     bid <- as.numeric(ticker$bestBid)
#'     ask <- as.numeric(ticker$bestAsk)
#'     bid_size <- as.numeric(ticker$bestBidSize)
#'     ask_size <- as.numeric(ticker$bestAskSize)

#'     total_size <- bid_size + ask_size
#'     weighted_price <- (bid * ask_size + ask * bid_size) / total_size

#'     return(weighted_price)
#'   }
#'   ```
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get current ticker for BTC-USDT
#'   ticker <- await(get_ticker_impl(symbol = "BTC-USDT"))
#'   
#'   # Print the basic ticker information
#'   cat("Symbol:", ticker$symbol, "\n")
#'   cat("Time:", format(ticker$time_datetime, "%Y-%m-%d %H:%M:%S"), "\n")
#'   cat("Last price:", ticker$price, "\n")
#'   cat("Best bid:", ticker$bestBid, "Size:", ticker$bestBidSize, "\n")
#'   cat("Best ask:", ticker$bestAsk, "Size:", ticker$bestAskSize, "\n")
#'   
#'   # Calculate and print the spread
#'   spread <- as.numeric(ticker$bestAsk) - as.numeric(ticker$bestBid)
#'   spread_pct <- spread / as.numeric(ticker$bestBid) * 100
#'   cat("Spread:", sprintf("%.2f (%.4f%%)", spread, spread_pct), "\n")
#'   
#'   # Check if the spread is tight enough for trading
#'   max_acceptable_spread_pct <- 0.05  # 0.05% maximum acceptable spread
#'   if (spread_pct <= max_acceptable_spread_pct) {
#'     cat("Spread is acceptable for trading\n")
#'   } else {
#'     cat("Spread is too wide for optimal trading\n")
#'   }
#'   
#'   # Fetch tickers for multiple symbols
#'   symbols <- c("BTC-USDT", "ETH-USDT", "SOL-USDT")
#'   tickers <- list()
#'   
#'   for (sym in symbols) {
#'     tickers[[sym]] <- await(get_ticker_impl(symbol = sym))
#'   }
#'   
#'   # Compare prices across symbols
#'   comparison <- data.frame(
#'     Symbol = sapply(symbols, function(s) tickers[[s]]$symbol),
#'     Price = sapply(symbols, function(s) as.numeric(tickers[[s]]$price)),
#'     Spread_Pct = sapply(symbols, function(s) {
#'       (as.numeric(tickers[[s]]$bestAsk) - as.numeric(tickers[[s]]$bestBid)) / 
#'       as.numeric(tickers[[s]]$bestBid) * 100
#'     })
#'   )
#'   
#'   print(comparison)
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
    if (is.null(symbol) || !is.character(symbol)) {
        rlang::abort("The 'symbol' parameter must be a non-empty character string.")
    }
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/orderbook/level1"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_ticker_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_ticker_impl.Rds")

        # Convert the 'data' field (a named list) to a data.table.
        ticker_dt <- data.table::as.data.table(parsed_response$data)
        ticker_dt[, symbol := symbol]

        # convert kucoin time to POSIXct
        ticker_dt[, time_datetime := time_convert_from_kucoin(time, "ms")]

        move_cols <- c("symbol", "time", "time_datetime")
        data.table::setcolorder(ticker_dt, c(move_cols, setdiff(names(ticker_dt), move_cols)))
        return(ticker_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_ticker_impl:", conditionMessage(e)))
    })
})

#' Get All Tickers
#'
#' Retrieves market tickers for all trading pairs from the KuCoin API asynchronously, including 24-hour volume data.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 15
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getAllTickers`
#'
#' ## Description
#' This function requests a comprehensive snapshot of market data for all trading pairs on KuCoin, 
#' including current prices and 24-hour statistics. KuCoin takes a snapshot of this data every 2 seconds.
#' The response includes best bid and ask prices and sizes, price changes, high/low values, and volume data
#' for each trading pair.
#' 
#' Note that on rare occasions when KuCoin changes a currency name, you can use the `symbolName` field
#' instead of the `symbol` field to track symbols that have been renamed.
#'
#' ## Workflow Overview
#' 1. **URL Assembly**: Combines `base_url` with `/api/v1/market/allTickers`.
#' 2. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 3. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 4. **Data Cleaning**: Processes each ticker object, replacing empty or NULL items with `NA`.
#' 5. **Data Conversion**: Converts the `"ticker"` array to a `data.table`, adding `time` and `time_datetime` 
#'    from the global snapshot time.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/allTickers`
#'
#' ## Usage
#' Utilised to fetch a snapshot of market data across all KuCoin trading pairs for monitoring or analysis.
#' This endpoint is particularly useful for market overview dashboards, pair discovery, or batch analysis
#' of market conditions.
#'
#' ## Official Documentation
#' [KuCoin Get All Tickers](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-tickers)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 19h23
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @return Promise resolving to a `data.table` containing:
#'   - `symbol` (character): Trading symbol unique code.
#'   - `symbolName` (character): Name of trading pairs, may change after renaming.
#'   - `buy` (character): Best bid price.
#'   - `bestBidSize` (character): Best bid size.
#'   - `sell` (character): Best ask price.
#'   - `bestAskSize` (character): Best ask size.
#'   - `changeRate` (character): 24-hour change rate.
#'   - `changePrice` (character): 24-hour price change.
#'   - `high` (character): Highest price in 24h.
#'   - `low` (character): Lowest price in 24h.
#'   - `vol` (character): 24-hour volume, executed based on base currency.
#'   - `volValue` (character): 24-hour traded amount.
#'   - `last` (character): Last traded price.
#'   - `averagePrice` (character): Average trading price in the last 24 hours.
#'   - `takerFeeRate` (character): Basic taker fee rate.
#'   - `makerFeeRate` (character): Basic maker fee rate.
#'   - `takerCoefficient` (character): Taker fee coefficient; actual fee must be multiplied by this value.
#'   - `makerCoefficient` (character): Maker fee coefficient; actual fee must be multiplied by this value.
#'   - `time` (numeric): Snapshot timestamp in milliseconds.
#'   - `time_datetime` (POSIXct): Converted snapshot timestamp as a POSIXct datetime object.
#'
#' ## Details
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains snapshot time and ticker array:
#'   - `time` (integer <int64>): Global timestamp of the snapshot in milliseconds.
#'   - `ticker` (array): Array of ticker objects, each containing:
#'     - `symbol` (string): Trading symbol unique code.
#'     - `symbolName` (string): Name of trading pairs, may change after renaming.
#'     - `buy` (string): Best bid price.
#'     - `bestBidSize` (string): Best bid size.
#'     - `sell` (string): Best ask price.
#'     - `bestAskSize` (string): Best ask size.
#'     - `changeRate` (string): 24-hour change rate.
#'     - `changePrice` (string): 24-hour price change.
#'     - `high` (string): Highest price in 24h.
#'     - `low` (string): Lowest price in 24h.
#'     - `vol` (string): 24-hour volume, executed based on base currency.
#'     - `volValue` (string): 24-hour traded amount.
#'     - `last` (string): Last traded price.
#'     - `averagePrice` (string): Average trading price in the last 24 hours.
#'     - `takerFeeRate` (string): Basic taker fee rate.
#'     - `makerFeeRate` (string): Basic maker fee rate.
#'     - `takerCoefficient` (string): Taker fee coefficient (`"1"` or `"0"`).
#'     - `makerCoefficient` (string): Maker fee coefficient (`"1"` or `"0"`).
#'
#' **Example JSON Response** (truncated for brevity):
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "time": 1729173207043,
#'     "ticker": [
#'       {
#'         "symbol": "BTC-USDT",
#'         "symbolName": "BTC-USDT",
#'         "buy": "67192.5",
#'         "bestBidSize": "0.000025",
#'         "sell": "67192.6",
#'         "bestAskSize": "1.24949204",
#'         "changeRate": "-0.0014",
#'         "changePrice": "-98.5",
#'         "high": "68321.4",
#'         "low": "66683.3",
#'         "vol": "1836.03034612",
#'         "volValue": "124068431.06726933",
#'         "last": "67193",
#'         "averagePrice": "67281.21437289",
#'         "takerFeeRate": "0.001",
#'         "makerFeeRate": "0.001",
#'         "takerCoefficient": "1",
#'         "makerCoefficient": "1"
#'       }
#'     ]
#'   }
#' }
#' ```
#'
#' ### Notes
#' - **Data Freshness**: KuCoin takes a snapshot of this data every 2 seconds.
#' - **Fee Calculation**: To calculate the actual fee, multiply the transaction amount by the corresponding fee rate and fee coefficient.
#' - **Symbol Tracking**: If a currency is renamed, use `symbolName` rather than `symbol` to track it through the change.
#' - **Numeric Conversion**: All price and size values are returned as strings to preserve precision. You may need to convert them to numeric types for calculations.
#' - **Rate Limiting**: This endpoint has a weight of 15 in the Public rate limit pool, which is significantly higher than most endpoints due to the volume of data returned.
#' - **Data Size**: This endpoint returns details for all trading pairs (potentially over 1,000 entries), so consider caching results if polling frequently.
#'
#' ### Advice for Automated Traders
#' - **Efficient Market Scanning**: Use this endpoint for periodic market scans rather than individual ticker requests:
#'   ```r
#'   market_scan <- function(criteria) {
#'     coro::async(function() {
#'       all_tickers <- await(get_all_tickers_impl())

#'       # Apply filter criteria
#'       matches <- all_tickers[
#'         as.numeric(changeRate) > criteria$min_change_rate &
#'         as.numeric(vol) > criteria$min_volume &
#'         as.numeric(last) > criteria$min_price
#'       ]

#'       return(matches)
#'     })
#'   }
#'   ```
#'
#' - **Market Breadth Indicators**: Calculate market-wide statistics for trend analysis:
#'   ```r
#'   calculate_market_breadth <- function(tickers, base_currency = "USDT") {
#'     # Filter for pairs with the specified base currency
#'     base_pairs <- tickers[grepl(paste0("-", base_currency, "$"), symbol)]

#'     # Calculate breadth indicators
#'     total_pairs <- nrow(base_pairs)
#'     advancing <- sum(as.numeric(base_pairs$changeRate) > 0)
#'     declining <- sum(as.numeric(base_pairs$changeRate) < 0)
#'     unchanged <- total_pairs - advancing - declining

#'     advance_decline_ratio <- advancing / max(declining, 1)
#'     advance_decline_line <- advancing - declining

#'     return(list(
#'       total_pairs = total_pairs,
#'       advancing = advancing,
#'       declining = declining,
#'       unchanged = unchanged,
#'       advance_decline_ratio = advance_decline_ratio,
#'       advance_decline_line = advance_decline_line
#'     ))
#'   }
#'   ```
#'
#' - **Volatility Ranking**: Identify the most volatile markets for potential trading opportunities:
#'   ```r
#'   rank_by_volatility <- function(tickers, min_volume = 0) {
#'     # Calculate volatility as (high - low) / low
#'     volatility_data <- tickers[as.numeric(vol) >= min_volume, .(
#'       symbol = symbol,
#'       volatility = (as.numeric(high) - as.numeric(low)) / as.numeric(low),
#'       volume = as.numeric(vol),
#'       price = as.numeric(last)
#'     )]

#'     # Rank by volatility in descending order
#'     return(volatility_data[order(-volatility)])
#'   }
#'   ```
#'
#' - **Correlation Matrix Builder**: Identify correlated and uncorrelated assets:
#'   ```r
#'   # Note: This would require historical data collection over time
#'   build_correlation_matrix <- function(price_history, top_n = 20) {
#'     # Extract the most active symbols by volume
#'     top_symbols <- names(sort(colSums(price_history$volume), decreasing = TRUE))[1:min(top_n, ncol(price_history$volume))]

#'     # Calculate returns
#'     returns <- apply(price_history$close[, top_symbols], 2, function(x) diff(log(x)))

#'     # Calculate correlation matrix
#'     correlation_matrix <- cor(returns, use = "pairwise.complete.obs")

#'     return(correlation_matrix)
#'   }
#'   ```
#'
#' - **Fee Optimisation**: Compare fee structures across symbols:
#'   ```r
#'   compare_fees <- function(tickers) {
#'     fee_data <- tickers[, .(
#'       symbol = symbol,
#'       maker_fee = as.numeric(makerFeeRate) * as.numeric(makerCoefficient),
#'       taker_fee = as.numeric(takerFeeRate) * as.numeric(takerCoefficient)
#'     )]

#'     # Group by fee structure
#'     fee_groups <- fee_data[, .N, by = .(maker_fee, taker_fee)]
#'     fee_groups <- fee_groups[order(maker_fee, taker_fee)]

#'     return(fee_groups)
#'   }
#'   ```
#'
#' - **Market Anomaly Detection**: Identify unusual price or volume conditions:
#'   ```r
#'   detect_anomalies <- function(tickers, z_score_threshold = 3) {
#'     # Convert relevant fields to numeric
#'     numeric_data <- tickers[, .(
#'       symbol = symbol,
#'       price = as.numeric(last),
#'       volume = as.numeric(vol),
#'       change_rate = as.numeric(changeRate)
#'     )]

#'     # Calculate z-scores
#'     numeric_data[, `:=`(
#'       price_z = (price - mean(price, na.rm = TRUE)) / sd(price, na.rm = TRUE),
#'       volume_z = (volume - mean(volume, na.rm = TRUE)) / sd(volume, na.rm = TRUE),
#'       change_z = (change_rate - mean(change_rate, na.rm = TRUE)) / sd(change_rate, na.rm = TRUE)
#'     )]

#'     # Identify anomalies
#'     anomalies <- numeric_data[
#'       abs(price_z) > z_score_threshold | 
#'       abs(volume_z) > z_score_threshold | 
#'       abs(change_z) > z_score_threshold
#'     ]

#'     return(anomalies[order(-abs(volume_z))])
#'   }
#'   ```
#'
#' - **Caching Strategy**: Implement efficient caching to respect rate limits:
#'   ```r
#'   # Cache data with a 2-minute timeout (KuCoin snapshots every 2 seconds)
#'   tickers_cache <- NULL
#'   last_fetch_time <- as.POSIXct(0, origin = "1970-01-01")
#'   
#'   get_cached_tickers <- function(max_age_seconds = 120) {
#'     coro::async(function() {
#'       current_time <- Sys.time()

#'       # Check if cache needs refresh
#'       if (is.null(tickers_cache) || 
#'           difftime(current_time, last_fetch_time, units = "secs") > max_age_seconds) {
#'         tickers_cache <<- await(get_all_tickers_impl())
#'         last_fetch_time <<- current_time
#'       }

#'       return(tickers_cache)
#'     })
#'   }
#'   ```
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get all tickers
#'   tickers <- await(get_all_tickers_impl())
#'   
#'   # Print the snapshot time
#'   cat("Snapshot time:", format(tickers$time_datetime[1], "%Y-%m-%d %H:%M:%S"), "\n")
#'   
#'   # Count the total number of trading pairs
#'   cat("Total trading pairs:", nrow(tickers), "\n")
#'   
#'   # Find the top 5 gainers in the last 24 hours
#'   top_gainers <- tickers[order(-as.numeric(changeRate))][1:5]
#'   cat("\nTop 5 Gainers:\n")
#'   print(top_gainers[, .(symbol, changeRate, last, vol)])
#'   
#'   # Find the top 5 losers in the last 24 hours
#'   top_losers <- tickers[order(as.numeric(changeRate))][1:5]
#'   cat("\nTop 5 Losers:\n")
#'   print(top_losers[, .(symbol, changeRate, last, vol)])
#'   
#'   # Find the most active pairs by volume
#'   most_active <- tickers[order(-as.numeric(volValue))][1:5]
#'   cat("\nMost Active Pairs:\n")
#'   print(most_active[, .(symbol, vol, volValue, last)])
#'   
#'   # Calculate average spread for USDT pairs
#'   usdt_pairs <- tickers[grepl("-USDT$", symbol)]
#'   usdt_pairs[, spread := as.numeric(sell) - as.numeric(buy)]
#'   usdt_pairs[, spread_pct := spread / as.numeric(buy) * 100]
#'   
#'   avg_spread <- mean(usdt_pairs$spread_pct, na.rm = TRUE)
#'   cat("\nAverage spread for USDT pairs:", sprintf("%.4f%%", avg_spread), "\n")
#'   
#'   # Identify pairs with the tightest spreads (potentially more liquid)
#'   tight_spreads <- usdt_pairs[order(spread_pct)][1:5]
#'   cat("\nPairs with Tightest Spreads:\n")
#'   print(tight_spreads[, .(symbol, spread_pct, buy, sell, vol)])
#'   
#'   # Calculate market-wide statistics
#'   total_pairs <- nrow(tickers)
#'   gainers <- sum(as.numeric(tickers$changeRate) > 0, na.rm = TRUE)
#'   losers <- sum(as.numeric(tickers$changeRate) < 0, na.rm = TRUE)
#'   unchanged <- total_pairs - gainers - losers
#'   
#'   cat("\nMarket Breadth:\n")
#'   cat("Advancing:", gainers, "(", sprintf("%.1f%%", gainers/total_pairs*100), ")\n")
#'   cat("Declining:", losers, "(", sprintf("%.1f%%", losers/total_pairs*100), ")\n")
#'   cat("Unchanged:", unchanged, "(", sprintf("%.1f%%", unchanged/total_pairs*100), ")\n")
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist
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
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_all_tickers_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_all_tickers_impl.Rds")

        # Extract the global snapshot time and the ticker array.
        ticker_list <- parsed_response$data$ticker

        ticker_list2 <- lapply(ticker_list, function(el) {
            # Loop through each element in the chain and replace zero-length items with NA
            for (nm in names(el)) {
                if (length(el[[nm]]) == 0 && is.null(el[[nm]])) {
                    el[[nm]] <- NA  # or use NA_character_ / NA_real_ based on expected type
                }
            }
            return(el)
        })

        result_dt <- data.table::rbindlist(ticker_list2)

        # coerce types
        result_dt[, `:=`(
            # summary stats
            time = as.numeric(parsed_response$data$time),
            time_datetime = time_convert_from_kucoin(parsed_response$data$time, "ms"),
            # ticker info
            symbol = as.character(symbol),
            symbolName = as.character(symbolName),
            buy = as.character(buy),
            bestBidSize = as.character(bestBidSize),
            sell = as.character(sell),
            bestAskSize = as.character(bestAskSize),
            changeRate = as.character(changeRate),
            changePrice = as.character(changePrice),
            high = as.character(high),
            low = as.character(low),
            vol = as.character(vol),
            volValue = as.character(volValue),
            last = as.character(last),
            averagePrice = as.character(averagePrice),
            takerFeeRate = as.character(takerFeeRate),
            makerFeeRate = as.character(makerFeeRate),
            takerCoefficient = as.character(takerCoefficient),
            makerCoefficient = as.character(makerCoefficient)
        )]
        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_all_tickers_impl:", conditionMessage(e)))
    })
})

#' Get Trade History
#'
#' Retrieves the most recent 100 trade records for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 3
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getTradeHistory`
#'
#' ## Description
#' This function requests the recent trade history for a specific trading symbol on KuCoin. 
#' It provides details of the latest 100 executed trades, including price, size, side (buy/sell), 
#' and execution time. This information is essential for analysing recent market activity and 
#' price momentum on a particular trading pair.
#'
#' ## Workflow Overview
#' 1. **Input Validation**: Verifies that `symbol` is a non-empty character string.
#' 2. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url`, `/api/v1/market/histories`, and the query string.
#' 4. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 5. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts the `"data"` field.
#' 6. **Type Conversion**: Converts string values to appropriate R data types and adds a datetime column from the nanosecond timestamp.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/histories`
#'
#' ## Usage
#' Utilised to fetch recent trade history for a trading symbol, useful for tracking market activity,
#' analysing recent price movements, and detecting unusual trading patterns.
#'
#' ## Official Documentation
#' [KuCoin Get Trade History](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-trade-history)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 20h17
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @return Promise resolving to a `data.table` containing:
#'   - `sequence` (character): Sequence number for synchronising updates.
#'   - `price` (numeric): Filled price, converted from string to numeric.
#'   - `size` (numeric): Filled amount, converted from string to numeric.
#'   - `side` (character): Filled side; `"buy"` or `"sell"`. The trade side indicates the taker order side.
#'   - `time` (numeric): Filled timestamp in nanoseconds.
#'   - `time_datetime` (POSIXct): Converted trade timestamp as a POSIXct datetime object.
#'
#' ## Details
#'
#' ### Request Parameters
#' - `symbol` (string, **required**): Trading symbol (e.g., `"BTC-USDT"`).
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (array): Array of trade objects, each containing:
#'   - `sequence` (string): Sequence number for synchronising updates.
#'   - `price` (string): Filled price (returned as string, converted to numeric).
#'   - `size` (string): Filled amount (returned as string, converted to numeric).
#'   - `side` (string): Filled side; either `"buy"` or `"sell"`. The trade side indicates the taker order side.
#'   - `time` (integer <int64>): Filled timestamp in nanoseconds.
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": [
#'     {
#'       "sequence": "10976028003549185",
#'       "price": "67122",
#'       "size": "0.000025",
#'       "side": "buy",
#'       "time": 1729177117877000000
#'     },
#'     {
#'       "sequence": "10976028003549188",
#'       "price": "67122",
#'       "size": "0.01792257",
#'       "side": "buy",
#'       "time": 1729177117877000000
#'     },
#'     {
#'       "sequence": "10976028003549191",
#'       "price": "67122.9",
#'       "size": "0.05654289",
#'       "side": "buy",
#'       "time": 1729177117877000000
#'     }
#'   ]
#' }
#' ```
#'
#' ### Notes
#' - **Limited History**: Only the most recent 100 trades are returned for each symbol.
#' - **Taker vs. Maker**: The `side` field indicates the taker order side. A taker order is the order that was matched with orders already open on the order book.
#' - **Nanosecond Precision**: The `time` field is in nanoseconds, providing extremely high-precision timestamps for trade execution time.
#' - **Sequence Numbers**: The `sequence` field can be used to order trades correctly when multiple trades happen at the same timestamp.
#' - **Rate Limiting**: This endpoint has a weight of 3 in the Public rate limit pool.
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get trade history for BTC-USDT
#'   trades <- await(get_trade_history_impl(symbol = "BTC-USDT"))
#'
#'   print(trades)
#' })
#' main_async()
#' while (!later::loop_empty()) later::run_now()
#' }
#' @importFrom coro async await
#' @importFrom httr GET timeout
#' @importFrom data.table as.data.table rbindlist
#' @importFrom rlang abort
#' @export
get_trade_history_impl <- coro::async(function(
    base_url = get_base_url(),
    symbol
) {
    if (is.null(symbol) || !is.character(symbol)) {
        rlang::abort("The 'symbol' parameter must be a non-empty character string.")
    }
    tryCatch({
        qs <- build_query(list(symbol = symbol))
        endpoint <- "/api/v1/market/histories"
        url <- paste0(base_url, endpoint, qs)

        # Send a GET request to the endpoint with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_trade_history_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_trade_history_impl.Rds")

        # Convert the 'data' field (an array of trade history objects) into a data.table.
        result_dt <- data.table::rbindlist(parsed_response$data)

        result_dt[, `:=`(
            sequence = as.character(sequence),
            price = as.numeric(price),
            size = as.numeric(size),
            side = as.character(side),
            time = as.numeric(time),
            time_datetime = time_convert_from_kucoin(time, "ns")
        )]

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_trade_history_impl:", conditionMessage(e)))
    })
})

#' Get Part OrderBook
#'
#' Retrieves partial orderbook depth data (20 or 100 levels) for a specified trading symbol from the KuCoin API asynchronously.
#'
#' ## API Details
#' 
#' - **Domain**: Spot
#' - **API Channel**: Public
#' - **API Permission**: NULL
#' - **API Rate Limit Pool**: Public
#' - **API Rate Limit Weight**: 2
#' - **SDK Service**: Spot
#' - **SDK Sub-Service**: Market
#' - **SDK Method Name**: `getPartOrderBook`
#'
#' ## Description
#' This function requests partial orderbook depth data (aggregated by price) for a specific trading symbol on KuCoin.
#' It provides a snapshot of bid and ask orders at specific price levels (either 20 or 100 levels). This endpoint
#' is recommended for faster system response and reduced traffic consumption compared to the full orderbook endpoint.
#'
#' ## Workflow Overview
#' 1. **Input Validation**: Ensures `size` is 20 or 100, aborting if invalid.
#' 2. **Query Construction**: Builds a query string with the `symbol` parameter using `build_query()`.
#' 3. **URL Assembly**: Combines `base_url`, `/api/v1/market/orderbook/level2_{size}`, and the query string.
#' 4. **HTTP Request**: Sends a GET request with a 10-second timeout via `httr::GET()`.
#' 5. **Response Processing**: Validates the response with `process_kucoin_response()` and extracts `"data"`.
#' 6. **Data Conversion**: Processes bid and ask arrays into separate data tables, then combines them with snapshot metadata.
#'
#' ## API Endpoint
#' `GET https://api.kucoin.com/api/v1/market/orderbook/level2_{size}`
#'
#' ## Usage
#' Utilised to obtain a snapshot of the orderbook for a trading symbol, showing aggregated bids and asks at specified price levels.
#'
#' ## Official Documentation
#' [KuCoin Get Part OrderBook](https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-part-orderbook)
#' 
#' ## Function Validated
#' - Last validated: 2025-02-26 21h29
#'
#' @param base_url Character string; base URL for the KuCoin API. Defaults to `get_base_url()`.
#' @param symbol Character string; trading symbol (e.g., `"BTC-USDT"`).
#' @param size Integer; orderbook depth (20 or 100); this represents the number of levels to return, a level is a price point with aggregated size.
#' @return Promise resolving to a `data.table` containing:
#'   - `time_datetime` (POSIXct): Snapshot timestamp as a POSIXct datetime object.
#'   - `time` (numeric): Snapshot timestamp in milliseconds.
#'   - `sequence` (character): Orderbook update sequence number.
#'   - `side` (character): Order side (`"bid"` or `"ask"`).
#'   - `price` (numeric): Price level.
#'   - `size` (numeric): Aggregated size at that price level.
#'
#' ## Details
#'
#' ### Path Parameters
#' - `size` (integer, **required**): Get the depth layer, optional value: 20, 100.
#'
#' ### Query Parameters
#' - `symbol` (string, **required**): Trading symbol (e.g., `"BTC-USDT"`).
#'
#' ### API Response Schema
#' - `code` (string): Status code, where `"200000"` indicates success.
#' - `data` (object): Contains:
#'   - `time` (integer <int64>): Timestamp (milliseconds).
#'   - `sequence` (string): Sequence number.
#'   - `bids` (array of arrays): Bids, from high to low. Each inner array contains price and size. Example:
#'     ```json
#'     "bids": [
#'       ["66976.4", "0.69109872"],  // First array: [price, size]
#'       ["66976.3", "0.14377"]      // Second array: [price, size]
#'     ]
#'     ```
#'   - `asks` (array of arrays): Asks, from low to high. Each inner array contains price and size. Example:
#'     ```json
#'     "asks": [
#'       ["66976.5", "0.05408199"],  // First array: [price, size]
#'       ["66976.8", "0.0005"]       // Second array: [price, size]
#'     ]
#'     ```
#'
#' **Example JSON Response**:
#' ```json
#' {
#'   "code": "200000",
#'   "data": {
#'     "time": 1729176273859,
#'     "sequence": "14610502970",
#'     "bids": [
#'       [
#'         "66976.4",
#'         "0.69109872"
#'       ],
#'       [
#'         "66976.3",
#'         "0.14377"
#'       ]
#'     ],
#'     "asks": [
#'       [
#'         "66976.5",
#'         "0.05408199"
#'       ],
#'       [
#'         "66976.8",
#'         "0.0005"
#'       ]
#'     ]
#'   }
#' }
#' ```
#'
#' The function processes this response by:
#' - Extracting the global timestamp and sequence from the `data` object.
#' - Converting each bid and ask array into a row in the resulting `data.table`.
#' - Adding a `side` column to differentiate bids and asks.
#' - Converting the timestamp to a POSIXct datetime object.
#'
#' ## Notes
#' - **Sorted Orders**: Bids are sorted from high to low, while asks are sorted from low to high.
#' - **Data Freshness**: The `time` field indicates when the snapshot was taken.
#' - **Sequence Number**: The `sequence` field can be used to order updates when polling frequently.
#' - **Rate Limiting**: This endpoint has a weight of 2 in the Public rate limit pool.
#' - **Size Options**: Only 20 or 100 levels can be requested; requests with other values will be rejected.
#'
#' ## Advice for Automated Trading Systems
#' - **Market Depth Analysis**: Use the orderbook data to calculate available liquidity at different price levels:
#'   ```r
#'   calculate_liquidity <- function(orderbook_dt, side, price_threshold) {
#'     if (side == "bid") {
#'       # Sum all bid sizes at or above the threshold price
#'       return(orderbook_dt[side == "bid" & price >= price_threshold, sum(size)])
#'     } else {
#'       # Sum all ask sizes at or below the threshold price
#'       return(orderbook_dt[side == "ask" & price <= price_threshold, sum(size)])
#'     }
#'   }
#'   ```
#'
#' - **Market Impact Estimation**: Estimate price impact for different order sizes:
#'   ```r
#'   estimate_market_impact <- function(orderbook_dt, side, order_size) {
#'     if (side == "buy") {
#'       # Sort asks by price (low to high)
#'       asks <- orderbook_dt[side == "ask"][order(price)]

#'       # Initialize variables
#'       remaining_size <- order_size
#'       total_cost <- 0

#'       for (i in 1:nrow(asks)) {
#'         if (remaining_size <= 0) break

#'         # Calculate how much can be filled at this price level
#'         filled_at_level <- min(remaining_size, asks$size[i])

#'         # Add to total cost
#'         total_cost <- total_cost + filled_at_level * asks$price[i]

#'         # Reduce remaining size
#'         remaining_size <- remaining_size - filled_at_level
#'       }

#'       # Calculate average price
#'       avg_price <- total_cost / order_size
#'       return(list(avg_price = avg_price, filled = (order_size - remaining_size)))
#'     } else {
#'       # For sell orders, use similar logic with bids
#'       # ...
#'     }
#'   }
#'   ```
#'
#' - **Microstructure Analysis**: Monitor order imbalance for momentum signals:
#'   ```r
#'   calculate_order_imbalance <- function(orderbook_dt, levels = 5) {
#'     top_bids <- orderbook_dt[side == "bid"][order(-price)][1:levels]
#'     top_asks <- orderbook_dt[side == "ask"][order(price)][1:levels]

#'     bid_volume <- sum(top_bids$size * top_bids$price)
#'     ask_volume <- sum(top_asks$size * top_asks$price)

#'     imbalance_ratio <- bid_volume / (bid_volume + ask_volume)
#'     return(imbalance_ratio)  # Values > 0.5 indicate buying pressure
#'   }
#'   ```
#'
#' - **Spread Analysis**: Track and analyse the bid-ask spread for trading signals:
#'   ```r
#'   analyse_spread <- function(orderbook_dt) {
#'     top_bid <- orderbook_dt[side == "bid", max(price)]
#'     top_ask <- orderbook_dt[side == "ask", min(price)]

#'     spread <- top_ask - top_bid
#'     spread_bps <- (spread / top_bid) * 10000  # In basis points

#'     return(list(spread = spread, spread_bps = spread_bps))
#'   }
#'   ```
#'
#' - **Optimal Order Placement**: Determine optimal order placement to minimise market impact:
#'   ```r
#'   suggest_limit_price <- function(orderbook_dt, side, urgency = "low") {
#'     if (side == "buy") {
#'       if (urgency == "low") {
#'         # Passive placement just above best bid
#'         return(orderbook_dt[side == "bid", max(price)] + min_tick)
#'       } else if (urgency == "medium") {
#'         # Mid-spread placement
#'         best_bid <- orderbook_dt[side == "bid", max(price)]
#'         best_ask <- orderbook_dt[side == "ask", min(price)]
#'         return(best_bid + (best_ask - best_bid) / 2)
#'       } else {
#'         # Aggressive placement at best ask
#'         return(orderbook_dt[side == "ask", min(price)])
#'       }
#'     } else {
#'       # Similar logic for sell orders
#'       # ...
#'     }
#'   }
#'   ```
#'
#' @examples
#' \dontrun{
#' main_async <- coro::async(function() {
#'   # Get orderbook with 20 levels for BTC-USDT
#'   orderbook_20 <- await(get_part_orderbook_impl(symbol = "BTC-USDT", size = 20))
#'   
#'   # Print the first 5 bids and asks
#'   print("First 5 Bids:")
#'   print(orderbook_20[side == "bid"][1:5])
#'   
#'   print("First 5 Asks:")
#'   print(orderbook_20[side == "ask"][1:5])
#'   
#'   # Calculate the bid-ask spread
#'   top_bid <- orderbook_20[side == "bid", max(price)]
#'   top_ask <- orderbook_20[side == "ask", min(price)]
#'   spread <- top_ask - top_bid
#'   spread_pct <- spread / top_bid * 100
#'   
#'   cat("Current Spread:", spread, "(", sprintf("%.4f%%", spread_pct), ")\n")
#'   
#'   # Get a deeper orderbook with 100 levels
#'   orderbook_100 <- await(get_part_orderbook_impl(symbol = "BTC-USDT", size = 100))
#'   cat("Total number of price levels in 100-level orderbook:", nrow(orderbook_100), "\n")
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
        requested_size <- rlang::arg_match0(as.character(size), c("20", "100"))

        # Construct query string and full URL.
        qs <- build_query(list(symbol = symbol))
        endpoint <- paste0("/api/v1/market/orderbook/level2_", requested_size)
        url <- paste0(base_url, endpoint, qs)

        # Send the GET request with a 10-second timeout.
        response <- httr::GET(url, httr::timeout(10))
        # saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_part_orderbook_impl.ignore.Rds")

        # Process and validate the response.
        parsed_response <- process_kucoin_response(response, url)
        # saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_part_orderbook_impl.Rds")

        data_obj <- parsed_response$data

        # Create a data.table for bids.
        bids_dt <- data.table::rbindlist(lapply(data_obj$bids, function(x) {
            return(data.table::data.table(
                price = as.numeric(x[1]),
                size = as.numeric(x[2]),
                side = "bid"
            ))
        }))

        # Create a data.table for asks.
        asks_dt <- data.table::rbindlist(lapply(data_obj$asks, function(x) {
            return(data.table::data.table(
                price = as.numeric(x[1]),
                size = as.numeric(x[2]),
                side = "ask"
            ))
        }))

        # Combine the bids and asks into a single data.table.
        orderbook_dt <- data.table::rbindlist(list(bids_dt, asks_dt))

        # Append global snapshot fields.
        orderbook_dt[, time := as.numeric(data_obj$time)]
        orderbook_dt[, sequence := as.numeric(data_obj$sequence)]
        orderbook_dt[, time_datetime := time_convert_from_kucoin(data_obj$time, "ms")]

        # Reorder columns to move global fields to the front.
        data.table::setcolorder(orderbook_dt, c("time_datetime", "time", "sequence", "side", "price", "size"))

        # Sort bids in descending order by price (highest first) and asks in ascending order (lowest first)
        # orderbook_dt <- orderbook_dt[order(side, data.table::fifelse(side == "bid", -price, price))]

        # First sort all rows by side
        data.table::setorder(orderbook_dt, side)

        # Then sort bids in descending order 
        orderbook_dt[side == "bid", data.table::setorder(.SD, -price)]

        # And sort asks in ascending order
        orderbook_dt[side == "ask", data.table::setorder(.SD, price)]

        return(orderbook_dt[])
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

#' Get 24-Hour Statistics
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

#' Get Market List
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

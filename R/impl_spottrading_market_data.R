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
        saveRDS(response, "../../api-responses/impl_spottrading_market_data/response-get_currency_impl.Rds")

        # Process the response and extract the 'data' field
        parsed_response <- process_kucoin_response(response, url)
        saveRDS(parsed_response, "../../api-responses/impl_spottrading_market_data/parsed_response-get_currency_impl.Rds")

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

        # Convert the resulting data (a named list) into a data.table and return it
        summary_fields_vals <- data_obj[c(
            "currency", "name", "fullName", "precision", # "confirms", "contractAddress", use the confirms/contractAddress from chain items
            "isMarginEnabled", "isDebitEnabled"
        )]

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

        data.table::setcolorder(result_dt, c(
            "currency", "name", "fullName", "precision", "isMarginEnabled",
            "isDebitEnabled", "chainName", "withdrawalMinSize", "depositMinSize",
            "withdrawFeeRate", "withdrawalMinFee", "isWithdrawEnabled",
            "isDepositEnabled", "confirms", "preConfirms", "contractAddress",
            "withdrawPrecision", "maxWithdraw", "maxDeposit", "needTag", "chainId"
        ))

        return(result_dt[])
    }, error = function(e) {
        rlang::abort(paste("Error in get_currency_impl:", conditionMessage(e)))
    })
})

#' Get All Currencies
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

#' Get Symbol
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

#' Get All Symbols
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

#' Get Ticker
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

#' Get All Tickers
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

#' Get Trade History
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

#' Get Part OrderBook
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

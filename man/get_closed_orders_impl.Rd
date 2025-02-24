% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_orders_get_x.R
\name{get_closed_orders_impl}
\alias{get_closed_orders_impl}
\title{Get Closed Orders (Implementation)}
\usage{
get_closed_orders_impl(
  keys = get_api_keys(),
  base_url = get_base_url(),
  symbol,
  side = NULL,
  type = NULL,
  startAt = NULL,
  endAt = NULL,
  limit = 20,
  max_pages = Inf,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{keys}{List; API configuration parameters from \code{get_api_keys()}. Defaults to \code{get_api_keys()}.}

\item{base_url}{Character string; base URL for the KuCoin API. Defaults to \code{get_base_url()}.}

\item{symbol}{Character string; the trading pair symbol (e.g., "BTC-USDT"). Required.}

\item{side}{Character string; optional filter for order side: "buy" or "sell".}

\item{type}{Character string; optional filter for order type: "limit" or "market".}

\item{startAt}{Numeric; optional start time in milliseconds.}

\item{endAt}{Numeric; optional end time in milliseconds.}

\item{limit}{Integer; number of orders per page (1 to 100, default 20).}

\item{max_pages}{Numeric; maximum number of pages to fetch (default \code{Inf}).}
}
\value{
Promise resolving to a \code{data.table} with columns:
\itemize{
\item \code{id} (character): Unique order ID.
\item \code{clientOid} (character): Client-assigned order ID.
\item \code{symbol} (character): Trading pair.
\item \code{opType} (character): Operation type.
\item \code{type} (character): Order type ("limit" or "market").
\item \code{side} (character): Order side ("buy" or "sell").
\item \code{price} (character): Order price.
\item \code{size} (character): Order size.
\item \code{funds} (character): Order funds.
\item \code{dealSize} (character): Filled quantity.
\item \code{dealFunds} (character): Filled funds.
\item \code{remainSize} (character): Remaining quantity.
\item \code{remainFunds} (character): Remaining funds.
\item \code{cancelledSize} (character): Canceled quantity.
\item \code{cancelledFunds} (character): Canceled funds.
\item \code{fee} (character): Handling fees.
\item \code{feeCurrency} (character): Fee currency.
\item \code{stp} (character or NA): Self Trade Prevention strategy.
\item \code{timeInForce} (character): Time in force.
\item \code{postOnly} (logical): Post-only flag.
\item \code{hidden} (logical): Hidden order flag.
\item \code{iceberg} (logical): Iceberg order flag.
\item \code{visibleSize} (character): Visible size for iceberg orders.
\item \code{cancelAfter} (integer): Seconds until cancellation for GTT.
\item \code{channel} (character): Order channel.
\item \code{remark} (character or NA): Order remarks.
\item \code{tags} (character or NA): Order tags.
\item \code{cancelExist} (logical): Indicates a cancellation record.
\item \code{tradeType} (character): Trade type.
\item \code{inOrderBook} (logical): Whether in the order book.
\item \code{tax} (character): Tax information.
\item \code{active} (logical): Order status (false for closed orders).
\item \code{createdAt} (numeric): Creation timestamp (milliseconds).
\item \code{lastUpdatedAt} (numeric): Last update timestamp (milliseconds).
\item \code{createdAtDatetime} (POSIXct): Creation time in UTC.
\item \code{lastUpdatedAtDatetime} (POSIXct): Last update time in UTC.
}
}
\description{
Retrieves all closed spot orders for a specified symbol from the KuCoin Spot trading system asynchronously.
This function supports pagination and returns a \code{data.table} with detailed information about each closed order,
sorted by the latest update time in descending order.
}
\details{
\subsection{Description}{

This endpoint fetches all closed orders (canceled or fully filled) for a given trading pair (e.g., "BTC-USDT").
The orders are returned in descending order based on their last update time. The function handles pagination
using the \code{lastId} parameter to fetch multiple pages of results, with data availability limited to the last
72 hours by default if no time range is specified beyond that period.
}

\subsection{Workflow}{
\enumerate{
\item \strong{Parameter Validation}: Ensures \code{symbol} is a valid trading pair and \code{limit} is an integer between 1 and 100.
\item \strong{Request Construction}: Builds the API endpoint with query parameters including \code{symbol}, \code{side}, \code{type}, \code{startAt}, \code{endAt}, and \code{limit}.
\item \strong{Authentication}: Generates private API headers using \code{build_headers()} with the GET method and endpoint.
\item \strong{API Request}: Sends asynchronous GET requests to fetch pages of closed orders until no more orders are returned or \code{max_pages} is reached.
\item \strong{Response Processing}: Combines the fetched orders into a single \code{data.table} and adds \code{createdAtDatetime} and \code{lastUpdatedAtDatetime} columns using \code{time_convert_from_kucoin()}.
}
}

\subsection{API Details}{
\itemize{
\item \strong{Endpoint}: \verb{GET https://api.kucoin.com/api/v1/hf/orders/done}
\item \strong{Domain}: Spot
\item \strong{API Channel}: Private
\item \strong{API Permission}: General
\item \strong{Rate Limit Pool}: Spot
\item \strong{Rate Limit Weight}: 2
\item \strong{SDK Service}: Spot
\item \strong{SDK Sub-Service}: Order
\item \strong{SDK Method Name}: getClosedOrders
\item \strong{Official Documentation}: \href{https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-closed-orders}{KuCoin Get Closed Orders}
}
}

\subsection{Request}{
\subsection{Query Parameters}{
\itemize{
\item \code{symbol}: String (required) - The trading pair symbol (e.g., "BTC-USDT").
\item \code{side}: Enum\if{html}{\out{<String>}} (optional) - Order side: "buy" or "sell".
\item \code{type}: Enum\if{html}{\out{<String>}} (optional) - Order type: "limit" or "market".
\item \code{lastId}: Integer\if{html}{\out{<int64>}} (optional) - The ID of the last order from the previous batch for pagination.
\item \code{limit}: Integer (optional) - Number of orders per page (default 20, max 100).
\item \code{startAt}: Integer\if{html}{\out{<int64>}} (optional) - Start time in milliseconds.
\item \code{endAt}: Integer\if{html}{\out{<int64>}} (optional) - End time in milliseconds.
}
}

\subsection{Example Request}{

\if{html}{\out{<div class="sourceCode bash">}}\preformatted{curl --location --request GET 'https://api.kucoin.com/api/v1/hf/orders/done?symbol=BTC-USDT&side=buy&type=limit&lastId=254062248624417&limit=20&startAt=1728663338000&endAt=1728692138000'
}\if{html}{\out{</div>}}
}

}

\subsection{Response}{
\subsection{HTTP Code: 200}{
\itemize{
\item \strong{Content Type}: \code{application/json}
}
}

\subsection{Data Schema}{
\itemize{
\item \code{code}: String (required) - Response code ("200000" indicates success).
\item \code{data}: Object (required) - Contains:
\itemize{
\item \code{lastId}: Integer\if{html}{\out{<int64>}} (required) - The ID for the next page of data.
\item \code{items}: Array of objects (required) - List of closed orders, each with fields:
\itemize{
\item \code{id}: String - Unique order ID.
\item \code{clientOid}: String - Client-assigned order ID.
\item \code{symbol}: String - Trading pair.
\item \code{opType}: String - Operation type.
\item \code{type}: Enum\if{html}{\out{<String>}} - Order type: "limit" or "market".
\item \code{side}: Enum\if{html}{\out{<String>}} - Order side: "buy" or "sell".
\item \code{price}: String - Order price.
\item \code{size}: String - Order size.
\item \code{funds}: String - Order funds.
\item \code{dealSize}: String - Filled quantity.
\item \code{dealFunds}: String - Filled funds.
\item \code{remainSize}: String - Remaining quantity.
\item \code{remainFunds}: String - Remaining funds.
\item \code{cancelledSize}: String - Canceled quantity.
\item \code{cancelledFunds}: String - Canceled funds.
\item \code{fee}: String - Handling fees.
\item \code{feeCurrency}: String - Fee currency.
\item \code{stp}: Enum\if{html}{\out{<String>}} - Self Trade Prevention: "DC", "CO", "CN", "CB" or NA.
\item \code{timeInForce}: Enum\if{html}{\out{<String>}} - Time in force: "GTC", "GTT", "IOC", "FOK".
\item \code{postOnly}: Boolean - Post-only flag.
\item \code{hidden}: Boolean - Hidden order flag.
\item \code{iceberg}: Boolean - Iceberg order flag.
\item \code{visibleSize}: String - Visible size for iceberg orders.
\item \code{cancelAfter}: Integer - Seconds until cancellation for GTT.
\item \code{channel}: String - Order channel.
\item \code{remark}: String or NA - Order remarks.
\item \code{tags}: String or NA - Order tags.
\item \code{cancelExist}: Boolean - Indicates a cancellation record.
\item \code{tradeType}: String - Trade type.
\item \code{inOrderBook}: Boolean - Whether in the order book.
\item \code{tax}: String - Tax information.
\item \code{active}: Boolean - Order status (false for closed orders).
\item \code{createdAt}: Integer\if{html}{\out{<int64>}} - Creation timestamp in milliseconds.
\item \code{lastUpdatedAt}: Integer\if{html}{\out{<int64>}} - Last update timestamp in milliseconds.
}
}
}
}

\subsection{JSON Response Example}{

\if{html}{\out{<div class="sourceCode json">}}\preformatted{\{
  "code": "200000",
  "data": \{
    "lastId": 19814995255305,
    "items": [
      \{
        "id": "6717422bd51c29000775ea03",
        "clientOid": "5c52e11203aa677f33e493fb",
        "symbol": "BTC-USDT",
        "opType": "DEAL",
        "type": "limit",
        "side": "buy",
        "price": "70000",
        "size": "0.00001",
        "funds": "0.7",
        "dealSize": "0.00001",
        "dealFunds": "0.677176",
        "remainSize": "0",
        "remainFunds": "0.022824",
        "cancelledSize": "0",
        "cancelledFunds": "0",
        "fee": "0.000677176",
        "feeCurrency": "USDT",
        "stp": null,
        "timeInForce": "GTC",
        "postOnly": false,
        "hidden": false,
        "iceberg": false,
        "visibleSize": "0",
        "cancelAfter": 0,
        "channel": "API",
        "remark": "order remarks",
        "tags": null,
        "cancelExist": false,
        "tradeType": "TRADE",
        "inOrderBook": false,
        "active": false,
        "tax": "0",
        "createdAt": 1729577515444,
        "lastUpdatedAt": 1729577515481
      \}
    ]
  \}
\}
}\if{html}{\out{</div>}}
}

}
}
\examples{
\dontrun{
library(coro)
library(data.table)

main_async <- coro::async(function() {
  # Retrieve closed orders for BTC-USDT
  closed_orders <- await(get_closed_orders_impl(
    symbol = "BTC-USDT",
    side = "buy",
    type = "limit",
    startAt = 1728663338000,
    endAt = 1728692138000,
    limit = 50,
    max_pages = 2
  ))
  print(closed_orders)
})

# Run the async function
main_async()
while (!later::loop_empty()) later::run_now()
}
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_orders_get_order_by.R
\name{get_order_by_order_id_impl}
\alias{get_order_by_order_id_impl}
\title{Get Order By OrderId (Implementation)}
\usage{
get_order_by_order_id_impl(
  keys = get_api_keys(),
  base_url = get_base_url(),
  orderId,
  symbol,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{keys}{List; API configuration parameters from \code{get_api_keys()}. Defaults to \code{get_api_keys()}.}

\item{base_url}{Character string; base URL for the KuCoin API. Defaults to \code{get_base_url()}.}

\item{orderId}{Character string; the unique order ID to retrieve (e.g., "6717422bd51c29000775ea03"). Required.}

\item{symbol}{Character string; the trading pair symbol (e.g., "BTC-USDT"). Required.}
}
\value{
Promise resolving to a \code{data.table} with one row containing order details, including:
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
\item \code{cancelledSize} (character): Canceled quantity.
\item \code{cancelledFunds} (character): Canceled funds.
\item \code{remainSize} (character): Remaining quantity.
\item \code{remainFunds} (character): Remaining funds.
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
\item \code{active} (logical): Order status (true = active, false = done).
\item \code{tax} (character): Tax information.
\item \code{createdAt} (integer): Creation timestamp (milliseconds).
\item \code{lastUpdatedAt} (integer): Last update timestamp (milliseconds).
\item \code{createdAtDatetime} (POSIXct): Creation time in UTC.
\item \code{lastUpdatedAtDatetime} (POSIXct): Last update time in UTC.
}
}
\description{
Retrieves detailed information for a single spot order using its order ID from the KuCoin Spot trading system asynchronously.
This function returns a \code{data.table} with comprehensive order details, including additional UTC datetime columns derived from timestamps.
}
\details{
\subsection{Description}{

This endpoint fetches data for a specific spot order identified by its \code{orderId}. The order can be in an active or done state:
\itemize{
\item \strong{Active Orders}: Orders currently in the order book (check \code{inOrderBook} to confirm).
\item \strong{Done Orders}: Orders that are canceled or fully filled (data available only within 3 * 24 hours from the current time).
}

If the order is not active and exceeds the 3 * 24-hour window, the API defaults to querying within that timeframe, potentially returning no data if outside the range.
}

\subsection{Workflow}{
\enumerate{
\item \strong{Parameter Validation}: Ensures \code{orderId} and \code{symbol} are non-empty strings, with \code{symbol} validated as a trading pair.
\item \strong{Request Construction}: Builds the endpoint URL with \code{orderId} in the path and \code{symbol} as a query parameter.
\item \strong{Authentication}: Generates private API headers using \code{build_headers()} with the GET method and endpoint.
\item \strong{API Request}: Sends a GET request to the KuCoin API with a 3-second timeout.
\item \strong{Response Processing}: Parses the response, converts the \code{data} object to a \code{data.table}, and adds \code{createdAtDatetime} and \code{lastUpdatedAtDatetime} columns.
}
}

\subsection{API Details}{
\itemize{
\item \strong{Endpoint}: \verb{GET https://api.kucoin.com/api/v1/hf/orders/\{orderId\}?symbol=\{symbol\}}
\item \strong{Domain}: Spot
\item \strong{API Channel}: Private
\item \strong{API Permission}: General
\item \strong{Rate Limit Pool}: Spot
\item \strong{Rate Limit Weight}: 2
\item \strong{SDK Service}: Spot
\item \strong{SDK Sub-Service}: Order
\item \strong{SDK Method Name}: getOrderByOrderId
\item \strong{Official Documentation}: \href{https://www.kucoin.com/docs-new/rest/spot-trading/orders/get-order-by-orderld}{KuCoin Get Order By OrderId}
}
}

\subsection{Request}{
\subsection{Path Parameters}{
\itemize{
\item \code{orderId}: String (required) - The unique order ID generated by the trading system (e.g., "6717422bd51c29000775ea03").
}
}

\subsection{Query Parameters}{
\itemize{
\item \code{symbol}: String (required) - The trading pair symbol (e.g., "BTC-USDT").
}
}

\subsection{Example Request}{

\if{html}{\out{<div class="sourceCode bash">}}\preformatted{curl --location --request GET 'https://api.kucoin.com/api/v1/hf/orders/6717422bd51c29000775ea03?symbol=BTC-USDT'
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
\item \code{data}: Object (required) - Order details with the following fields:
\itemize{
\item \code{id}: String (required) - Unique order ID.
\item \code{clientOid}: String (required) - Client-assigned order ID.
\item \code{symbol}: String (required) - Trading pair (e.g., "BTC-USDT").
\item \code{opType}: String (required) - Operation type.
\item \code{type}: Enum\if{html}{\out{<String>}} (required) - Order type: "limit" or "market".
\item \code{side}: Enum\if{html}{\out{<String>}} (required) - Order side: "buy" or "sell".
\item \code{price}: String (required) - Order price.
\item \code{size}: String (required) - Order size.
\item \code{funds}: String (required) - Order funds.
\item \code{dealSize}: String (required) - Filled quantity.
\item \code{dealFunds}: String (required) - Filled funds.
\item \code{cancelledSize}: String (required) - Canceled quantity.
\item \code{cancelledFunds}: String (required) - Canceled funds.
\item \code{remainSize}: String (required) - Remaining quantity.
\item \code{remainFunds}: String (required) - Remaining funds.
\item \code{fee}: String (required) - Handling fees.
\item \code{feeCurrency}: String (required) - Fee currency.
\item \code{stp}: Enum\if{html}{\out{<String>}} (optional) - Self Trade Prevention: "DC", "CO", "CN", "CB".
\item \code{timeInForce}: Enum\if{html}{\out{<String>}} (required) - Time in force: "GTC", "GTT", "IOC", "FOK".
\item \code{postOnly}: Boolean (required) - Post-only flag.
\item \code{hidden}: Boolean (required) - Hidden order flag.
\item \code{iceberg}: Boolean (required) - Iceberg order flag.
\item \code{visibleSize}: String (required) - Visible size for iceberg orders.
\item \code{cancelAfter}: Integer (required) - Seconds until cancellation for GTT.
\item \code{channel}: String (required) - Order channel.
\item \code{remark}: String (optional) - Order remarks.
\item \code{tags}: String (optional) - Order tags.
\item \code{cancelExist}: Boolean (required) - Indicates a cancellation record.
\item \code{tradeType}: String (required) - Trade type (redundant parameter).
\item \code{inOrderBook}: Boolean (required) - Whether the order is in the order book.
\item \code{active}: Boolean (required) - Order status (true = active, false = done).
\item \code{tax}: String (required) - Tax information (for certain regions).
\item \code{createdAt}: Integer\if{html}{\out{<int64>}} (required) - Creation timestamp in milliseconds.
\item \code{lastUpdatedAt}: Integer\if{html}{\out{<int64>}} (required) - Last update timestamp in milliseconds.
}
}
}

\subsection{JSON Response Example}{

\if{html}{\out{<div class="sourceCode json">}}\preformatted{\{
  "code": "200000",
  "data": \{
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
  # Retrieve order details
  order_details <- await(get_order_by_order_id_impl(
    orderId = "6717422bd51c29000775ea03",
    symbol = "BTC-USDT"
  ))
  print(order_details)
})

# Run the async function
main_async()
while (!later::loop_empty()) later::run_now()
}

# Expected Output (simplified):
#    id                    clientOid symbol opType type  side price size  ... createdAtDatetime   lastUpdatedAtDatetime
# 1: 6717422bd51c29000775ea03 5c52e11203aa677f33e493fb BTC-USDT DEAL limit buy  70000 0.00001 ... 2023-10-22 03:31:55 2023-10-22 03:31:55
}

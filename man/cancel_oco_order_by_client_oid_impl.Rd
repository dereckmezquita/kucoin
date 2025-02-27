% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_orders_oco.R
\name{cancel_oco_order_by_client_oid_impl}
\alias{cancel_oco_order_by_client_oid_impl}
\title{Cancel OCO Order By ClientOid (Implementation)}
\usage{
cancel_oco_order_by_client_oid_impl(
  keys = get_api_keys(),
  base_url = get_base_url(),
  clientOid,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{keys}{List; API configuration parameters from \code{get_api_keys()}. Defaults to \code{get_api_keys()}.}

\item{base_url}{Character string; base URL for the KuCoin API. Defaults to \code{get_base_url()}.}

\item{clientOid}{Character string; the unique client order ID to cancel (e.g., "5c52e11203aa67f1e493fb"). Required.}
}
\value{
Promise resolving to a \code{data.table} with one row containing:
\itemize{
\item \code{cancelledOrderIds} (list): A list of two character strings representing the IDs of the canceled limit and stop-limit orders.
}
}
\description{
Cancels an existing OCO order on the KuCoin Spot trading system using its client-assigned order ID (\code{clientOid}) asynchronously by sending a DELETE request to the \verb{/api/v3/oco/client-order/\{clientOid\}} endpoint.
}
\details{
\subsection{What is an OCO Order?}{

An OCO (One-Cancels-the-Other) order links a limit order (profit target) with a stop-limit order (loss limit). Canceling by \code{clientOid} allows:
\itemize{
\item \strong{Custom Tracking}: Use your unique ID to cancel without needing the system \code{orderId}, ideal for systems tracking orders locally.
\item \strong{Flexibility}: Adjust strategies when market trends shift unexpectedly (e.g., canceling an OCO if a breakout is anticipated).
\item \strong{Error Handling}: Quickly remove an OCO order if set incorrectly, such as wrong price levels.
For example, if an OCO order was placed with a \code{clientOid} to sell BTC at $55,000 or $48,000 but you detect a potential rally, you might cancel it using your custom ID.
}
}

\subsection{Description}{

This function initiates the cancellation of an OCO order identified by its \code{clientOid}, returning a \code{data.table} with the IDs of the canceled limit and stop-limit orders.
}

\subsection{Workflow}{
\enumerate{
\item \strong{Parameter Validation}: Ensures \code{clientOid} is a non-empty string.
\item \strong{Request Construction}: Constructs the endpoint URL by embedding \code{clientOid} as a path parameter.
\item \strong{Authentication}: Generates private API headers using \code{build_headers()} with the DELETE method and endpoint.
\item \strong{API Request}: Sends a DELETE request to the KuCoin API with a 3-second timeout via \code{httr::DELETE}.
\item \strong{Response Processing}: Parses the response, confirms success ("200000"), and converts the \code{cancelledOrderIds} array to a \code{data.table} column as a list.
}
}

\subsection{API Details}{
\itemize{
\item \strong{Endpoint}: \verb{DELETE https://api.kucoin.com/api/v3/oco/client-order/\{clientOid\}}
\item \strong{Domain}: Spot
\item \strong{API Channel}: Private
\item \strong{API Permission}: Spot
\item \strong{Rate Limit Pool}: Spot
\item \strong{Rate Limit Weight}: 3
\item \strong{SDK Service}: Spot
\item \strong{SDK Sub-Service}: Order
\item \strong{SDK Method Name}: cancelOcoOrderByClientOid
\item \strong{Official Documentation}: \href{https://www.kucoin.com/docs-new/rest/spot-trading/orders/cancel-oco-order-by-clientoid}{KuCoin Cancel OCO Order By ClientOid}
}
}

\subsection{Request}{
\subsection{Path Parameters}{
\itemize{
\item \code{clientOid}: String (required) - Unique client order ID created by the user (e.g., "5c52e11203aa67f1e493fb").
}
}

\subsection{Example Request}{

\if{html}{\out{<div class="sourceCode bash">}}\preformatted{curl --location --request DELETE 'https://api.kucoin.com/api/v3/oco/client-order/5c52e11203aa67f1e493fb'
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
\item \code{cancelledOrderIds}: Array\link{String} (required) - List of two order IDs related to the canceled OCO order (limit and stop-limit components).
}
}
}

\subsection{JSON Response Example}{

\if{html}{\out{<div class="sourceCode json">}}\preformatted{\{
  "code": "200000",
  "data": \{
    "cancelledOrderIds": [
      "vs93gpqc6r0mkk57003gok3h",
      "vs93gpqc6r0mkk57003gok3i"
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
  # Cancel an OCO order by clientOid
  canceled_orders <- await(cancel_oco_order_by_client_oid_impl(
    clientOid = "5c52e11203aa67f1e493fb"
  ))
  print(canceled_orders)
})

# Run the async function
main_async()
while (!later::loop_empty()) later::run_now()
}
}

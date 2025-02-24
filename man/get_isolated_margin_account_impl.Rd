% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_account_account_and_funding.R
\name{get_isolated_margin_account_impl}
\alias{get_isolated_margin_account_impl}
\title{Retrieve Isolated Margin Account Information (Implementation)}
\usage{
get_isolated_margin_account_impl(
  keys = get_api_keys(),
  base_url = get_base_url(),
  query = list(),
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{keys}{List containing API configuration parameters from \code{get_api_keys()}, including:
\itemize{
\item \code{api_key}: Character string; your KuCoin API key.
\item \code{api_secret}: Character string; your KuCoin API secret.
\item \code{api_passphrase}: Character string; your KuCoin API passphrase.
\item \code{key_version}: Character string; API key version (e.g., \code{"2"}).
Defaults to \code{get_api_keys()}.
}}

\item{base_url}{Character string representing the base URL for the API. Defaults to \code{get_base_url()}.}

\item{query}{Named list of query parameters:
\itemize{
\item \code{symbol} (character, optional): Trading pair (e.g., \code{"BTC-USDT"}).
\item \code{quoteCurrency} (character, optional): Quote currency (e.g., \code{"USDT"}, \code{"KCS"}, \code{"BTC"}; default \code{"USDT"}).
\item \code{queryType} (character, optional): Type (\code{"ISOLATED"}, \code{"ISOLATED_V2"}, \code{"ALL"}; default \code{"ISOLATED"}).
}}
}
\value{
Promise resolving to a named list containing:
\itemize{
\item \code{summary}: \code{data.table} with:
\itemize{
\item \code{totalAssetOfQuoteCurrency} (character): Total assets.
\item \code{totalLiabilityOfQuoteCurrency} (character): Total liabilities.
\item \code{timestamp} (integer): Timestamp in milliseconds.
\item \code{datetime} (POSIXct): Converted datetime.
}
\item \code{assets}: \code{data.table} with:
\itemize{
\item \code{symbol} (character): Trading pair.
\item \code{status} (character): Position status.
\item \code{debtRatio} (character): Debt ratio.
\item \code{base_currency} (character): Base currency code.
\item \code{base_borrowEnabled} (logical): Base borrowing enabled.
\item \code{base_transferInEnabled} (logical): Base transfer-in enabled.
\item \code{base_liability} (character): Base liability.
\item \code{base_total} (character): Base total funds.
\item \code{base_available} (character): Base available funds.
\item \code{base_hold} (character): Base funds on hold.
\item \code{base_maxBorrowSize} (character): Base max borrowable.
\item \code{quote_currency} (character): Quote currency code.
\item \code{quote_borrowEnabled} (logical): Quote borrowing enabled.
\item \code{quote_transferInEnabled} (logical): Quote transfer-in enabled.
\item \code{quote_liability} (character): Quote liability.
\item \code{quote_total} (character): Quote total funds.
\item \code{quote_available} (character): Quote available funds.
\item \code{quote_hold} (character): Quote funds on hold.
\item \code{quote_maxBorrowSize} (character): Quote max borrowable.
}
}
}
\description{
Fetches isolated margin account details from the KuCoin API asynchronously for specific trading pairs. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, segregating collateral by pair.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{URL Construction}: Combines the base URL (from \code{get_base_url()} or provided \code{base_url}) with \verb{/api/v3/isolated/accounts} and a query string from \code{build_query()}.
\item \strong{Header Preparation}: Constructs authentication headers using \code{build_headers()}.
\item \strong{API Request}: Sends a GET request with a 3-second timeout via \code{httr::GET()}.
\item \strong{Response Processing}: Processes the response with \code{process_kucoin_response()}, converting the \code{"data"} field into \code{summary} and flattened \code{assets} \code{data.table} objects, adding a \code{datetime} column.
}
}

\subsection{API Endpoint}{

\verb{GET https://api.kucoin.com/api/v3/isolated/accounts}
}

\subsection{Usage}{

Utilised internally by \code{KucoinAccountAndFunding} to provide isolated margin account data.
}

\subsection{Official Documentation}{

\href{https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-isolated-margin}{KuCoin Get Account Isolated Margin}
}
}
\examples{
\dontrun{
keys <- get_api_keys()
base_url <- "https://api.kucoin.com"
query <- list(symbol = "BTC-USDT", quoteCurrency = "USDT")
main_async <- coro::async(function() {
  result <- await(get_isolated_margin_account_impl(keys = keys, base_url = base_url, query = query))
  print(result$summary)
  print(result$assets)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

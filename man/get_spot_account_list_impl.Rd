% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_account_account_and_funding.R
\name{get_spot_account_list_impl}
\alias{get_spot_account_list_impl}
\title{Retrieve Spot Account List (Implementation)}
\usage{
get_spot_account_list_impl(
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

\item{query}{Named list of query parameters, e.g., \code{list(currency = "USDT", type = "main")}. Supported:
\itemize{
\item \code{currency} (character, optional): Filter by currency (e.g., \code{"USDT"}).
\item \code{type} (character, optional): Filter by account type (\code{"main"}, \code{"trade"}).
}}
}
\value{
Promise resolving to a \code{data.table} containing:
\itemize{
\item \code{id} (character): Account ID.
\item \code{currency} (character): Currency code.
\item \code{type} (character): Account type (e.g., \code{"main"}, \code{"trade"}).
\item \code{balance} (numeric): Total funds.
\item \code{available} (numeric): Available funds.
\item \code{holds} (numeric): Funds on hold.
}
}
\description{
Fetches a list of spot accounts from the KuCoin API asynchronously with optional filters. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, returning financial metrics in a \code{data.table}.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{URL Construction}: Combines the base URL (from \code{get_base_url()} or provided \code{base_url}) with \verb{/api/v1/accounts} and a query string from \code{build_query()}.
\item \strong{Header Preparation}: Constructs authentication headers using \code{build_headers()}.
\item \strong{API Request}: Sends a GET request with a 3-second timeout via \code{httr::GET()}.
\item \strong{Response Processing}: Processes the response with \code{process_kucoin_response()}, converts the \code{"data"} array into a \code{data.table}, and handles empty responses with a typed empty table.
}
}

\subsection{API Endpoint}{

\verb{GET https://api.kucoin.com/api/v1/accounts}
}

\subsection{Usage}{

Utilised internally by \code{KucoinAccountAndFunding} to list spot accounts.
}

\subsection{Official Documentation}{

\href{https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-list-spot}{KuCoin Get Account List Spot}
}
}
\examples{
\dontrun{
keys <- get_api_keys()
base_url <- "https://api.kucoin.com"
query <- list(currency = "USDT", type = "main")
main_async <- coro::async(function() {
  dt <- await(get_spot_account_list_impl(keys = keys, base_url = base_url, query = query))
  print(dt)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

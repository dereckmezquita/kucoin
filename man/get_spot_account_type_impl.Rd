% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_account_account_and_funding.R
\name{get_spot_account_type_impl}
\alias{get_spot_account_type_impl}
\title{Determine Spot Account Type (Implementation)}
\usage{
get_spot_account_type_impl(
  keys = get_api_keys(),
  base_url = get_base_url(),
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
}
\value{
Promise resolving to a logical value: \code{TRUE} for high-frequency, \code{FALSE} for low-frequency.
}
\description{
Determines whether the spot account is high-frequency or low-frequency from the KuCoin API asynchronously. This internal function is designed for use within an R6 class and is not intended for direct end-user consumption, impacting asset transfer endpoints.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{URL Construction}: Combines the base URL (from \code{get_base_url()} or provided \code{base_url}) with the endpoint \verb{/api/v1/hf/accounts/opened}.
\item \strong{Header Preparation}: Constructs authentication headers using \code{build_headers()}.
\item \strong{API Request}: Sends a GET request with a 3-second timeout via \code{httr::GET()}.
\item \strong{Response Processing}: Processes the response with \code{process_kucoin_response()} and extracts the boolean \code{"data"} field indicating account type.
}
}

\subsection{API Endpoint}{

\verb{GET https://api.kucoin.com/api/v1/hf/accounts/opened}
}

\subsection{Usage}{

Utilised internally by \code{KucoinAccountAndFunding} to ascertain spot account frequency.
}

\subsection{Official Documentation}{

\href{https://www.kucoin.com/docs-new/rest/account-info/account-funding/get-account-type-spot}{KuCoin Get Account Type Spot}
}
}
\examples{
\dontrun{
keys <- get_api_keys()
base_url <- "https://api.kucoin.com"
main_async <- coro::async(function() {
  is_high_freq <- await(get_spot_account_type_impl(keys = keys, base_url = base_url))
  print(is_high_freq)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

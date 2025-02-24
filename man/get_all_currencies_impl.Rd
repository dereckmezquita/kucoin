% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_market_data.R
\name{get_all_currencies_impl}
\alias{get_all_currencies_impl}
\title{Get All Currencies (Implementation)}
\usage{
get_all_currencies_impl(
  base_url = get_base_url(),
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{base_url}{Character string; base URL for the KuCoin API. Defaults to \code{get_base_url()}.}
}
\value{
Promise resolving to a \code{data.table} containing:
\itemize{
\item \strong{Summary Fields}:
\itemize{
\item \code{currency} (character): Unique currency code.
\item \code{name} (character): Short name.
\item \code{fullName} (character): Full name.
\item \code{precision} (integer): Decimal places.
\item \code{confirms} (integer or NA): Block confirmations.
\item \code{contractAddress} (character or NA): Primary contract address.
\item \code{isMarginEnabled} (logical): Margin trading status.
\item \code{isDebitEnabled} (logical): Debit status.
}
\item \strong{Chain-Specific Fields}:
\itemize{
\item \code{chainName} (character or NA): Blockchain name.
\item \code{withdrawalMinSize} (character or NA): Minimum withdrawal amount.
\item \code{depositMinSize} (character or NA): Minimum deposit amount.
\item \code{withdrawFeeRate} (character or NA): Withdrawal fee rate.
\item \code{withdrawalMinFee} (character or NA): Minimum withdrawal fee.
\item \code{isWithdrawEnabled} (logical or NA): Withdrawal enabled status.
\item \code{isDepositEnabled} (logical or NA): Deposit enabled status.
\item \code{confirms} (integer or NA): Chain-specific confirmations.
\item \code{preConfirms} (integer or NA): Pre-confirmations.
\item \code{chain_contractAddress} (character or NA): Chain-specific contract address.
\item \code{withdrawPrecision} (integer or NA): Withdrawal precision.
\item \code{maxWithdraw} (character or NA): Maximum withdrawal amount.
\item \code{maxDeposit} (character or NA): Maximum deposit amount.
\item \code{needTag} (logical or NA): Memo/tag requirement.
\item \code{chainId} (character or NA): Blockchain identifier.
\item \code{depositFeeRate} (character or NA): Deposit fee rate.
\item \code{withdrawMaxFee} (character or NA): Maximum withdrawal fee.
\item \code{depositTierFee} (character or NA): Tiered deposit fee.
}
}
}
\description{
Retrieves a list of all currencies available on KuCoin asynchronously, combining summary and chain-specific details into a \code{data.table}.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{URL Assembly}: Combines \code{base_url} with \verb{/api/v3/currencies}.
\item \strong{HTTP Request}: Sends a GET request with a 10-second timeout via \code{httr::GET()}.
\item \strong{Response Processing}: Validates the response with \code{process_kucoin_response()} and extracts the \code{"data"} field.
\item \strong{Data Iteration}: Loops through each currency, extracting summary fields and chain data (if present).
\item \strong{Result Assembly}: Combines summary and chain data into a \code{data.table}, adding dummy chain columns with \code{NA} if no chains exist.
}
}

\subsection{API Endpoint}{

\verb{GET https://api.kucoin.com/api/v3/currencies}
}

\subsection{Usage}{

Utilised to fetch comprehensive currency details, including multi-chain support, for market analysis or configuration.
}

\subsection{Official Documentation}{

\href{https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-all-currencies}{KuCoin Get All Currencies}
}
}
\examples{
\dontrun{
main_async <- coro::async(function() {
  currencies <- await(get_all_currencies_impl())
  print(currencies)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

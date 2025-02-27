% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_market_data.R
\name{get_24hr_stats_impl}
\alias{get_24hr_stats_impl}
\title{Get 24-Hour Statistics (Implementation)}
\usage{
get_24hr_stats_impl(
  base_url = get_base_url(),
  symbol,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{base_url}{Character string; base URL for the KuCoin API. Defaults to \code{get_base_url()}.}

\item{symbol}{Character string; trading symbol (e.g., \code{"BTC-USDT"}).}
}
\value{
Promise resolving to a \code{data.table} containing:
\itemize{
\item \code{timestamp} (POSIXct): Snapshot timestamp in UTC.
\item \code{time_ms} (integer): Snapshot timestamp in milliseconds.
\item \code{symbol} (character): Trading symbol.
\item \code{buy} (character): Best bid price.
\item \code{sell} (character): Best ask price.
\item \code{changeRate} (character): 24-hour change rate.
\item \code{changePrice} (character): 24-hour price change.
\item \code{high} (character): 24-hour high price.
\item \code{low} (character): 24-hour low price.
\item \code{vol} (character): 24-hour trading volume.
\item \code{volValue} (character): 24-hour turnover.
\item \code{last} (character): Last traded price.
\item \code{averagePrice} (character): 24-hour average price.
\item \code{takerFeeRate} (character): Taker fee rate.
\item \code{makerFeeRate} (character): Maker fee rate.
\item \code{takerCoefficient} (character): Taker fee coefficient.
\item \code{makerCoefficient} (character): Maker fee coefficient.
}
}
\description{
Retrieves 24-hour market statistics for a specified trading symbol from the KuCoin API asynchronously.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{Query Construction}: Builds a query string with the \code{symbol} parameter using \code{build_query()}.
\item \strong{URL Assembly}: Combines \code{base_url}, \verb{/api/v1/market/stats}, and the query string.
\item \strong{HTTP Request}: Sends a GET request with a 10-second timeout via \code{httr::GET()}.
\item \strong{Response Processing}: Validates the response with \code{process_kucoin_response()} and extracts \code{"data"}.
\item \strong{Data Conversion}: Converts \code{"data"} to a \code{data.table}, renames \code{time} to \code{time_ms}, and adds a \code{timestamp} column via \code{time_convert_from_kucoin()}.
}
}

\subsection{API Endpoint}{

\verb{GET https://api.kucoin.com/api/v1/market/stats}
}

\subsection{Usage}{

Utilised to fetch a 24-hour snapshot of market statistics for a trading symbol, including volume and price changes.
}

\subsection{Official Documentation}{

\href{https://www.kucoin.com/docs-new/rest/spot-trading/market-data/get-24hr-stats}{KuCoin Get 24hr Stats}
}
}
\examples{
\dontrun{
main_async <- coro::async(function() {
  stats <- await(get_24hr_stats_impl(symbol = "BTC-USDT"))
  print(stats)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

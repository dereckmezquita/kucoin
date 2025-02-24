% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{verify_symbol}
\alias{verify_symbol}
\title{Verify Ticker Symbol Format}
\usage{
verify_symbol(ticker)
}
\arguments{
\item{ticker}{Character string representing the ticker symbol to verify.}
}
\value{
Logical; \code{TRUE} if the symbol is valid, \code{FALSE} otherwise.
}
\description{
Checks whether a ticker symbol adheres to the format \code{"BTC-USDT"}, consisting of uppercase alphanumeric characters separated by a dash.
}
\examples{
\dontrun{
verify_symbol("BTC-USDT")  # Returns TRUE
verify_symbol("btc-usdt")  # Returns FALSE
verify_symbol("BTC_USDT")  # Returns FALSE
}
}

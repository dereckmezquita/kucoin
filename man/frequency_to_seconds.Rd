% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/impl_spottrading_market_data_get_klines.R
\name{frequency_to_seconds}
\alias{frequency_to_seconds}
\title{Convert Frequency String to Seconds}
\usage{
frequency_to_seconds(freq)
}
\arguments{
\item{freq}{Character string representing the frequency (e.g., \code{"1min"}, \code{"1hour"}). Allowed values: \code{"1min"}, \code{"3min"}, \code{"5min"}, \code{"15min"}, \code{"30min"}, \code{"1hour"}, \code{"2hour"}, \code{"4hour"}, \code{"6hour"}, \code{"8hour"}, \code{"12hour"}, \code{"1day"}, \code{"1week"}, \code{"1month"}.}
}
\value{
Numeric value representing the duration in seconds.
}
\description{
Converts a KuCoin klines frequency string into its equivalent duration in seconds.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{Validation}: Calls \code{check_allowed_frequency_str()} to ensure \code{freq} is valid.
\item \strong{Conversion}: Retrieves the corresponding duration in seconds from \code{freq_to_second_map}.
}
}

\subsection{API Endpoint}{

Not applicable (helper conversion function).
}

\subsection{Usage}{

Utilised to translate frequency strings into seconds for time range calculations in klines data retrieval.
}

\subsection{Official Documentation}{

Not directly tied to a specific endpoint; see KuCoin klines API documentation for frequency mappings.
}
}
\examples{
\dontrun{
frequency_to_seconds("1min")   # Returns 60
frequency_to_seconds("1hour")  # Returns 3600
}
}

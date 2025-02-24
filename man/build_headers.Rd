% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helpers_api.R
\name{build_headers}
\alias{build_headers}
\title{Construct Request Headers for KuCoin API}
\usage{
build_headers(
  method,
  endpoint,
  body,
  keys,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{method}{Character string specifying the HTTP method (e.g., \code{"GET"}, \code{"POST"}).}

\item{endpoint}{Character string representing the API endpoint (e.g., \code{"/api/v1/orders"}).}

\item{body}{Character string containing the JSON-formatted request body; use \code{""} if no payload is required.}

\item{keys}{List of API credentials including:
\itemize{
\item \code{api_key}: Character string; your KuCoin API key.
\item \code{api_secret}: Character string; your KuCoin API secret.
\item \code{api_passphrase}: Character string; your KuCoin API passphrase.
\item \code{key_version}: Character string; the API key version (e.g., \code{"2"}).
}}
}
\value{
Promise resolving to a list of HTTP headers created with \code{httr::add_headers()}.
}
\description{
Generates HTTP request headers asynchronously for authenticated KuCoin API requests, incorporating the API key, HMAC-SHA256 signature, timestamp, encrypted passphrase, key version, and content type to ensure request security.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{Retrieve Server Time}: Obtains the current server timestamp in milliseconds by calling \code{get_server_time()} with the base URL from \code{get_base_url()}.
\item \strong{Construct Prehash String}: Concatenates the timestamp, uppercase HTTP method, endpoint, and request body.
\item \strong{Generate Signature}: Computes an HMAC-SHA256 signature over the prehash string using the API secret, then base64-encodes it.
\item \strong{Encrypt Passphrase}: Signs the API passphrase with the API secret using HMAC-SHA256 and base64-encodes the result.
\item \strong{Assemble Headers}: Constructs headers with \code{httr::add_headers()}, including \code{KC-API-KEY}, \code{KC-API-SIGN}, \code{KC-API-TIMESTAMP}, \code{KC-API-PASSPHRASE}, \code{KC-API-KEY-VERSION}, and \code{Content-Type}.
}
}

\subsection{API Endpoint}{

Not applicable (helper function for request construction).
}

\subsection{Usage}{

Employed to authenticate and secure API requests to KuCoin endpoints requiring authorisation.
}

\subsection{Official Documentation}{

Not directly tied to a specific endpoint; see KuCoin API authentication guidelines.
}
}
\examples{
\dontrun{
keys <- list(
  api_key = "your_api_key",
  api_secret = "your_api_secret",
  api_passphrase = "your_api_passphrase",
  key_version = "2"
)
main_async <- coro::async(function() {
  headers <- await(build_headers("POST", "/api/v1/orders", '{"size": 1}', keys))
  print(headers)
  headers <- await(build_headers("GET", "/api/v1/orders", "", keys))
  print(headers)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/helpers_api.R
\name{auto_paginate}
\alias{auto_paginate}
\title{Facilitate Automatic Pagination for KuCoin API Endpoints}
\usage{
auto_paginate(
  fetch_page,
  query = list(currentPage = 1, pageSize = 50),
  items_field = "items",
  paginate_fields = list(currentPage = "currentPage", totalPage = "totalPage"),
  aggregate_fn = function(acc) {
     acc
 },
  max_pages = Inf,
  .__coro_env_parent__ = <environment>
)
}
\arguments{
\item{fetch_page}{Function fetching a page of results, returning a promise resolving to the response.}

\item{query}{Named list of query parameters for the first page. Defaults to \code{list(currentPage = 1, pageSize = 50)}.}

\item{items_field}{Character string; field in the response containing items to aggregate. Defaults to \code{"items"}.}

\item{paginate_fields}{Named list specifying response fields for pagination:
\itemize{
\item \code{currentPage}: Field with the current page number.
\item \code{totalPage}: Field with the total number of pages.
Defaults to \code{list(currentPage = "currentPage", totalPage = "totalPage")}.
}}

\item{aggregate_fn}{Function combining accumulated results into the final output. Defaults to returning the accumulator list unchanged.}

\item{max_pages}{Numeric; maximum number of pages to fetch. Defaults to \code{Inf} (all available pages).}
}
\value{
Promise resolving to the aggregated result as defined by \code{aggregate_fn}.
}
\description{
Handles pagination for KuCoin API endpoints asynchronously by iteratively fetching pages with a user-supplied function and aggregating results using a provided aggregation function.
}
\details{
\subsection{Workflow Overview}{
\enumerate{
\item \strong{Fetch Page}: Calls \code{fetch_page} with current query parameters to retrieve a page.
\item \strong{Accumulate Results}: Adds items from the page (via \code{items_field}) to an accumulator list.
\item \strong{Determine Continuation}: Continues if the current page is less than the total pages and \code{max_pages} hasn’t been reached.
\item \strong{Aggregate Results}: Applies \code{aggregate_fn} to the accumulator once all pages are fetched.
}
}

\subsection{API Endpoint}{

Not applicable (helper function for paginated endpoints).
}

\subsection{Usage}{

Utilised to simplify retrieval of multi-page data from KuCoin API responses, aggregating results into a user-defined format.
}

\subsection{Official Documentation}{

Not directly tied to a specific endpoint; see KuCoin API pagination guidelines.
}
}
\examples{
\dontrun{
fetch_page <- coro::async(function(query) {
  url <- paste0(get_base_url(), "/api/v1/example", build_query(query))
  response <- httr::GET(url, httr::timeout(3))
  process_kucoin_response(response, url)
})
aggregate <- function(acc) data.table::rbindlist(acc)
main_async <- coro::async(function() {
  result <- await(auto_paginate(
    fetch_page = fetch_page,
    query = list(currentPage = 1, pageSize = 10),
    max_pages = 3,
    aggregate_fn = aggregate
  ))
  print(result)
})
main_async()
while (!later::loop_empty()) later::run_now()
}
}

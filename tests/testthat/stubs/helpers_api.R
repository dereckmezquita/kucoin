# tests/testthat/stubs/helpers_api.R

# Load the real helpers_api module from your R/ directory.
real_helpers <- box::use(../../../R/helpers_api)

# Export the functions expected by your production code.
box::export(auto_paginate, build_headers, process_kucoin_response)

# Re-export the original implementations for functions you don't want to stub.
auto_paginate <- real_helpers$auto_paginate
build_headers <- real_helpers$build_headers

# Override process_kucoin_response with a stub that throws an error.
process_kucoin_response <- function(response, url) {
  stop("YEETTTTT")
}
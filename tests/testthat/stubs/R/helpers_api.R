# tests/testthat/stubs/R/helpers_api.R

# IMPORTANT: Load the real helpers_api from production using a relative import.
# Use a relative path here so that we bypass the search path (and avoid circularity).
real_helpers <- box::use(./../../R/helpers_api)

# Export the functions expected by production code.
box::export(auto_paginate, build_headers, process_kucoin_response)

# Re-export the original implementations for functions we do NOT want to stub.
auto_paginate <- real_helpers$auto_paginate
build_headers  <- real_helpers$build_headers

# Override process_kucoin_response with our stub.
process_kucoin_response <- function(response, url) {
  stop("YEETTTTT")
}
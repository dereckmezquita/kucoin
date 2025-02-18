if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, expect_null, expect_true, expect_equal, fail ],
    later[ loop_empty, run_now ],
    promises[ then, catch ],
    digest[ hmac ],
    base64enc[ base64encode ],
    ../../R/helpers_api[ build_headers ],
    ../../R/utils[ get_base_url ]
)

test_that("build_headers returns valid authenticated request headers", {
    error <- NULL

    # Define test API credentials.
    keys <- list(
        api_key       = "test_key",
        api_secret    = "test_secret",
        api_passphrase= "test_pass",
        key_version   = "2"
    )
    method   <- "GET"
    endpoint <- "/api/v1/test"
    body     <- ""

    build_headers(method, endpoint, body, keys)$
        then(function(headers) {
            # Extract the actual headers from the object returned by add_headers().
            actual_headers <- headers$headers
            # Verify that all expected header fields are present.
            expected_names <- c(
                "KC-API-KEY", "KC-API-SIGN", "KC-API-TIMESTAMP",
                "KC-API-PASSPHRASE", "KC-API-KEY-VERSION", "Content-Type"
            )
            actual_names <- names(actual_headers)
            for (n in expected_names) {
                expect_true(n %in% actual_names, info = paste("Header", n, "is missing"))
            }

            # Check that static header values match.
            expect_equal(actual_headers[["KC-API-KEY"]], keys$api_key, info = "API key mismatch")
            expect_equal(actual_headers[["KC-API-KEY-VERSION"]], keys$key_version, info = "Key version mismatch")
            expect_equal(actual_headers[["Content-Type"]], "application/json", info = "Content-Type mismatch")

            # Validate the timestamp.
            timestamp_val <- actual_headers[["KC-API-TIMESTAMP"]]
            timestamp     <- as.numeric(timestamp_val)
            expect_true(!is.na(timestamp) && timestamp > 0, info = "Timestamp is not valid")

            # Reconstruct the prehash string: timestamp, uppercased method, endpoint, and body.
            prehash <- paste0(timestamp, toupper(method), endpoint, body)

            # Compute the expected signature.
            expected_signature_raw <- hmac(
                key = keys$api_secret,
                object = prehash,
                algo = "sha256",
                serialize = FALSE,
                raw = TRUE
            )
            expected_signature <- base64encode(expected_signature_raw)
            expect_equal(actual_headers[["KC-API-SIGN"]], expected_signature, info = "Signature mismatch")

            # Compute the expected encrypted passphrase.
            expected_passphrase_raw <- hmac(
                key = keys$api_secret,
                object = keys$api_passphrase,
                algo = "sha256",
                serialize = FALSE,
                raw = TRUE
            )
            expected_encrypted_passphrase<- base64encode(expected_passphrase_raw)
            expect_equal(actual_headers[["KC-API-PASSPHRASE"]], expected_encrypted_passphrase, info = "Encrypted passphrase mismatch")
        })$
        catch(function(e) {
            error <<- e
            detailed <- paste(capture.output(str(e)), collapse = "\n")
            fail(paste("Promise rejected with error:", conditionMessage(e), "\nDetails:\n", detailed))
        })

    while (!loop_empty()) {
        run_now(timeoutSecs = 0.1)
    }
    expect_null(error)
})

if (interactive()) setwd("./tests/testthat")

box::use(
    testthat[ test_that, expect_null, expect_equal, expect_true, fail ],
    ../../R/utils[ build_query, get_base_url, get_api_keys, get_subaccount ]
)

## Tests for build_query

test_that("build_query returns an empty string for empty parameters", {
    expect_equal(build_query(list()), "")
})

test_that("build_query builds a correct query string", {
    params <- list(currency = "USDT", type = "main")
    qs <- build_query(params)
    expect_equal(qs, "?currency=USDT&type=main")
})

test_that("build_query filters out NULL values", {
    params <- list(currency = "USDT", type = NULL, limit = 10)
    qs <- build_query(params)
    expect_equal(qs, "?currency=USDT&limit=10")
})

## Tests for get_base_url

test_that("get_base_url returns provided URL", {
    expect_equal(get_base_url("https://example.com"), "https://example.com")
})

test_that("get_base_url returns default URL when none provided", {
    old_endpoint <- Sys.getenv("KC-API-ENDPOINT")
    Sys.setenv("KC-API-ENDPOINT" = "")
    expect_equal(get_base_url(), "https://api.kucoin.com")
    Sys.setenv("KC-API-ENDPOINT" = old_endpoint)
})

test_that("get_base_url returns environment variable if set", {
    old_endpoint <- Sys.getenv("KC-API-ENDPOINT")
    Sys.setenv("KC-API-ENDPOINT" = "https://env-endpoint.com")
    expect_equal(get_base_url(), "https://env-endpoint.com")
    Sys.setenv("KC-API-ENDPOINT" = old_endpoint)
})

## Tests for get_api_keys

test_that("get_api_keys returns provided credentials", {
    keys <- get_api_keys("key1", "secret1", "pass1", "2")
    expect_equal(
        keys,
        list(
            api_key        = "key1",
            api_secret     = "secret1",
            api_passphrase = "pass1",
            key_version    = "2"
        )
    )
})

test_that("get_api_keys returns credentials from environment", {
    old_key    <- Sys.getenv("KC-API-KEY")
    old_secret <- Sys.getenv("KC-API-SECRET")
    old_pass   <- Sys.getenv("KC-API-PASSPHRASE")
    
    Sys.setenv("KC-API-KEY"        = "env_key")
    Sys.setenv("KC-API-SECRET"     = "env_secret")
    Sys.setenv("KC-API-PASSPHRASE" = "env_pass")
    
    keys <- get_api_keys()
    expect_equal(keys, list(api_key = "env_key", api_secret = "env_secret", 
                              api_passphrase = "env_pass", key_version = "2"))
    
    Sys.setenv("KC-API-KEY"        = old_key)
    Sys.setenv("KC-API-SECRET"     = old_secret)
    Sys.setenv("KC-API-PASSPHRASE" = old_pass)
})

## Tests for get_subaccount

test_that("get_subaccount returns provided sub-account configuration", {
    sub_cfg <- get_subaccount("sub1", "pass1")
    expect_equal(sub_cfg, list(sub_account_name = "sub1", sub_account_password = "pass1"))
})

test_that("get_subaccount returns values from environment", {
    old_name <- Sys.getenv("KC-ACCOUNT-SUBACCOUNT-NAME")
    old_pass <- Sys.getenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD")
    
    Sys.setenv("KC-ACCOUNT-SUBACCOUNT-NAME"     = "env_sub")
    Sys.setenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD" = "env_pass")
    
    sub_cfg <- get_subaccount()
    expect_equal(sub_cfg, list(sub_account_name = "env_sub", sub_account_password = "env_pass"))
    
    Sys.setenv("KC-ACCOUNT-SUBACCOUNT-NAME"     = old_name)
    Sys.setenv("KC-ACCOUNT-SUBACCOUNT-PASSWORD" = old_pass)
})

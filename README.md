
# kucoin <img src="man/figures/logo-small.png" align="right" height="139" />

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/dereckmezquita/kucoin.svg?branch=master)](https://travis-ci.org/dereckmezquita/kucoin)
<!-- badges: end -->

## Installation

You can install the development version of `kucoin` using:

``` r
# install.packages("remotes")
remotes::install_github("dereckmezquita/kucoin")
```

## Getting Started

### API Authorisation

Some functions in this package require permissioned access and need a
proper API key, secret, and passphrase. If you don’t have a key, or need
more information, visit the
<a href="https://docs.kucoin.com/#generating-an-api-key"
target="&quot;_blank">Generating an API Key</a>.

#### Setting-up API Key

Use an `.Renviron` file to set your API key. In the `.Renviron` file,
insert your API key details as follow:

``` bash
# sandbox has been deprecated see kucoin documentation for more information
KC-API-ENDPOINT = "https://api.kucoin.com"

KC-API-KEY = XXXXXXXXXX
KC-API-SECRET = XXXXXXXXXX
KC-API-PASSPHRASE = XXXXXXXXXX
```

### Asynchronous Programming

`kucoin` is built on top of `coro::async` and `promises`. This means
that all functions are asynchronous and return promises. One can use
`kucoin` in two ways, either by using the `coro::async` function or by
using the `then` and `catch` methods of the promises.

For a run down on `asynchronous` programming see my blog post here:
[Async programming in R for JS
devs](https://derecksnotes.com/blog/20250208_async-programming-in-R-for-JS-devs)

``` r
box::use(
    kucoin[ KucoinSpotMarketData ],
    coro[ async ],
    later[ loop_empty, run_now ]
)

market_data <- KucoinSpotMarketData$new()

async_main <- async(function() {
    data <- await(market_data$get_24hr_stats("BTC-USDT"))
    print(data)
})

async_main()

market_data$get_24hr_stats("BTC-USDT")$
    then(function(result) {
        print(result)
    })$
    catch(function(error) {
        print(error)
    })

# run the event loop
while (!loop_empty()) {
    run_now(timeoutSecs = Inf, all = TRUE)
}
```

    #>              timestamp      time_ms   symbol     buy    sell changeRate
    #>                 <POSc>        <num>   <char>  <char>  <char>     <char>
    #> 1: 2025-02-21 19:42:02 1.740167e+12 BTC-USDT 95454.7 95454.8    -0.0286
    #> 11 variable(s) not shown: [changePrice <char>, high <char>, low <char>, vol <char>, volValue <char>, last <char>, averagePrice <char>, takerFeeRate <char>, makerFeeRate <char>, takerCoefficient <char>, ...]
    #>              timestamp      time_ms   symbol     buy    sell changeRate
    #>                 <POSc>        <num>   <char>  <char>  <char>     <char>
    #> 1: 2025-02-21 19:42:02 1.740167e+12 BTC-USDT 95454.7 95454.8    -0.0286
    #> 11 variable(s) not shown: [changePrice <char>, high <char>, low <char>, vol <char>, volValue <char>, last <char>, averagePrice <char>, takerFeeRate <char>, makerFeeRate <char>, takerCoefficient <char>, ...]

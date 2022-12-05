
# kucoin

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/dereckdemezquita/kucoin.svg?branch=master)](https://travis-ci.org/dereckdemezquita/kucoin)
<!-- badges: end -->

## Installation

You can install the development version of `kucoin` using:

``` r
# install.packages("remotes")
remotes::install_github("dereckdemezquita/kucoin")
```

## Getting Started

``` r
# import library
library("kucoin")
```

### API Authorisation

Some functions in this package require permissioned access and need a
proper API key, secret, and passphrase. If you don’t have a key, or need
more information, visit the
<a href="https://docs.kucoin.com/#generating-an-api-key"
target="&quot;_blank">Generating an API Key</a>.

Current functions that need API authorisation are:

- `kucoin::cancel_all_orders`
- `kucoin::cancel_order`
- `kucoin::get_orders_all`
- `kucoin::get_account_balances`
- `kucoin::get_deposit_address`
- `kucoin::get_orders_by_id`
- `kucoin::submit_limit_order`
- `kucoin::submit_market_order`

#### Setting-up API Key

Use an `.Renviron` file to set your API key. You can `touch` or use
`usethat` to create a new `.Renviron` file;
<a href="https://usethis.r-lib.org/reference/edit.html"
target="_blank"><code>usethis::edit_r_environ()</code></a>:

In the `.Renviron` file, insert your API key details as follow:

``` bash
KC-API-ENDPOINT = https://openapi-sandbox.kucoin.com

KC-API-KEY = XXXXXXXXXX
KC-API-SECRET = XXXXXXXXXX
KC-API-PASSPHRASE = XXXXXXXXXX
```

The `KC-API-ENDPOINT` variable is optional. This is used to allow the
user access KuCoin’s sandbox API for paper trading. If not set then the
real API is used by default:

1.  <https://openapi-sandbox.kucoin.com>
2.  <https://api.kucoin.com/>

### Market Data

**All market data is publicly accessible, and could be accessed without
API authorisation.**

For getting historical data, you can use `kucoin::get_market_data()`:

``` r
# get one pair of symbol prices
prices <- kucoin::get_market_data(
    symbols = "KCS/USDT",
    from = "2022-10-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

prices
#>        symbol            datetime      open      high       low     close
#>        <char>              <POSc>     <num>     <num>     <num>     <num>
#>   1: KCS/USDT 2022-10-05 00:00:00 21205.960 21205.960 21205.960 21205.960
#>   2: KCS/USDT 2022-10-05 01:00:00 21205.960 21205.960 21205.960 21205.960
#>   3: KCS/USDT 2022-10-05 02:00:00 21205.960 21205.960 21205.960 21205.960
#>  ---                                                                     
#> 661: KCS/USDT 2022-11-01 12:00:00    17.613    17.613    17.613    17.613
#> 662: KCS/USDT 2022-11-01 13:00:00    17.613    17.613    17.613    17.613
#> 663: KCS/USDT 2022-11-01 14:00:00    17.100    17.100    17.100    17.100
#>      volume
#>       <num>
#>   1:   0.00
#>   2:   0.00
#>   3:   0.00
#>  ---       
#> 661:   0.00
#> 662:   0.00
#> 663:   0.15
#> 1 variable not shown: [turnover <num>]
```

The `kucoin::get_market_data()` function also supports for querying
multiple symbols:

``` r
# get one pair of symbol prices
prices <- kucoin::get_market_data(
    symbols = c("KCS/USDT", "BTC/USDT", "KCS/BTC"),
    from = "2022-10-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

prices
#>         symbol            datetime     open     high      low    close
#>         <char>              <POSc>    <num>    <num>    <num>    <num>
#>    1: KCS/USDT 2022-10-05 00:00:00 21205.96 21205.96 21205.96 21205.96
#>    2: KCS/USDT 2022-10-05 01:00:00 21205.96 21205.96 21205.96 21205.96
#>    3: KCS/USDT 2022-10-05 02:00:00 21205.96 21205.96 21205.96 21205.96
#>   ---                                                                 
#> 1079: BTC/USDT 2022-11-05 21:00:00 66271.00 66271.00 50000.00 62522.12
#> 1080: BTC/USDT 2022-11-05 22:00:00 63000.00 66270.00 59600.00 59600.00
#> 1081: BTC/USDT 2022-11-05 23:00:00 52500.00 76999.00  1000.00  1993.00
#>           volume
#>            <num>
#>    1: 0.00000000
#>    2: 0.00000000
#>    3: 0.00000000
#>   ---           
#> 1079: 0.04779697
#> 1080: 0.00416984
#> 1081: 1.16038578
#> 1 variable not shown: [turnover <num>]
```

You can also get the most recent metadata for all symbols using
`kucoin::get_market_metadata()`:

``` r
# get all symbols' most recent metadata
metadata <- kucoin::get_market_metadata()

metadata
#>         symbol       name base_currency quote_currency fee_currency market
#>         <char>     <char>        <char>         <char>       <char> <char>
#>  1: ADA3S/USDT ADA3S/USDT         ADA3S           USDT         USDT    ETF
#>  2:  ALGO/USDT  ALGO/USDT          ALGO           USDT         USDT   USDS
#>  3:   AMPL/BTC   AMPL/BTC          AMPL            BTC          BTC   DeFi
#> ---                                                                       
#> 95:   XSR/USDT   XSR/USDT           XSR           USDT         USDT   USDS
#> 96:   ZEN/USDT   ZEN/USDT           ZEN           USDT         USDT   USDS
#> 97:   ZIL/USDT   ZIL/USDT           ZIL           USDT         USDT   USDS
#> 10 variables not shown: [base_min_size <num>, quote_min_size <num>, base_max_size <num>, quote_max_size <num>, base_increment <num>, quote_increment <num>, price_increment <num>, price_limit_rate <num>, is_margin_enabled <lgcl>, enable_trading <lgcl>]
```

### Get User Information

**All user information data is private, and needs API authorisation.**

To get balance information you can use `kucoin::get_account_balances()`:

``` r
# get user's balance details
balances <- kucoin::get_account_balances()

balances
```

### Post an Order

**All order posting functions are private, and need API authorisation.**

#### Market Order

Here is an example of posting a market order:

``` r
# post a market order: buy 1 KCS
order_id <- kucoin::submit_market_order(
    symbol = "KCS/BTC",
    side = "buy",
    base_size = 1
)

order_id
```

#### Limit Order

Here is an example of posting a limit order:

``` r
# post a limit order: buy 1 KCS
order_id <- submit_limit_order(
    symbol = "KCS/BTC",
    side = "buy",
    base_size = 1
)

order_id
```


# kucoin

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

For more details and tutorials see the documentation at
[TUTORIALS](TUTORIALS.md).

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

Use an `.Renviron` file to set your API key. In the `.Renviron` file,
insert your API key details as follow:

``` shell
# sandbox has been deprecated see kucoin documentation for more information
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
#>        symbol            datetime   open   high    low  close   volume
#>        <char>              <POSc>  <num>  <num>  <num>  <num>    <num>
#>   1: KCS/USDT 2022-10-05 00:00:00  9.208  9.214  9.155  9.162 3753.287
#>   2: KCS/USDT 2022-10-05 01:00:00  9.162  9.174  9.156  9.164 1946.244
#>   3: KCS/USDT 2022-10-05 02:00:00  9.164  9.173  9.152  9.156 1885.309
#>  ---                                                                  
#> 766: KCS/USDT 2022-11-05 21:00:00 10.221 10.221 10.190 10.200 1628.069
#> 767: KCS/USDT 2022-11-05 22:00:00 10.201 10.256 10.201 10.212 2743.678
#> 768: KCS/USDT 2022-11-05 23:00:00 10.212 10.231 10.173 10.221 7536.361
#> 1 variable(s) not shown: [turnover <num>]
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
#>         symbol            datetime      open      high       low     close
#>         <char>              <POSc>     <num>     <num>     <num>     <num>
#>    1: KCS/USDT 2022-10-05 00:00:00 9.2080000 9.2140000 9.1550000 9.1620000
#>    2: KCS/USDT 2022-10-05 01:00:00 9.1620000 9.1740000 9.1560000 9.1640000
#>    3: KCS/USDT 2022-10-05 02:00:00 9.1640000 9.1730000 9.1520000 9.1560000
#>   ---                                                                     
#> 2302:  KCS/BTC 2022-11-05 21:00:00 0.0004785 0.0004790 0.0004781 0.0004782
#> 2303:  KCS/BTC 2022-11-05 22:00:00 0.0004782 0.0004803 0.0004782 0.0004795
#> 2304:  KCS/BTC 2022-11-05 23:00:00 0.0004795 0.0004802 0.0004783 0.0004800
#> 2 variable(s) not shown: [volume <num>, turnover <num>]
```

You can also get the most recent metadata for all symbols using
`kucoin::get_market_metadata()`:

``` r
# get all symbols' most recent metadata
metadata <- kucoin::get_market_metadata()

metadata
#>           symbol       name base_currency quote_currency fee_currency market
#>           <char>     <char>        <char>         <char>       <char> <char>
#>    1:  1CAT/USDT  1CAT/USDT          1CAT           USDT         USDT   USDS
#>    2: 1INCH/USDT 1INCH/USDT         1INCH           USDT         USDT   USDS
#>    3:    AA/USDT    AA/USDT            AA           USDT         USDT   USDS
#>   ---                                                                       
#> 1263:   ZRO/USDT   ZRO/USDT           ZRO           USDT         USDT   USDS
#> 1264:    ZRX/BTC    ZRX/BTC           ZRX            BTC          BTC   DeFi
#> 1265:   ZRX/USDT   ZRX/USDT           ZRX           USDT         USDT   USDS
#> 11 variable(s) not shown: [base_min_size <num>, quote_min_size <num>, base_max_size <num>, quote_max_size <num>, base_increment <num>, quote_increment <num>, price_increment <num>, price_limit_rate <num>, min_funds <num>, is_margin_enabled <lgcl>, ...]
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

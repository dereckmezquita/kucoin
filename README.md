
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

First of all, let’s start by importing the library:

``` r
# import library
library("kucoin")
```

### API Authorization

Some function in this package requires private access and need a proper
API key, secret, and passphrase. If you don’t have any, or need more
information, please visit the
<a href="https://docs.kucoin.com/#generating-an-api-key"
target="&quot;_blank">Generating an API Key</a> section in the official
API documentation.

Current functions that need API authorization are:

- `post_kucoin_market_order()`
- `get_kucoin_balances()`
- `get_kucoin_order()`

#### Setting-up API Key

To setup the API, the recommended way is using `.Renviron` file, which
could be conveniently done using
<a href="https://usethis.r-lib.org/reference/edit.html"
target="_blank"><code>usethis::edit_r_environ()</code></a>:

``` r
# you can also use `scope = "project"` for local environment
usethis::edit_r_environ(scope = "user")
```

In the `.Renviron` file, insert your API key details as follow:

``` bash
KC-API-ENDPOINT = https://openapi-sandbox.kucoin.com

KC-API-KEY = XXXXXXXXXX
KC-API-SECRET = XXXXXXXXXX
KC-API-PASSPHRASE = XXXXXXXXXX
```

The `KC-API-ENDPOINT` variable is optional. This is used to allow the
user to use KuCoin’s sandbox `api` for paper trading. If not set then
the real `api` is used by default:

1.  <https://openapi-sandbox.kucoin.com>
2.  <https://api.kucoin.com/>

### Market Data

**All market data is publicly accessible, and could be accessed without
API authorization.**

For getting historical data, you can use `get_kucoin_prices()`:

``` r
# get one pair of symbol prices
prices <- get_kucoin_prices(
    symbols = "KCS/USDT",
    from = "2022-10-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# quick check
prices
#>        symbol            datetime   open   high    low  close   volume turnover
#>   1: KCS/USDT 2022-10-05 00:00:00  9.208  9.214  9.155  9.162 3753.287 34426.22
#>   2: KCS/USDT 2022-10-05 01:00:00  9.162  9.174  9.156  9.164 1946.244 17829.28
#>   3: KCS/USDT 2022-10-05 02:00:00  9.164  9.173  9.152  9.156 1885.309 17269.03
#>   4: KCS/USDT 2022-10-05 03:00:00  9.156  9.164  9.147  9.149 1547.051 14160.24
#>   5: KCS/USDT 2022-10-05 04:00:00  9.149  9.155  9.127  9.142 2132.160 19486.83
#>  ---                                                                           
#> 764: KCS/USDT 2022-11-05 19:00:00 10.196 10.209 10.190 10.208 1866.102 19032.93
#> 765: KCS/USDT 2022-11-05 20:00:00 10.206 10.227 10.205 10.221 2503.484 25580.72
#> 766: KCS/USDT 2022-11-05 21:00:00 10.221 10.221 10.190 10.200 1628.069 16611.88
#> 767: KCS/USDT 2022-11-05 22:00:00 10.201 10.256 10.201 10.212 2743.678 28065.46
#> 768: KCS/USDT 2022-11-05 23:00:00 10.212 10.231 10.173 10.221 7536.361 76762.74
```

The `get_kucoin_prices()` function also support for querying multiple
symbols:

``` r
# get one pair of symbol prices
prices <- get_kucoin_prices(
    symbols = c("KCS/USDT", "BTC/USDT", "KCS/BTC"),
    from = "2022-10-05 00:00:00",
    to = "2022-11-06 00:00:00",
    frequency = "1 hour"
)

# quick check
prices
#>         symbol            datetime      open      high       low     close
#>    1: KCS/USDT 2022-10-05 00:00:00 9.2080000 9.2140000 9.1550000 9.1620000
#>    2: KCS/USDT 2022-10-05 01:00:00 9.1620000 9.1740000 9.1560000 9.1640000
#>    3: KCS/USDT 2022-10-05 02:00:00 9.1640000 9.1730000 9.1520000 9.1560000
#>    4: KCS/USDT 2022-10-05 03:00:00 9.1560000 9.1640000 9.1470000 9.1490000
#>    5: KCS/USDT 2022-10-05 04:00:00 9.1490000 9.1550000 9.1270000 9.1420000
#>   ---                                                                     
#> 2300:  KCS/BTC 2022-11-05 19:00:00 0.0004788 0.0004790 0.0004780 0.0004784
#> 2301:  KCS/BTC 2022-11-05 20:00:00 0.0004783 0.0004793 0.0004783 0.0004788
#> 2302:  KCS/BTC 2022-11-05 21:00:00 0.0004785 0.0004790 0.0004781 0.0004782
#> 2303:  KCS/BTC 2022-11-05 22:00:00 0.0004782 0.0004803 0.0004782 0.0004795
#> 2304:  KCS/BTC 2022-11-05 23:00:00 0.0004795 0.0004802 0.0004783 0.0004800
#>          volume     turnover
#>    1: 3753.2870 3.442622e+04
#>    2: 1946.2436 1.782928e+04
#>    3: 1885.3086 1.726903e+04
#>    4: 1547.0508 1.416024e+04
#>    5: 2132.1598 1.948683e+04
#>   ---                       
#> 2300:   67.4737 3.228209e-02
#> 2301:   42.6286 2.041167e-02
#> 2302:    3.6421 1.742147e-03
#> 2303:   65.7072 3.149826e-02
#> 2304:  104.3910 5.001386e-02
```

You can also get the most recent metadata for all symbols using
`get_kucoin_symbols()`:

``` r
# get all symbols' most recent metadata
metadata <- get_kucoin_symbols()

# quick check
metadata
#>            symbol        name base_currency quote_currency fee_currency market
#>    1: 1EARTH/USDT 1EARTH/USDT        1EARTH           USDT         USDT   DeFi
#>    2:  1INCH/USDT  1INCH/USDT         1INCH           USDT         USDT   USDS
#>    3:   2CRZ/USDT   2CRZ/USDT          2CRZ           USDT         USDT   USDS
#>    4:    AAVE/BTC    AAVE/BTC          AAVE            BTC          BTC   DeFi
#>    5:    AAVE/KCS    AAVE/KCS          AAVE            KCS          KCS    KCS
#>   ---                                                                         
#> 1281:    ZIL/USDC    ZIL/USDC           ZIL           USDC         USDC   USDS
#> 1282:    ZIL/USDT    ZIL/USDT           ZIL           USDT         USDT   USDS
#> 1283:    ZKT/USDT    ZKT/USDT           ZKT           USDT         USDT   USDS
#> 1284:     ZRX/BTC     ZRX/BTC           ZRX            BTC          BTC   DeFi
#> 1285:     ZRX/ETH     ZRX/ETH           ZRX            ETH          ETH   DeFi
#>       base_min_size quote_min_size base_max_size quote_max_size base_increment
#>    1:         1e+00          1e-03         1e+10          1e+08          1e-04
#>    2:         1e-02          1e-02         1e+10          1e+08          1e-04
#>    3:         1e+01          1e-01         1e+10          1e+08          1e-04
#>    4:         1e-03          1e-06         1e+10          1e+08          1e-04
#>    5:         1e-02          1e-02         1e+10          1e+08          1e-04
#>   ---                                                                         
#> 1281:         1e+01          1e-01         1e+10          1e+08          1e-04
#> 1282:         1e+00          1e-01         1e+10          1e+08          1e-04
#> 1283:         1e-01          1e-01         1e+10          1e+08          1e-04
#> 1284:         1e-01          1e-05         1e+10          1e+08          1e-04
#> 1285:         1e-01          1e-04         1e+10          1e+08          1e-04
#>       quote_increment price_increment price_limit_rate min_funds
#>    1:           1e-08           1e-08              0.1     1e-01
#>    2:           1e-05           1e-05              0.1     1e-01
#>    3:           1e-06           1e-06              0.1     1e-01
#>    4:           1e-06           1e-06              0.1     1e-06
#>    5:           1e-04           1e-04              0.1     1e-03
#>   ---                                                           
#> 1281:           1e-05           1e-05              0.1     1e-01
#> 1282:           1e-05           1e-05              0.1     1e-01
#> 1283:           1e-03           1e-03              0.1     1e-01
#> 1284:           1e-08           1e-08              0.1     1e-06
#> 1285:           1e-07           1e-07              0.1     1e-05
#>       is_margin_enabled enable_trading
#>    1:             FALSE           TRUE
#>    2:              TRUE           TRUE
#>    3:             FALSE           TRUE
#>    4:             FALSE           TRUE
#>    5:             FALSE           TRUE
#>   ---                                 
#> 1281:             FALSE           TRUE
#> 1282:              TRUE           TRUE
#> 1283:             FALSE          FALSE
#> 1284:             FALSE           TRUE
#> 1285:             FALSE           TRUE
```

### Get User Information

**All user information data is private, and need API authorization.**

To get the balance information, you can use `get_kucoin_balance()`:

``` r
# get user's balance details
balances <- get_kucoin_balances()

# quick check
balances
```

### Post an Order

**All order posting functions are private, and need API authorization.**

#### Market Order

Here is an example of posting a market order:

``` r
# post a market order: buy 1 KCS
order_detail <- post_kucoin_market_order(
    symbol = "KCS/BTC",
    side = "buy",
    base_size = 1
)

# quick check
order_detail
```

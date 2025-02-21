
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

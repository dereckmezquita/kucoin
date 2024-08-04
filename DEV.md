```bash
Rscript -e "testthat::test_dir('tests/testthat')"

Rscript -e "devtools::document()"
Rscript -e "devtools::check()"
Rscript -e "devtools::install()"
```
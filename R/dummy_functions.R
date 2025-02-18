# These functions return dummy values to provide good values for the examples of other non-exported functions.
# They should not be exported.

#' Get dummy filter states to apply initially
#'
#' This can be used for the argument `filter` in [`srv_teal`].
#'
#' @param data (`TealData`)
#' @return dummy filter states
#' @keywords internal
get_dummy_filter <- function(data) { # nolint
  ADSL <- teal.data::get_raw_data(x = data, dataname = "ADSL") # nolint
  ADLB <- teal.data::get_raw_data(x = data, dataname = "ADLB") # nolint

  res <- list(
    ADSL = list(
      filter = list(
        list(
          SEX = teal.slice:::init_filter_state(
            x = ADSL$SEX,
            varname = "SEX",
            varlabel = "Sex"
          ),
          AGE = teal.slice:::init_filter_state(
            x = ADSL$AGE,
            varname = "AGE",
            varlabel = "Age"
          )
        )
      )
    ),
    ADLB = list(
      filter = list(
        list(
          ASEQ = teal.slice:::init_filter_state(
            x = ADLB$ASEQ,
            varname = "ASEQ",
            varlabel = "Sequence Number"
          )
        )
      )
    )
  )

  return(res)
}

#' Get dummy CDISC data
#'
#' Get dummy CDISC data including `ADSL`, `ADAE` and `ADLB`.
#' Some NAs are also introduced to stress test.
#'
#' @return `cdisc_data`
#' @keywords internal
get_dummy_cdisc_data <- function() { # nolint
  teal_with_pkg <- function(pkg, code) {
    pkg_name <- paste0("package:", pkg)
    if (!pkg_name %in% search()) {
      require(pkg, character.only = TRUE)
      on.exit(detach(pkg_name, character.only = TRUE))
    }
    eval.parent(code)
    return(invisible(NULL))
  }

  teal_with_pkg("scda", code = {
    ADSL <- scda::synthetic_cdisc_data("latest")$adsl # nolint
    ADAE <- scda::synthetic_cdisc_data("latest")$adae # nolint
    ADLB <- scda::synthetic_cdisc_data("latest")$adlb # nolint
  })

  ADSL$logical_test <- sample(c(TRUE, FALSE, NA), size = nrow(ADSL), replace = TRUE) # nolint
  ADSL$SEX[1:150] <- NA # nolint

  res <- teal.data::cdisc_data(
    teal.data::cdisc_dataset(dataname = "ADSL", x = ADSL),
    teal.data::cdisc_dataset(dataname = "ADAE", x = ADAE),
    teal.data::cdisc_dataset(dataname = "ADLB", x = ADLB),
    code = "
      ADSL <- synthetic_cdisc_data(\"latest\")$adsl
      ADAE <- synthetic_cdisc_data(\"latest\")$adae
      ADLB <- synthetic_cdisc_data(\"latest\")$adlb
    "
  )
  return(res)
}

#' Get a dummy `datasets` object with `ADSL` data, useful in the examples
#'
#' Returns a new `R6` object on each invocation, not a singleton.
#' @return `FilteredData` with `ADSL` set
#' @keywords internal
get_dummy_datasets <- function() { # nolint
  dummy_cdisc_data <- get_dummy_cdisc_data()
  return(teal.slice::init_filtered_data(dummy_cdisc_data))
}

#' Get dummy modules
#'
#' Create an example hierarchy of `teal_modules` from which
#' a teal app can be created.
#'
#' @return `teal_modules`
#' @keywords internal
get_dummy_modules <- function() {
  mods <- modules(
    label = "d1",
    modules(
      label = "d2",
      modules(
        label = "d3",
        module(label = "aaa1"), module(label = "aaa2"), module(label = "aaa3")
      ),
      module(label = "bbb")
    ),
    module(label = "ccc")
  )
  return(mods)
}

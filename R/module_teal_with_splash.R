# This file adds a splash screen for delayed data loading on top of teal

#' UI to show a splash screen in the beginning, then delegate to [srv_teal()]
#'
#' @description `r lifecycle::badge("stable")`
#' The splash screen could be used to query for a password to fetch the data.
#' [init()] is a very thin wrapper around this module useful for end-users which
#' assumes that it is a top-level module and cannot be embedded.
#' This function instead adheres to the Shiny module conventions.
#'
#' If data is obtained through delayed loading, its splash screen is used. Otherwise,
#' a default splash screen is shown.
#'
#' Please also refer to the doc of [init()].
#'
#' @param id (`character(1)`)\cr
#'   module id
#' @inheritParams init
#' @export
ui_teal_with_splash <- function(id,
                                data,
                                title,
                                header = tags$p("Add Title Here"),
                                footer = tags$p("Add Footer Here")) {
  stopifnot(is(data, "TealDataAbstract"))
  is_pulled_data <- teal.data::is_pulled(data)
  ns <- NS(id)

  # Startup splash screen for delayed loading
  # We use delayed loading in all cases, even when the data does not need to be fetched.
  # This has the benefit that when filtering the data takes a lot of time initially, the
  # Shiny app does not time out.
  splash_ui <- if (is_pulled_data) {
    # blank ui if data is already pulled
    div()
  } else {
    message("App was initialized with delayed data loading.")
    data$get_ui(ns("startapp_module"))
  }

  ui_teal(id = ns("teal"), splash_ui = splash_ui, title = title, header = header, footer = footer)
}

#' Server function that loads the data through reactive loading and then delegates
#' to [srv_teal()].
#'
#' @description `r lifecycle::badge("stable")`
#' Please also refer to the doc of [init()].
#'
#' @inheritParams init
#' @param modules `teal_modules` object containing the output modules which
#'   will be displayed in the teal application. See [modules()] and [module()] for
#'   more details.
#' @inheritParams shiny::moduleServer
#' @return `reactive`, return value of [srv_teal()]
#' @export
srv_teal_with_splash <- function(id, data, modules, filter = list()) {
  stopifnot(is(data, "TealDataAbstract"))
  moduleServer(id, function(input, output, session) {
    logger::log_trace(
      "srv_teal_with_splash initializing module with data { paste(data$get_datanames(), collapse = ' ')}."
    )

    if (getOption("teal.show_js_log", default = FALSE)) {
      shinyjs::showLog()
    }

    is_pulled_data <- teal.data::is_pulled(data)
    # raw_data contains TealDataAbstract, i.e. R6 object and container for data
    # reactive to get data through delayed loading
    # we must leave it inside the server because of callModule which needs to pick up the right session
    if (is_pulled_data) {
      raw_data <- reactiveVal(data) # will trigger by setting it
    } else {
      raw_data <- data$get_server()(id = "startapp_module")
      if (!is.reactive(raw_data)) {
        stop("The delayed loading module has to return a reactive object.")
      }
    }

    res <- srv_teal(id = "teal", modules = modules, raw_data = raw_data, filter = filter)
    logger::log_trace(
      "srv_teal_with_splash initialized the module with data { paste(data$get_datanames(), collapse = ' ') }."
    )
    return(res)
  })
}

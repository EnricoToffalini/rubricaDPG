create_R_env <- function() {
  if (!file.exists(".Renviron")) {
    file.create(".Renviron")
    writeLines(
      "GMAIL=youraccount@gmail.com\nQUARTO_PROJECT_RENDER_ALL=1",
      con = ".Renviron"
    )
  }
  utils::file.edit(".Renviron")
}

info <- list(
  teaching = list(
    online = "https://docs.google.com/spreadsheets/d/16SQ0qckkVENVpRXZg5D6QTMEQs4v0NC2OjAHRKw91lQ/edit?gid=0#gid=0",
    local = "database/teaching.rds"
  )
)

read_all_sheets <- function(x) {
  sheets <- readxl::excel_sheets(here::here(x))
  file <- lapply(sheets, function(s) {
    readxl::read_xlsx(here::here(x), sheet = s)
  })
  names(file) <- sheets
  if (length(file) == 1) {
    file <- file[[1]]
  }
  return(file)
}

drive_dowload_read <- function(x) {
  local_xlsx <- xfun::with_ext(x$local, "xlsx")
  force_download <- Sys.getenv("FORCE_TEACHING_DOWNLOAD", "0") == "1"

  if (!force_download && file.exists(x$local)) {
    message("Using cached local RDS: ", x$local)
    return(readRDS(x$local))
  }

  if (!interactive() && Sys.getenv("GDRIVE_AUTH", "0") != "1") {
    googledrive::drive_deauth()
  }

  out <- tryCatch(
    {
      file <- googledrive::drive_download(
        x$online,
        local_xlsx,
        overwrite = TRUE
      )
      xlsx <- read_all_sheets(file$local_path)
      saveRDS(xlsx, x$local)
      readRDS(x$local)
    },
    error = function(e) {
      if (file.exists(x$local)) {
        message("Google Drive download failed, using cached local RDS: ", x$local)
        return(readRDS(x$local))
      }

      if (file.exists(local_xlsx)) {
        message("Google Drive download failed, using local XLSX: ", local_xlsx)
        xlsx <- read_all_sheets(local_xlsx)
        saveRDS(xlsx, x$local)
        return(readRDS(x$local))
      }

      stop(
        paste0(
          "Cannot download data from Google Drive and no local cache is available.\n",
          "Original error: ",
          conditionMessage(e)
        ),
        call. = FALSE
      )
    }
  )

  out
}

flag <- function(x){
  sprintf('<span class="fi fi-%s"></span>', x)
}

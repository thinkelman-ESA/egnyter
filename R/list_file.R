#' List file or folder
#'
#' List information about a file or folder
#'
#' @param source   The full path (starting 'Shared/') of the remote file or folder
#' @param token    User's Egnyter authorisation token
#' @param domain   Egnyte domain URL
#' @export
#'

list_file <- function(source, token = get_parameter("token"), domain = get_parameter("domain")){
  # Check domain
  if(!egnyter:::validate_domain(domain)) stop("Invalid Egnyte domain.", call. = FALSE)

  # Check authorisation token
  if(!egnyter:::validate_token(token)) stop("Invalid Egnyte token.", call. = FALSE)

  # Add a trailing '/' if not given
  if(stringr::str_sub(domain, -1) != "/") domain <- paste0(domain,"/")

  # Replace whitespace in destination folder path
  source <- stringr::str_replace_all(source, " ", "%20")

  # Formatted file path
  file_path <- paste0(domain, "pubapi/v1/fs/", source)

  # GET request to retrieve file data
  file_req <- httr::GET(url = file_path, httr::add_headers(Authorization = token))

  # Alert us if there's a problem
  httr::stop_for_status(file_req)

  httr::content(file_req)
}

#' Download a file from Egnyte
#'
#' This function downloads and parses a file of any type from Egnyte.
#'
#' @param source The full path (starting 'Shared/') of the remote file
#' @param local_dest The local file to be created
#' @param file_type The MIME file type to pull the file in, see \link[httr]{content} for more info
#' @param encoding The default encoding to use for the content translation, see \link[httr]{content} for more info
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @export
download_file <- function(source, local_dest, file_type = "raw", encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain")) {
  # Check domain
  if(!egnyter:::validate_domain(domain)) stop("Invalid Egnyte domain.", call. = FALSE)

  # Check authorisation token
  if(!egnyter:::validate_token(token)) stop("Invalid Egnyte token.", call. = FALSE)

  # Add a trailing '/' if not given
  if(stringr::str_sub(domain, -1) != "/") domain <- paste0(domain,"/")

  # Replace whitespace in destination folder path
  source <- stringr::str_replace_all(source, " ", "%20")

  # Formatted download path
  download_path <- paste0(domain, "pubapi/v1/fs-content/", source)

  # GET request to retrieve file data
  file_req <- httr::GET(url = download_path, httr::add_headers(Authorization = token))

  # Alert us if there's a problem
  httr::stop_for_status(file_req)

  # Write content to local file
  file_content <- httr::content(file_req, file_type, encoding = encoding)
  writeBin(file_content, local_dest)

  invisible(local_dest)
}

#' Download a feather file from Egnyte into a local data frame
#'
#' This function downloads and parses a .feather file from Egnyte into
#' a local data frame in R.
#'
#' @param source The path of the remote file in your Egnyte filesystem
#' @param encoding The default encoding to use for content translation
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @param ... Additional arguments to be passed to `read_feather`
#' @export
download_feather <- function(source, encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain"), ...)
{
  # Create a new temporary file (feather)
  tmp_name <- tempfile(fileext = ".feather")

  # Download the data into our temporary file
  egnyter::download_file(source = source, local_dest = tmp_name, file_type = "raw", encoding = encoding, domain = domain)

  # Read the temporary file into R
  downloaded_data <- feather::read_feather(tmp_name, ...)

  # Remove temporary file
  file.remove(tmp_name)

  # Return dataframe invisibly
  invisible(downloaded_data)
}


#' Download a csv file from Egnyte into a local data frame
#'
#' This function downloads and parses a csv file from Egnyte into
#' a local data frame in R.
#'
#' @param source The path of the remote file in your Egnyte filesystem
#' @param encoding The default encoding to use for content translation
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @param ... Additional arguments to be passed to `read_csv`
#' @export
download_csv <- function(source, encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain"), ...)
{
  # Create a new temporary file (csv)
  tmp_name <- tempfile(fileext = ".csv")

  # Download the data into our temporary file
  egnyter::download_file(source = source, local_dest = tmp_name, file_type = "raw", encoding = encoding, domain = domain)

  # Read the temporary file into R
  downloaded_data <- readr::read_csv(tmp_name, ...)

  # Remove temporary file
  file.remove(tmp_name)

  # Return dataframe invisibly
  invisible(downloaded_data)
}

#' Download a delimited file from Egnyte into a local data frame
#'
#' This function downloads and parses a delimited file from Egnyte into
#' a local data frame in R.
#'
#' @param source The path of the remote file in your Egnyte filesystem
#' @param delim Single character used to separate fields within a record
#' @param encoding The default encoding to use for content translation
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @param ... Additional arguments to be passed to `read_delim`
#' @export
download_delim <- function(source, delim, encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain"), ...)
{
  # Create a new temporary file (csv)
  tmp_name <- tempfile(fileext = ".csv")

  # Download the data into our temporary file
  egnyter::download_file(source = source, local_dest = tmp_name, file_type = "raw", encoding = encoding, domain = domain)

  # Read the temporary file into R
  downloaded_data <- readr::read_delim(tmp_name, delim, ...)

  # Remove temporary file
  file.remove(tmp_name)

  # Return dataframe invisibly
  invisible(downloaded_data)
}

#' Download an Excel file from Egnyte into a local data frame
#'
#' This function downloads and parses an Excel file from Egnyte into
#' a local data frame in R.
#'
#' @param source The path of the remote file in your Egnyte filesystem
#' @param encoding The default encoding to use for content translation
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @param ... Additional arguments to be passed to `read_excel`
#' @export
download_excel <- function(source, encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain"), ...)
{
  file_extension <- stringr::str_extract(source, "(\\.[^.]+)$")

  if (file_extension != ".xlsx" && file_extension != ".xls") {
    stop("This function is for downloading Excel files only.", call. = FALSE)
  }

  # Create a new temporary file (excel)
  tmp_name <- tempfile(fileext = file_extension)

  # Download the data into our temporary file
  egnyter::download_file(source = source, local_dest = tmp_name, file_type = "raw", encoding = encoding, domain = domain)

  # Read the temporary file into R
  downloaded_data <- readxl::read_excel(tmp_name, ...)

  # Remove temporary file
  file.remove(tmp_name)

  # Return dataframe invisibly
  invisible(downloaded_data)
}

#' Download an RDS file from Egnyte and load contents into R
#'
#' This function downloads and parses an object in an RDS file from Egnyte into
#' a local object (using \link[base]{readRDS}).
#'
#' @param source The path of the remote file in your Egnyte filesystem
#' @param encoding The default encoding to use for content translation
#' @param token User's Egnyter authorisation token
#' @param domain Egnyte domain URL
#' @param ... Additional arguments to be passed to `load`
#' @export
download_rds <- function(source, encoding = "ISO-8859-1", token = get_parameter("token"), domain = get_parameter("domain"), ...)
{
  # Create a new temporary file (rds)
  tmp_name <- tempfile(fileext = ".rds")

  # Download the data into our temporary file
  egnyter::download_file(source = source, local_dest = tmp_name, file_type = "raw", encoding = encoding, token = token, domain = domain)

  # Load this data into the global environment
  newobject <- readRDS(tmp_name)

  # Remove temporary file
  file.remove(tmp_name)

  # Return the new object invisibly
  invisible(newobject)
}

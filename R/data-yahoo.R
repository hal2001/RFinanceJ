get_from_yahoo <- function(
  code,
  start_date,
  end_date,
  frequency)
{
  i <- 1
  dfl <- list()
  repeat{
    query <- make_query(code, type, start_date, end_date, frequency, i)
    df <- run_query(query)
    if(nrow(df) != 0){
      dfl[[i]] <- df
    }else{
      break;
    }
    i <- i + 1
  }
  dplyr::bind_rows(dfl)
}
run_query <- function(query)
{
  COLNAMES <- list(
    c("Date", "Open", "High", "Low", "Close", "Volume", "AdjClose"),
    c("Date", "Open", "High", "Low", "Close"),
    c("Date", "Value", "NAV"))
  res <- readHTMLTable(query, stringsAsFactors=FALSE)[[2]]
  if(!is.null(res)){
    size <- ncol(res)
    colnames(res) <- unlist(COLNAMES[sapply(COLNAMES, function(x)length(x)==size)])
    res_data <- res %>% select(-Date) %>% mutate_each(funs(as_number))
    res_date <- res %>% select(Date)  %>% mutate_each(funs(convert_to_date))
    cbind(res_date, res_data)
  }else{
    nd <- as.double()
    data.frame(as.Date(character()), nd)
  }
}
#
format_code <- function(code)
{
  if(is.numeric(code)){
    paste0(code, ".T")
  }else if(is.character(code)){
    if(length(grep(".T", code))){
      code
    }else{
      paste0(code, ".T")      
    }
  }
  else{
    stop("'code' argument must be number of character for Yahoo! Finance.")
  }
}
#
make_query <- function(code, type, start_date, end_date, frequency, page)
{
  BASE <- "http://info.finance.yahoo.co.jp/history/?code="
  DATE_STRING_FORMAT <- "([0-9]{4,4})-([0-9]{2,2})-([0-9]{2,2})"
  s <- start_date %>% convert_to_date %>% format("%Y-%m-%d") %>% gsub(DATE_STRING_FORMAT,"&sy=\\1&sm=\\2&sd=\\3", .)
  e <- end_date   %>% convert_to_date %>% format("%Y-%m-%d") %>% gsub(DATE_STRING_FORMAT,"&ey=\\1&em=\\2&ed=\\3", .)
  yahoo_frequency <- if(frequency == WEEKLY){
    "w"
  }else if(frequency == MONTHLY){
    "m"
  }
  else{
    "d"
  } 
  paste0(BASE, code, s, e, '&p=', page,'&tm=', yahoo_frequency)  
}
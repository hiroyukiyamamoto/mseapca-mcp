fail <- function(message) stop(message,call.=FALSE)
scalar_integer <- function(x,name,lo,hi) {
  if(!is.numeric(x)||length(x)!=1L||!is.finite(x)||x!=floor(x)||x<lo||x>hi)
    fail(sprintf("%s must be an integer from %s to %s",name,lo,hi))
  as.integer(x)
}
scalar_number <- function(x,name,lo,hi) {
  if(!is.numeric(x)||length(x)!=1L||!is.finite(x)||x<lo||x>hi)fail(paste(name,"is outside its allowed range"))
  x
}
scalar_text <- function(x,name,max_length=200L,empty=FALSE) {
  if(!is.character(x)||length(x)!=1L||is.na(x)||nchar(x)>max_length||(!empty&&!nzchar(trimws(x))))fail(paste("Invalid",name))
  trimws(x)
}
restricted_id <- function(x) grepl("kegg|^[CDGR][0-9]{5}$|^(hsa|map|ko)[0-9]{5}$",x,ignore.case=TRUE)
text_vector <- function(x,name,maximum=5000L,empty=FALSE) {
  if(is.list(x)) {
    if(any(lengths(x)!=1L)||!all(vapply(x,is.character,logical(1))))fail(paste(name,"must be a string array"))
    x<-unlist(x,use.names=FALSE)
  }
  if(is.null(x)&&empty)return(character())
  if(!is.character(x)||length(x)>maximum||(!empty&&!length(x))||anyNA(x)||any(nchar(x)>1024)||any(!nzchar(trimws(x))))fail(paste("Invalid",name))
  x<-trimws(x)
  if(any(restricted_id(x)))fail(paste(name,"contains excluded identifiers or source references"))
  x
}
normalize_ids <- function(x,identifier) {
  if(!identifier %in% c("name","hmdb","chebi","inchikey","pubchem"))fail("Unknown identifier namespace")
  if(identifier=="name")tolower(trimws(x))else toupper(trimws(x))
}
safe_result <- function(expr) {
  warnings<-character()
  tryCatch({
    result<-withCallingHandlers(expr,warning=function(w){warnings<<-unique(c(warnings,conditionMessage(w)));invokeRestart("muffleWarning")})
    result$ok<-TRUE;result$warnings<-as.list(warnings);result$schema_version<-"1.0"
    result
  },error=function(e)list(ok=FALSE,error=list(code="analysis_error",message=conditionMessage(e)),warnings=as.list(warnings)))
}
finite_value <- function(x)if(is.numeric(x)&&length(x)==1L&&!is.finite(x))"not_finite" else unname(x)
numeric_rows <- function(x,min_rows=4L,max_rows=200L,max_cols=500L,max_cells=50000L) {
  if(is.list(x)&&identical(names(x),"rows"))x<-x$rows
  if(is.matrix(x)) {
    if(!is.numeric(x)||nrow(x)<min_rows||nrow(x)>max_rows||ncol(x)<3L||ncol(x)>max_cols||length(x)>max_cells||any(!is.finite(x)))fail("Numeric matrix exceeds dimensions or contains nonfinite values")
    return(x)
  }
  if(!is.list(x)||length(x)<min_rows||length(x)>max_rows)fail("Invalid matrix row count")
  sizes<-lengths(x)
  if(length(unique(sizes))!=1L||sizes[[1]]<3L||sizes[[1]]>max_cols||sum(sizes)>max_cells)fail("Invalid matrix dimensions")
  x<-lapply(x,function(row){
    if(is.list(row)){if(any(lengths(row)!=1L)||!all(vapply(row,is.numeric,logical(1))))fail("Matrix must contain numbers");row<-unlist(row,use.names=FALSE)}
    if(!is.numeric(row)||any(!is.finite(row)))fail("Matrix must contain finite numbers")
    row
  })
  do.call(rbind,x)
}
matrix_input <- function(x)list(rows=unname(lapply(seq_len(nrow(x)),function(i)as.list(unname(x[i,])))))

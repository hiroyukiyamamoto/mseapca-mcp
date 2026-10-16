isolated_worker <- function(fn,args,timeout)tryCatch(
  callr::r(fn,args=args,timeout=timeout,show=FALSE,supervise=TRUE),
  error=function(e)list(ok=FALSE,warnings=list(),error=list(
    code=if(inherits(e,"callr_timeout_error"))"computation_timeout" else "analysis_error",
    message=if(inherits(e,"callr_timeout_error"))"Computation exceeded its time limit" else "Analysis worker failed")))
run_bounded_analysis <- function(name,arguments,timeout=20) {
  allowed<-c("catalog_info","search_sets","get_sets","lookup_metabolites","demo_data","analyze_ora","analyze_range","analyze_msea","analyze_ssea")
  if(!name %in% allowed)stop("Unknown tool")
  isolated_worker(function(root,lib,name,arguments){
    setwd(root);.libPaths(lib)
    source("R/utils.R");source("R/database.R");source("R/analysis.R")
    do.call(get(name,mode="function"),arguments)
  },list(getwd(),.libPaths(),name,arguments),timeout)
}

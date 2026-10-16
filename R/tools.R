make_tools <- function() {
  strings <- function(description,required=TRUE)ellmer::type_array(items=ellmer::type_string(),description=description,required=required)
  members <- function(label,required=FALSE)ellmer::type_object(label,.required=required,
    sets=ellmer::type_array(items=ellmer::type_object("Set",name=ellmer::type_string(),members=strings("Identifiers"))))
  common <- list(set_ids=strings("Database set IDs; select at least two sets in total",FALSE),
    custom_sets=members("Optional custom sets"),identifier=ellmer::type_string("name, hmdb, chebi, inchikey or pubchem; default name",required=FALSE))
  ora <- c(list(significant=strings("Significant identifiers"),detected=strings("Detected background",FALSE)),common,
    list(method=ellmer::type_string("det, all, est_naive, est_weighted or est_shrink",required=FALSE),
      lambda=ellmer::type_number("Positive shrinkage parameter; default 5",required=FALSE),max_results=ellmer::type_integer("1-200; default 50",required=FALSE)))
  range <- ora;range$detected<-strings("Detected background");range$method<-ellmer::type_string("ora_full, bino_naive, bino_weighted or bino_shrink",required=FALSE)
  range$nsim<-ellmer::type_integer("10-1000; default 100",required=FALSE)
  range$probs<-ellmer::type_array(items=ellmer::type_number(),description="Two quantiles bracketing 0.5",required=FALSE)
  msea<-c(list(x=ellmer::type_object("Samples by metabolites, 4-200 rows, 3-500 columns, at most 50000 cells",
    rows=ellmer::type_array(items=ellmer::type_array(items=ellmer::type_number()))),
    metabolite_ids=strings("Column identifiers"),y=ellmer::type_array(items=ellmer::type_number(),description="Nonconstant sample response")),common,
    list(maxiter=ellmer::type_integer("10-1000 membership permutations; default 100",required=FALSE),
      seed=ellmer::type_integer("Reproducible random seed",required=FALSE),max_results=ellmer::type_integer("1-200",required=FALSE)))
  ssea<-c(list(samples=ellmer::type_object("Presence lists",samples=ellmer::type_array(items=ellmer::type_object("Sample",name=ellmer::type_string(),members=strings("Present metabolites")))),detected=strings("Common detected background")),common)
  definitions<-list(
    catalog_info=list("Filtered snapshot provenance, source counts and supported identifiers",list()),
    search_sets=list("Search non-KEGG set metadata using literal text",list(query=ellmer::type_string(required=FALSE),source=ellmer::type_string(required=FALSE),organism=ellmer::type_string(required=FALSE),limit=ellmer::type_integer(required=FALSE),offset=ellmer::type_integer(required=FALSE))),
    get_sets=list("Retrieve set members in one identifier namespace; output may be truncated",list(set_ids=strings("1-50 set IDs"),identifier=ellmer::type_string(required=FALSE),max_members=ellmer::type_integer(required=FALSE))),
    lookup_metabolites=list("Literal metabolite lookup; no inferred identifier conversion",list(query=ellmer::type_string(),exact=ellmer::type_boolean(required=FALSE),limit=ellmer::type_integer(required=FALSE))),
    demo_data=list("Real fasting metabolome with exploratory PC1 selection, or synthetic membership example",list(dataset=ellmer::type_string("fasting (default) or membership",required=FALSE))),
    analyze_ora=list("Official mseapca over-representation analysis; BH correction before truncation",ora),
    analyze_range=list("Official ORA uncertainty range; upstream simulation uses seed 1",range),
    analyze_msea=list("Official quantitative MSEA: metabolite-membership permutation and upstream FDR",msea),
    analyze_ssea=list("Official sample presence-list ORA scores, minus natural log p; not GSVA",ssea))
  lapply(names(definitions),function(name){
    fn<-get(name,mode="function");force(name)
    wrapped<-function(...)ellmer::ContentText(text=as.character(jsonlite::toJSON(
      run_bounded_analysis(name,as.list(environment())),auto_unbox=TRUE,digits=NA,null="null")))
    formals(wrapped)<-formals(fn)
    ellmer::tool(wrapped,name=name,description=definitions[[name]][[1]],arguments=definitions[[name]][[2]],convert=FALSE)
  })
}

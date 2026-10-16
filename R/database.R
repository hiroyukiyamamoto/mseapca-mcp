.catalog_cache<-new.env(parent=emptyenv())
database <- function() {
  if(is.null(.catalog_cache$data)) {
    .catalog_cache$data<-jsonlite::fromJSON(gzfile("data/catalog.json.gz"),simplifyVector=FALSE)
    stopifnot(all(vapply(.catalog_cache$data,function(p)!any(restricted_id(c(p$id,p$source_db))),logical(1))))
  }
  .catalog_cache$data
}
source_manifest <- function()jsonlite::fromJSON("data/manifest.json",simplifyVector=FALSE)
catalog_info <- function()safe_result({
  list(database=source_manifest(),identifier_namespaces=as.list(c("name","hmdb","chebi","inchikey","pubchem")),
    notes="Only the filtered fixed snapshot is queried. No remote AI, update or identifier API is called.")
})
search_sets <- function(query="",source="",organism="",limit=25L,offset=0L)safe_result({
  query<-tolower(scalar_text(query,"query",empty=TRUE));source<-scalar_text(source,"source",empty=TRUE)
  organism<-tolower(scalar_text(organism,"organism",empty=TRUE))
  limit<-scalar_integer(limit,"limit",1L,100L);offset<-scalar_integer(offset,"offset",0L,10000L)
  if(nzchar(source)&&!source %in% names(source_manifest()$source_counts))fail("Unknown or excluded source")
  found<-Filter(function(p)(!nzchar(source)||p$source_db==source)&&
    (!nzchar(organism)||grepl(organism,tolower(p$organism),fixed=TRUE))&&
    (!nzchar(query)||grepl(query,tolower(paste(p$id,p$name,p$category,p$description)),fixed=TRUE)),database())
  selected<-head(found[seq_along(found)>offset],limit)
  list(total=length(found),offset=offset,returned=length(selected),truncated=offset+length(selected)<length(found),
    results=unname(lapply(selected,function(p)c(p[intersect(names(p),c("id","name","source_db","organism","category"))],list(metabolite_count=length(p$metabolites))))))
})
resolve_database_sets <- function(ids) {
  ids<-text_vector(ids,"set_ids",200L,empty=TRUE)
  if(anyDuplicated(ids))fail("Duplicate set IDs")
  db<-database();index<-match(ids,vapply(db,function(p)p$id,character(1)))
  if(anyNA(index))fail("Unknown or excluded set ID")
  db[index]
}
member_ids <- function(p,identifier) {
  field<-switch(identifier,name="name",hmdb="hmdb_id",chebi="chebi_id",inchikey="inchikey",pubchem="pubchem_cid",fail("Unknown identifier namespace"))
  values<-vapply(p$metabolites,function(m)if(is.null(m[[field]]))""else as.character(m[[field]]),character(1))
  unique(normalize_ids(values[nzchar(values)],identifier))
}
get_sets <- function(set_ids,identifier="name",max_members=100L)safe_result({
  max_members<-scalar_integer(max_members,"max_members",1L,500L)
  normalize_ids(character(),identifier)
  sets<-resolve_database_sets(set_ids)
  if(!length(sets)||length(sets)>50L)fail("Choose 1-50 sets for retrieval")
  list(identifier=identifier,sets=unname(lapply(sets,function(p){
    ids<-member_ids(p,identifier)
    list(id=p$id,name=p$name,source=p$source_db,organism=p$organism,description=p$description,
      member_count=length(ids),members=as.list(head(ids,max_members)),truncated=length(ids)>max_members)
  })))
})
lookup_metabolites <- function(query,exact=TRUE,limit=25L)safe_result({
  query<-tolower(scalar_text(query,"query"))
  if(restricted_id(query))fail("Excluded identifier")
  if(!is.logical(exact)||length(exact)!=1L||is.na(exact))fail("exact must be boolean")
  limit<-scalar_integer(limit,"limit",1L,100L)
  found<-list();seen<-character()
  for(p in database())for(m in p$metabolites) {
    values<-tolower(as.character(unlist(m[intersect(names(m),c("id","name","hmdb_id","chebi_id","inchikey","pubchem_cid"))],use.names=FALSE)))
    match<-if(exact)any(values==query)else any(grepl(query,values,fixed=TRUE))
    key<-paste(m$id,m$name,m$inchikey,sep="|")
    if(match&&!key %in% seen) {seen<-c(seen,key);found[[length(found)+1L]]<-list(metabolite=m,example_set=p$id,source=p$source_db)}
  }
  list(query=query,exact=exact,total_candidates=length(found),results=unname(head(found,limit)),truncated=length(found)>limit,
    matching="Case-insensitive literal matching only; no synonym, cross-species or structure equivalence is inferred.")
})
analysis_sets <- function(set_ids,custom_sets,identifier) {
  normalize_ids(character(),identifier)
  records<-resolve_database_sets(set_ids)
  M<-setNames(lapply(records,member_ids,identifier=identifier),vapply(records,function(p)p$id,character(1)))
  metadata<-setNames(lapply(records,function(p)list(name=p$name,source=p$source_db,organism=p$organism)),names(M))
  if(length(custom_sets)) {
    if(!is.list(custom_sets)||!identical(names(custom_sets),"sets")||!is.list(custom_sets$sets)||length(custom_sets$sets)>200L)fail("custom_sets must be a sets envelope")
    for(s in custom_sets$sets) {
      name<-scalar_text(s$name,"custom set name",max_length=100L)
      if(restricted_id(name)||name %in% names(M))fail("Excluded or duplicate custom set name")
      M[[name]]<-unique(normalize_ids(text_vector(s$members,"members",1000L),identifier))
      metadata[[name]]<-list(name=name,source="user",organism="user-specified")
    }
  }
  if(length(M)<2L||length(M)>200L)fail("Select 2-200 metabolite sets; upstream ORA requires at least two")
  if(any(lengths(M)==0L))fail("A selected set has no members in the chosen namespace")
  if(sum(lengths(M))>25000L||length(unique(unlist(M,use.names=FALSE)))>10000L)fail("Selected set collection exceeds 25000 memberships or 10000 unique IDs")
  list(M=M,metadata=metadata)
}

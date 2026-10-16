if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
args <- commandArgs(trailingOnly=TRUE)
input <- if(length(args)) args[[1]] else ".reference/default_pathways.json"
stopifnot(file.exists(input))
raw <- jsonlite::fromJSON(input,simplifyVector=FALSE)
is_restricted <- function(x) any(grepl("kegg|^[CDGR][0-9]{5}$|^(hsa|map|ko)[0-9]{5}$",as.character(x),ignore.case=TRUE))
sources <- c("Reactome","PathBank","WikiPathways","integMET","ILDMDB","MACdb","ProMENDA","MetSigDis")
excluded <- c(source=0L,metadata=0L,metabolite=0L)
crossrefs_removed <- 0L
filtered <- list()
for(p in raw) {
  if(!p$source_db %in% sources) {excluded[["source"]]<-excluded[["source"]]+1L;next}
  meta <- p[intersect(names(p),c("id","name","source_db","organism","category","description","updated_at"))]
  if(is_restricted(unlist(meta,use.names=FALSE))) {excluded[["metadata"]]<-excluded[["metadata"]]+1L;next}
  members <- list()
  for(m in p$metabolites) {
    if(!is.null(m$kegg_id) && nzchar(m$kegg_id)) crossrefs_removed<-crossrefs_removed+1L
    clean <- m[intersect(names(m),c("name","hmdb_id","chebi_id","pubchem_cid","inchikey","formula"))]
    clean <- Filter(function(x)!is.null(x)&&length(x)==1L&&nzchar(as.character(x))&&!is_restricted(x),clean)
    candidates <- c(if(!is_restricted(m$id))m$id,unlist(clean[c("hmdb_id","chebi_id","inchikey","pubchem_cid","name")],use.names=FALSE))
    candidates<-candidates[!is.na(candidates)&nzchar(candidates)]
    if(!length(candidates)||is.null(clean$name)) {excluded[["metabolite"]]<-excluded[["metabolite"]]+1L;next}
    clean$id<-as.character(candidates[[1]])
    members[[length(members)+1L]]<-clean
  }
  meta$metabolites<-members
  if(length(members)) filtered[[length(filtered)+1L]]<-meta
}
dir.create("data",showWarnings=FALSE)
con<-gzfile("data/catalog.json.gz","wb",compression=9)
writeLines(jsonlite::toJSON(filtered,auto_unbox=TRUE,null="null",digits=NA),con,useBytes=TRUE)
close(con)
manifest<-list(schema_version="1.0",upstream_repository="hiroyukiyamamoto/AI",
  upstream_commit="1fa2e6b7a479429e2842c60c15208d105e8473db",
  upstream_path="apps/mseapca-db-web/seed_data/default_pathways.json",
  upstream_blob="e51a166b71647a1bcdaf9c3ac0a3e9e393620c24",
  input_records=length(raw),retained_records=length(filtered),
  source_counts=as.list(table(vapply(filtered,function(x)x$source_db,character(1)))),
  excluded=as.list(excluded),removed_cross_references=crossrefs_removed,
  policy="Exclude KEGG-origin sets, restricted metadata, all KEGG cross-references and primary compound IDs. No built-in mseapca pathway data or upstream fallback exports are used.",
  license_note="Database sources retain their own terms. Non-KEGG does not imply unrestricted commercial use; see DATA_SOURCES.md.")
jsonlite::write_json(manifest,"data/manifest.json",auto_unbox=TRUE,pretty=TRUE)
cat(jsonlite::toJSON(manifest,auto_unbox=TRUE,pretty=TRUE),"\n")

analyze_ora <- function(significant,detected=list(),set_ids=list(),custom_sets=list(),identifier="name",
  method="det",lambda=5,max_results=50L)safe_result({
  if(!method %in% c("det","all","est_naive","est_weighted","est_shrink"))fail("Unknown ORA method")
  collection<-analysis_sets(set_ids,custom_sets,identifier);M<-collection$M
  SIG<-normalize_ids(text_vector(significant,"significant"),identifier)
  DET<-normalize_ids(text_vector(detected,"detected",10000L,empty=method=="all"),identifier)
  if(anyDuplicated(SIG)||anyDuplicated(DET))fail("Duplicate input IDs after normalization")
  universe<-unique(unlist(M,use.names=FALSE))
  if(method=="all") {if(!all(SIG %in% universe))fail("For all-background ORA, significant IDs must belong to the selected-set universe")}
  else if(!all(SIG %in% DET))fail("Significant IDs must be a subset of detected IDs")
  lambda<-scalar_number(lambda,"lambda",.000001,1000)
  limit<-scalar_integer(max_results,"max_results",1L,200L)
  fit<-mseapca::msea_ora(SIG,DET,M,option=method,lambda=lambda)
  summarize_fit(fit[[1]],collection,limit,"ora",list(method=method,identifier=identifier,significant_count=length(SIG),
    detected_count=length(DET),selected_sets=length(M),multiple_testing="Upstream Benjamini-Hochberg across all selected sets before output truncation",
    lambda=if(method=="est_shrink")lambda else NULL,detected_outside_selected_sets=sum(!DET %in% universe)),
    overlaps=fit[["significant metabolites"]],tables=fit[["Contingency tables"]])
})
summarize_fit <- function(result,collection,limit,analysis,conditions,overlaps=NULL,tables=NULL) {
  result<-as.matrix(result)
  order<-order(if(ncol(result)==3L&&analysis=="msea")result[,2]else result[,1],na.last=TRUE)
  index<-head(order,limit)
  rows<-lapply(index,function(i){
    id<-rownames(result)[[i]]
    row<-list(set_id=id,metadata=collection$metadata[[id]],statistics=setNames(lapply(result[i,],finite_value),colnames(result)))
    if(!is.null(overlaps)) {v<-overlaps[[id]];row$overlap_count<-length(v);row$overlap<-as.list(head(v,100L));row$overlap_truncated<-length(v)>100L}
    if(!is.null(tables))row$contingency_table<-matrix_input(tables[[id]])
    row
  })
  list(analysis=analysis,package_version=as.character(utils::packageVersion("mseapca")),conditions=conditions,
    total_results=nrow(result),returned_results=length(rows),truncated=nrow(result)>length(rows),results=unname(rows),
    nonfinite_statistics=sum(!is.finite(result)),interpretation="Exploratory enrichment; verify identifier mapping, biological context and study design.")
}
analyze_range <- function(significant,detected,set_ids=list(),custom_sets=list(),identifier="name",
  method="bino_naive",nsim=100L,lambda=5,probs=list(.025,.975),max_results=50L)safe_result({
  if(!method %in% c("ora_full","bino_naive","bino_weighted","bino_shrink"))fail("Unknown range method")
  collection<-analysis_sets(set_ids,custom_sets,identifier);M<-collection$M
  SIG<-normalize_ids(text_vector(significant,"significant"),identifier)
  DET<-normalize_ids(text_vector(detected,"detected",10000L),identifier)
  if(anyDuplicated(SIG)||anyDuplicated(DET)||!all(SIG %in% DET))fail("IDs must be unique and significant must be a subset of detected")
  if(is.list(probs)){if(any(lengths(probs)!=1L)||!all(vapply(probs,is.numeric,logical(1))))fail("probs must contain two numbers");probs<-unlist(probs)}
  if(!is.numeric(probs)||length(probs)!=2L||any(!is.finite(probs))||probs[1]<=0||probs[1]>=.5||probs[2]<=.5||probs[2]>=1)fail("probs must straddle 0.5 strictly between 0 and 1")
  nsim<-scalar_integer(nsim,"nsim",10L,1000L);lambda<-scalar_number(lambda,"lambda",.000001,1000)
  limit<-scalar_integer(max_results,"max_results",1L,200L)
  if(method=="ora_full"&&sum(vapply(M,function(m)length(setdiff(m,DET))+1L,integer(1)))>10000L)fail("Full enumeration exceeds 10000 configurations; choose binomial resampling or fewer sets")
  if(method!="ora_full"&&length(M)*nsim>100000L)fail("At most 100000 total simulations per request")
  fit<-mseapca::msea_ora_range(SIG,DET,M,option=method,probs=probs,nsim=nsim,lambda=lambda)
  summarize_fit(fit[[1]],collection,limit,"ora_range",list(method=method,identifier=identifier,selected_sets=length(M),
    nsim=if(method!="ora_full")nsim else NULL,seed=if(method!="ora_full")1L else NULL,
    randomization="The upstream binomial function resets its seed to 1; this wrapper does not override it.",
    range=if(method=="ora_full")"Minimum, median and maximum of full enumeration"else"Upstream binomial quantiles and median, not a validated coverage guarantee",
    probs=if(method!="ora_full")as.list(probs)else NULL,q_values="Not returned by upstream range functions"))
})
analyze_msea <- function(x,metabolite_ids,y,set_ids=list(),custom_sets=list(),identifier="name",maxiter=100L,seed=1L,max_results=50L)safe_result({
  X<-numeric_rows(x)
  ids<-normalize_ids(text_vector(metabolite_ids,"metabolite_ids",500L),identifier)
  if(length(ids)!=ncol(X)||anyDuplicated(ids)||any(apply(X,2,stats::sd)==0))fail("One unique ID per nonconstant feature column is required")
  if(is.list(y)){if(any(lengths(y)!=1L)||!all(vapply(y,is.numeric,logical(1))))fail("y must be numeric");y<-unlist(y,use.names=FALSE)}
  if(!is.numeric(y)||length(y)!=nrow(X)||any(!is.finite(y))||stats::sd(y)==0)fail("y must be a nonconstant finite numeric response per sample")
  collection<-analysis_sets(set_ids,custom_sets,identifier)
  hits<-vapply(collection$M,function(m)sum(ids %in% m),integer(1))
  excluded<-names(hits)[hits==0L]
  collection$M<-collection$M[hits>0L]
  if(length(collection$M)<2L||any(hits==length(ids)))fail("MSEA needs at least two overlapping sets, each covering fewer than all measured features")
  maxiter<-scalar_integer(maxiter,"maxiter",10L,1000L);seed<-scalar_integer(seed,"seed",0L,2147483646L)
  if(ncol(X)*length(collection$M)*maxiter>5000000L)fail("MSEA work limit: features x sets x maxiter <= 5000000")
  limit<-scalar_integer(max_results,"max_results",1L,200L)
  set.seed(seed)
  fit<-mseapca::msea_sub(collection$M,data.frame(id=ids,t(X),check.names=FALSE),y,maxiter=maxiter)
  summarize_fit(fit[[1]],collection,limit,"msea",list(identifier=identifier,samples=nrow(X),features=ncol(X),
    maxiter=maxiter,seed=seed,excluded_nonoverlapping_sets=as.list(excluded),selected_sets=length(collection$M),
    multiple_testing="Upstream permutation-based q-values, not Benjamini-Hochberg",permutation="Metabolite-set membership; not sample/class labels"),overlaps=fit[[2]])
})
analyze_ssea <- function(samples,detected,set_ids=list(),custom_sets=list(),identifier="name")safe_result({
  if(!is.list(samples)||!identical(names(samples),"samples")||!is.list(samples$samples)||!length(samples$samples)||length(samples$samples)>100L)fail("samples must contain 1-100 named sample records")
  collection<-analysis_sets(set_ids,custom_sets,identifier)
  if(length(collection$M)*length(samples$samples)>10000L)fail("SSEA output exceeds 10000 scores")
  DET<-normalize_ids(text_vector(detected,"detected",10000L),identifier)
  if(anyDuplicated(DET))fail("Duplicate detected IDs")
  labels<-vapply(samples$samples,function(s)scalar_text(s$name,"sample name",100L),character(1))
  if(anyDuplicated(labels))fail("Sample names must be unique")
  lists<-lapply(samples$samples,function(s){ids<-normalize_ids(text_vector(s$members,"sample members",5000L),identifier);if(anyDuplicated(ids)||!all(ids %in% DET))fail("Sample IDs must be unique subsets of detected background");ids})
  if(sum(lengths(lists))>25000L)fail("SSEA exceeds 25000 sample memberships")
  fit<-as.matrix(mseapca::ssea_ora(lists,DET,collection$M))
  list(analysis="ssea_ora",conditions=list(identifier=identifier,background_count=length(DET),sample_count=length(lists),
    selected_sets=length(collection$M),score="Negative natural logarithm of the per-sample ORA p-value; not expression-based ssGSEA/GSVA"),
    samples=as.list(labels),set_ids=as.list(names(collection$M)),
    scores=list(rows=unname(lapply(seq_len(nrow(fit)),function(i)lapply(fit[i,],finite_value)))),nonfinite_scores=sum(!is.finite(fit)))
})
demo_data <- function(dataset="fasting")safe_result({
  if(!dataset %in% c("fasting","membership"))fail("dataset must be fasting or membership")
  if(dataset=="fasting") {
    env<-new.env(parent=baseenv());utils::data(list="fasting",package="loadings",envir=env)
    X<-as.matrix(env$fasting$X);ids<-colnames(X)
    fit<-loadings::pca_loading(stats::prcomp(X,center=TRUE,scale.=TRUE))
    SIG<-ids[fit$loading$R[,1]>0&fit$loading$p.value[,1]<.05]
    measured<-normalize_ids(ids,"name")
    candidates<-Filter(function(p)p$source_db=="Reactome",database())
    hits<-vapply(candidates,function(p)sum(measured %in% member_ids(p,"name")),integer(1))
    candidates<-candidates[hits>=2L&hits<length(measured)]
    counts<-hits[hits>=2L&hits<length(measured)]
    selected<-head(candidates[order(-counts,vapply(candidates,function(p)p$id,character(1)))],20L)
    if(length(selected)<2L||!length(SIG))fail("Real-data demo cannot find compatible non-excluded sets")
    list(description="Full packaged mouse-liver fasting metabolome: 10 samples, 282 metabolites. PC1 positive-loading p<0.05 defines the illustrative significant list.",
      dataset="loadings::fasting",identifier="name",set_ids=as.list(vapply(selected,function(p)p$id,character(1))),
      significant=as.list(SIG),detected=as.list(ids),x=matrix_input(X),metabolite_ids=as.list(ids),y=as.list(unname(fit$x[,1])),method="det",
      reference="https://doi.org/10.1186/1471-2105-15-51",source_commit=source_manifest()$upstream_commit,
      matching="Exact case-insensitive names only; the 20 reference sets with greatest detected coverage were selected without using significance.",
      caveat="The supplied Reactome snapshot is human; applying it to mouse metabolites is an illustrative software example, not validated cross-species biological inference. PCA sign is arbitrary; exploratory p-values are unadjusted when selecting the input list.")
  } else {
  # A deterministic database-membership example, not fabricated experimental data.
  candidates<-Filter(function(p)p$source_db=="Reactome"&&length(member_ids(p,"chebi"))>=4L&&length(member_ids(p,"chebi"))<=20L,database())
  selected<-head(candidates,4L)
  if(length(selected)<2L)fail("Demo catalog is unavailable")
  ids<-vapply(selected,function(p)p$id,character(1))
  M<-lapply(selected,member_ids,identifier="chebi")
  DET<-unique(unlist(M,use.names=FALSE));SIG<-head(M[[1]],2L)
  list(description="Illustrative Reactome-membership ORA example. Selected IDs are chosen deterministically, not measured differential metabolites.",
    identifier="chebi",set_ids=as.list(ids),significant=as.list(SIG),detected=as.list(DET),method="det",
    source_commit=source_manifest()$upstream_commit,source="Filtered user-provided database; no bundled pathway data")
  }
})

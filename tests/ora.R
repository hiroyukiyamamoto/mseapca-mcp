if(dir.exists(".library")) .libPaths(c(normalizePath(".library"),.libPaths()))
source("R/utils.R");source("R/database.R");source("R/analysis.R")
sets<-list(sets=list(list(name="setA",members=as.list(c("a","b","c"))),list(name="setB",members=as.list(c("c","d","e")))))
result<-analyze_ora(c("a","b"),letters[1:8],custom_sets=sets)
stopifnot(result$ok,result$total_results==2L)
reference<-mseapca::msea_ora(c("a","b"),letters[1:8],list(setA=c("a","b","c"),setB=c("c","d","e")))
for(row in result$results)stopifnot(isTRUE(all.equal(unlist(row$statistics),unname(reference[[1]][row$set_id,]),check.attributes=FALSE)))
stopifnot(!analyze_ora("x","a",custom_sets=sets)$ok,
  !analyze_ora("C00031","C00031",custom_sets=sets)$ok,
  !analyze_ora("a",letters[1:8],set_ids=list("hsa00010"))$ok)
cat("First ORA MVP: official numerical comparison and invalid/excluded input checks passed.\n")

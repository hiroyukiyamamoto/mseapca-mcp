source("tests/ora.R")
M<-list(setA=c("a","b","z"),setB=c("c","d","e"),setC=c("f","g","h"))
sets<-list(sets=lapply(names(M),function(n)list(name=n,members=as.list(M[[n]]))))
check<-function(result,ref){
  stopifnot(result$ok)
  for(row in result$results){expected<-ref[row$set_id,];actual<-unlist(row$statistics,use.names=FALSE);valid<-is.finite(expected)
    stopifnot(isTRUE(all.equal(as.numeric(actual[valid]),as.numeric(expected[valid]),tolerance=1e-10)),all(actual[!valid]=="not_finite"))}
}
for(method in c("det","all","est_naive","est_weighted","est_shrink")) {
  r<-analyze_ora(c("a","d"),letters[1:8],custom_sets=sets,method=method)
  check(r,mseapca::msea_ora(c("a","d"),letters[1:8],M,option=method,lambda=5)[[1]])
}
for(method in c("ora_full","bino_naive","bino_weighted","bino_shrink")) {
  r<-analyze_range(c("a","d"),letters[1:8],custom_sets=sets,method=method,nsim=10L)
  check(r,mseapca::msea_ora_range(c("a","d"),letters[1:8],M,option=method,nsim=10L)[[1]])
}
set.seed(42);X<-matrix(rnorm(80),10,8);y<-1:10
r<-analyze_msea(matrix_input(X),letters[1:8],y,custom_sets=sets,maxiter=20L,seed=7L)
set.seed(7);ref<-mseapca::msea_sub(M,data.frame(id=letters[1:8],t(X)),y,maxiter=20L)
check(r,ref[[1]])
samples<-list(samples=list(list(name="s1",members=list("a","d")),list(name="s2",members=list("b","e"))))
r<-analyze_ssea(samples,letters[1:8],custom_sets=sets)
stopifnot(r$ok,isTRUE(all.equal(do.call(rbind,lapply(r$scores$rows,unlist)),unname(mseapca::ssea_ora(list(c("a","d"),c("b","e")),letters[1:8],M)),check.attributes=FALSE)))
demo<-demo_data();stopifnot(demo$ok,analyze_ora(demo$significant,demo$detected,demo$set_ids,identifier=demo$identifier)$ok)
stopifnot(!analyze_range("a","a",custom_sets=sets,nsim=1)$ok,
 !analyze_msea(matrix_input(X),letters[1:8],rep(1,10),custom_sets=sets)$ok,
 !analyze_ssea(samples,"a",custom_sets=sets)$ok)
cat("All five ORA modes, four range modes, MSEA, SSEA and real-catalog demo matched official functions.\n")

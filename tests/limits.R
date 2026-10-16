source("tests/ora.R")
# Bounds reject work before invoking expensive upstream computations.
stopifnot(!analyze_ora("a",letters[1:8],custom_sets=sets,max_results=201)$ok,
 !analyze_ora("a",letters[1:8],set_ids=list("unknown-set"))$ok,
 !analyze_ora(c("a","A"),letters[1:8],custom_sets=sets)$ok,
 !analyze_range("a",letters[1:8],custom_sets=sets,nsim=1001)$ok,
 !analyze_msea(list(rows=rep(list(as.list(1:501)),4)),as.list(paste0("x",1:501)),1:4,custom_sets=sets)$ok)
a<-analyze_ora(c("a","b"),letters[1:8],custom_sets=sets,max_results=1)
b<-analyze_ora(c("a","b"),letters[1:8],custom_sets=sets,max_results=2)
stopifnot(a$ok,a$truncated,identical(a$results[[1]]$statistics,b$results[[1]]$statistics))
d<-demo_data();m<-analyze_msea(d$x,d$metabolite_ids,d$y,d$set_ids,maxiter=10L)
stopifnot(m$ok)
cat("Input/compute/output bounds, correction before truncation and real-metabolome MSEA passed.\n")

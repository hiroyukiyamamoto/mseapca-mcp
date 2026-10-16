if (dir.exists(".library")) .libPaths(c(normalizePath(".library"), .libPaths()))
run_http_test <- function() {
  port <- httpuv::randomPort()
  server <- callr::r_bg(function(root, lib, port) {
    setwd(root); .libPaths(lib); Sys.setenv(PORT = port); source("R/server.R")
  }, args = list(getwd(), .libPaths(), port), stdout = "|", stderr = "|")
  on.exit(server$kill(), add = TRUE)
  url <- sprintf("http://127.0.0.1:%d/mcp", port)
  for (i in seq_len(100)) {
    if (!server$is_alive()) stop(paste(server$read_all_error(), collapse = "\n"))
    ready <- tryCatch({ httr2::request(url) |> httr2::req_error(is_error = function(resp) FALSE) |> httr2::req_perform(); TRUE }, error = function(e) FALSE)
    if (ready) break
    Sys.sleep(0.1)
  }
  config <- tempfile(fileext = ".json")
  on.exit(unlink(config), add = TRUE)
  jsonlite::write_json(list(mcpServers = list(loadings = list(url = url))), config, auto_unbox = TRUE)
  # Official MCP client performs initialization, tools/list and tools/call.
  tools <- mcptools::mcp_tools(config)
  names(tools) <- vapply(tools, function(t) t@name, character(1))
  stopifnot(length(tools)==9L,!any(grepl("execute|eval|shell",names(tools))))
  decode<-function(r){if(inherits(r,"ellmer::ContentToolResult"))r<-r@value;if(is.character(r))r<-jsonlite::fromJSON(r,simplifyVector=FALSE);r}
  call<-function(name,args=list())decode(do.call(tools[[name]],args))
  stopifnot(call("catalog_info")$ok,call("search_sets",list(query="glucose"))$ok,
    call("lookup_metabolites",list(query="glucose"))$ok)
  demo<-call("demo_data")
  stopifnot(demo$ok,call("get_sets",list(set_ids=demo$set_ids[1:2]))$ok)
  result<-call("analyze_ora",list(significant=demo$significant,detected=demo$detected,set_ids=demo$set_ids))
  stopifnot(result$ok,length(result$results)>0)
  source("R/utils.R");source("R/database.R");source("R/analysis.R")
  local<-demo_data();stopifnot(isTRUE(all.equal(unlist(local$x),unlist(demo$x),tolerance=1e-12)))
  sets<-list(sets=list(list(name="a",members=list("a","b","z")),list(name="b",members=list("c","d","e")),list(name="c",members=list("f","g","h"))))
  stopifnot(call("analyze_range",list(significant=list("a","d"),detected=as.list(letters[1:8]),custom_sets=sets,nsim=10L))$ok)
  set.seed(4);x<-matrix_input(matrix(rnorm(80),10,8))
  stopifnot(call("analyze_msea",list(x=x,metabolite_ids=as.list(letters[1:8]),y=as.list(1:10),custom_sets=sets,maxiter=10L))$ok)
  stopifnot(call("analyze_ssea",list(samples=list(samples=list(list(name="s1",members=list("a","d")))),detected=as.list(letters[1:8]),custom_sets=sets))$ok)
  stopifnot(!call("analyze_ora",list(significant=list("C00031"),detected=list("C00031"),custom_sets=sets))$ok)
  cat("Official HTTP MCP client: initialization, nine tools, all analyses, precision and invalid inputs passed.\n")
}
run_http_test()

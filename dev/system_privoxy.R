

# privoxy_search_path can be automated to some extent

find_privoxy <- function(privoxy_search_path){

  if(missing(privoxy_search_path)){
   ppaths <- c(Sys.getenv("ProgramFiles(x86)"),Sys.getenv("ProgramFiles"))
   ppaths <- ppaths[nchar(ppaths)>0]
   if(length(ppaths)>0){
     privoxy_search_path <- list.files(ppaths,"Privoxy", full.names = TRUE)
   }
  }

  found <- FALSE

  privoxy_path <- list.files(privoxy_search_path, pattern = "privoxy.exe", recursive = TRUE, full.names = TRUE)

  privoxy_res_path <- list.files(dirname(privoxy_path), full.names = TRUE)
  d <- file.info(privoxy_res_path)
  d$fn <- privoxy_res_path

  privoxy_res_path <- d$fn[!d$isdir& d$exe=="no"]
  privoxy_res_path <- privoxy_res_path[!grepl("config.txt",privoxy_res_path)]

  if(length(privoxy_path)>0) found <- TRUE

  pconfig_path <- list.files(privoxy_search_path, pattern = "config.txt", recursive = TRUE, full.names = TRUE)
  pconfig_path <- pconfig_path[grepl("^config.txt$",basename(pconfig_path))]
  if(length(pconfig_path)>0){
    pconfig_path <- pconfig_path[1]
  }


  list(found = found, privoxy_path = privoxy_path, privoxy_config_path = pconfig_path, privoxy_resource_paths = privoxy_res_path)


}

start_privoxy <- function(privoxy_search_path){

  ploc <- find_privoxy(privoxy_search_path)

  if(!ploc$found){
    stop("Privoxy not found.\n", call. = FALSE)
  }

  internal_dep_wdman <- asNamespace("wdman")

  internal_dep_fisher <- asNamespace("fisher")

  # check port 8228
  pid_port_map <- internal_dep_fisher$sys_get_pid_port_map()
  if(8228 %in% pid_port_map$port){
    try(ps::ps_kill(ps::ps_handle(pid_port_map$pid[pid_port_map$port==8228L])),
        silent = TRUE)
  }

  of <- tempfile(pattern = "out_")
  ef <- tempfile(pattern = "error_")

  # edit config
  ptdir <- tempfile(pattern = "privoxy_dir")
  dir.create(ptdir, showWarnings = FALSE, recursive = TRUE)

  # copy resources

  file.copy(ploc$privoxy_resource_paths, ptdir)

  config_txt <- file.path(ptdir, "config.txt")

  existing_config <- readLines(ploc$privoxy_config_path, warn = FALSE)
  existing_config <- existing_config[!grepl("^#",existing_config)]

  # remove these lines

  existing_config_put <- existing_config[!grepl("confdir|logdir|forward-socks5t|listen-address",existing_config)]

  existing_config_put <- c(
    paste0("confdir ", normalizePath(ptdir)),
    paste0("logdir ", normalizePath(ptdir)),
    paste0("listen-address ","127.0.0.1:8228"),
    paste0("forward-socks5t   /               ","127.0.0.1:9050"," ."),
    existing_config_put
  )

  writeLines(existing_config_put, config_txt)

  h <- internal_dep_wdman$spawn_tofile(
    command = normalizePath(ploc$privoxy_path[1]),
    args = paste0(' "',normalizePath(config_txt),'"'),
    outfile = of, errfile = ef
  )

  list(
    process = h,
    read_log = function(){
      readLines(of, warn = FALSE)
    },
    read_error = function(){
      readLines(ef, warn = FALSE)
    }
  )

}

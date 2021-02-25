
# for windows

find_tor <- function(tor_search_path){

  found <- FALSE

  tor_path <- list.files(tor_search_path, pattern = "tor.exe", recursive = TRUE, full.names = TRUE)

  if(length(tor_path)>0) found <- TRUE

  torrc_path <- list.files(tor_search_path, pattern = "torrc", recursive = TRUE, full.names = TRUE)
  torrc_path <- torrc_path[grepl("^torrc$",basename(torrc_path))]
  if(length(torrc_path)>0){
    torrc_path <- torrc_path[1]
  }


  list(found = found, tor_path = tor_path, torrc_path = torrc_path)


}

start_tor <- function(tor_search_path){

  tloc <- find_tor(tor_search_path)

  if(!tloc$found){
    stop("Tor not found.\n", call. = FALSE)
  }

  # only cmd
  # cmd<- paste0('"',normalizePath(tor_path[1]),'"', ' -f "',normalizePath(torrc_path),'"')

  internal_dep_wdman <- asNamespace("wdman")

  internal_dep_fisher <- asNamespace("fisher")

  # check port 9050
  pid_port_map <- internal_dep_fisher$sys_get_pid_port_map()
  if(9050 %in% pid_port_map$port){
    ps::ps_kill(ps::ps_handle(pid_port_map$pid[pid_port_map$port==9050L]))
  }

  of <- tempfile(pattern = "out_")
  ef <- tempfile(pattern = "error_")

  if(length(tloc$torrc_path)==1){
    h <- internal_dep_wdman$spawn_tofile(
      command = normalizePath(tloc$tor_path[1]),
      args = paste0(' -f "',normalizePath(tloc$torrc_path),'"'),
      outfile = of, errfile = ef
    )
  }else{
    h <- internal_dep_wdman$spawn_tofile(
      command = normalizePath(tloc$tor_path[1]),
      args = character(0),
      outfile = of, errfile = ef
    )
  }

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


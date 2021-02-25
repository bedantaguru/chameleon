# setup_framework

setup_framework_core_re_run <- function(
  f, in_wd = FALSE, env = FALSE){
  emb <- list()
  emb$tmpfile.f <- tempfile(pattern = "func_")
  emb$tmpfile.r <- tempfile(pattern = "run_")

  if(in_wd){
    # cleanup
    # unlink(list.files(all.files = T, pattern = ".tmp.afterRestartComm"),
    # recursive = T)
    emb$tmpfile.f <- paste0(".tmp.afterRestartComm_", basename(emb$tmpfile.f))
    emb$tmpfile.r <- paste0(".tmp.afterRestartComm_", basename(emb$tmpfile.r))
  }

  emb$tmpfile.f <- normalizePath(
    emb$tmpfile.f, winslash = "/", mustWork = FALSE)
  emb$tmpfile.r <- normalizePath(
    emb$tmpfile.r, winslash = "/", mustWork = FALSE)
  saveRDS(f, emb$tmpfile.f)
  writeLines(c(
    paste0("f <- readRDS('",emb$tmpfile.f,"')"),
    ifelse(env, "f$run()", "f()"),
    paste0("unlink('",emb$tmpfile.f,"',recursive = TRUE, force = TRUE)"),
    paste0("unlink('",emb$tmpfile.r,"',recursive = TRUE, force = TRUE)")
  ),
  emb$tmpfile.r)

  invisible(
    list(
      file_info = emb,
      job = emb$tmpfile.r,
      comm = paste0("source('",emb$tmpfile.r,"')")
    )
  )
}

setup_framework_rs_reload_run <- function(
  f, clean_all = FALSE, env = FALSE){
  if(exists(".rs.restartR")){
    if(clean_all){
      rm(list = ls(envir = globalenv(), all.names = TRUE), envir = globalenv())
      Sys.sleep(0.1)
    }
    if(missing(f)){
      .rs.restartR()
    }else{
      .rs.restartR(
        afterRestartCommand =
          setup_framework_core_re_run(f, in_wd = TRUE, env = env)$comm)
    }
  }else{
    cat("\nNot in RStudio. Exiting\n")
  }
  invisible(0)
}

setup_framework_rs_job_run <- function(
  f, job_tag = "External Job", env = FALSE, wait = FALSE){
  if(exists(".rs.api.runScriptJob")){
    sp <- setup_framework_core_re_run(f, env = env)$job
    .rs.api.runScriptJob(
      path = sp,
      name = job_tag)
    if(wait){
      # wait for file to be deleted (as there is no other known way to track job
      # completion)
      t0 <- Sys.time()
      repeat{
        if(!file.exists(sp)) break()
        if(as.numeric(difftime(Sys.time(), t0, units = "mins"))>59){
          cat("\nSetup time out reached\n")
          break()
        }
        Sys.sleep(1)
      }
    }
  }else{
    cat("\nNot in RStudio. Exiting\n")
  }
  invisible(0)
}

setup_framework_install_run <- function(
  f,
  tag = "Setup Job",
  clean_all = TRUE,
  reload = TRUE)
{

  env <-NA

  if(is.function(f)){
    env <- FALSE
  }else{
    if(is.list(f)){
      if("run" %in% names(f)){
        env <- TRUE
        f <- list_to_environment(f)
      }
    }
  }

  if(is.na(env)){
    stop("Unknwon format for setup script", call. = FALSE)
  }

  # prefer job
  if(exists(".rs.api.runScriptJob")){
    setup_framework_rs_job_run(f, job_tag = tag, env = env, wait = reload)
    if(reload){
      setup_framework_rs_reload_run(clean_all = clean_all)
    }else{
      cat("\nAfter the setup please (possibly) restart R-Session for effect\n")
    }
    return(invisible(0))
  }else{
    setup_framework_rs_reload_run(f,clean_all = clean_all, env = env)
  }

  invisible(0)

}


list_to_environment <- function(l){

  e <- new.env()

  for(elm in names(l)){
    e[[elm]] <- l[[elm]]
    environment(e[[elm]]) <- e
  }

  e
}

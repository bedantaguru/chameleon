

# https://github.com/richfitz/stevedore
# https://github.com/richfitz/stevedore/issues/46

#reticulate::conda_create(envname = "r-fisher", packages = c("python=3.7","numpy"))
reticulate::conda_create(envname = "r-fisher", packages = c("python","numpy"))

reticulate::use_condaenv(condaenv = "r-fisher")

reticulate::py_available(initialize = T)

reticulate::py_config()

# https://stackoverflow.com/questions/45954528/pip-is-configured-with-locations-that-require-tls-ssl-however-the-ssl-module-in
# in case fail

# https://github.com/docker/docker-py/pull/1871
# https://github.com/twosixlabs/armory/issues/156
reticulate::conda_install(envname = "r-fisher", packages = c("docker","pypiwin32"), pip = TRUE)


post_inst <- file.path(reticulate::py_config()$pythonhome,"Scripts", "pywin32_postinstall.py")

if(file.exists(post_inst)){
  py_bin <- reticulate::py_config()$python
  system(paste0(py_bin, " ", post_inst, " -install"))
}

stevedore:::httppipe_available(T)

reticulate::conda_remove(envname = "r-fisher")



#  approach two

reticulate::conda_create(envname = "r-fisher", packages = c("python","numpy","pywin32"))

reticulate::use_condaenv(condaenv = "r-fisher")

reticulate::py_available(initialize = T)

reticulate::py_config()

# https://stackoverflow.com/questions/45954528/pip-is-configured-with-locations-that-require-tls-ssl-however-the-ssl-module-in
# in case fail

# https://github.com/docker/docker-py/pull/1871
# https://github.com/twosixlabs/armory/issues/156
reticulate::conda_install(envname = "r-fisher", packages = c("docker","pypiwin32"), pip = TRUE)




# fixed version not working
setup_stevedore <- function(fixed_version = FALSE){

  reticulate::py_available()

  if(fixed_version){
    reticulate::conda_create(envname = "r-fisher", packages = c("python","numpy","pywin32"))
  }else{
    reticulate::conda_create(envname = "r-fisher", packages = c("python=3.9","numpy"))
    reticulate::conda_create(envname = "r-fisher", packages = c("pywin32=227"))
  }


  reticulate::use_condaenv(condaenv = "r-fisher")

  reticulate::py_available(initialize = T)

  reticulate::py_config()

  # in case fail
  # https://stackoverflow.com/questions/45954528/pip-is-configured-with-locations-that-require-tls-ssl-however-the-ssl-module-in
  # https://github.com/twosixlabs/armory/issues/156

  if(fixed_version){
    reticulate::conda_install(envname = "r-fisher", packages = c("docker==4.4.0","pypiwin32==223"), pip = TRUE)
  }else{
    reticulate::conda_install(envname = "r-fisher", packages = c("docker","pypiwin32"), pip = TRUE)
  }
}



make_ready_r_fisher_windows <- function(){

  reticulate::conda_create(envname = "r-fisher", packages = c("python","numpy","pywin32"))

  reticulate::use_condaenv(condaenv = "r-fisher")

  reticulate::py_available(initialize = TRUE)

  reticulate::py_config()

  # in case fail
  # https://stackoverflow.com/questions/45954528/pip-is-configured-with-locations-that-require-tls-ssl-however-the-ssl-module-in
  # https://github.com/twosixlabs/armory/issues/156

  reticulate::conda_install(envname = "r-fisher", packages = c("docker","pypiwin32"), pip = TRUE)

}


core_re_run <- function(f, in_wd = FALSE){
  emb <- list()
  emb$tmpfile.f <- tempfile(pattern = "func_")
  emb$tmpfile.r <- tempfile(pattern = "run_")

  if(in_wd){
    # cleanup
    # unlink(list.files(all.files = T, pattern = ".tmp.afterRestartComm"), recursive = T)
    emb$tmpfile.f <- paste0(".tmp.afterRestartComm_", basename(emb$tmpfile.f))
    emb$tmpfile.r <- paste0(".tmp.afterRestartComm_", basename(emb$tmpfile.r))
  }

  emb$tmpfile.f <- normalizePath(emb$tmpfile.f, winslash = "/", mustWork = FALSE)
  emb$tmpfile.r <- normalizePath(emb$tmpfile.r, winslash = "/", mustWork = FALSE)
  saveRDS(f, emb$tmpfile.f)
  writeLines(c(
    paste0("f <- readRDS('",emb$tmpfile.f,"')"),
    "f()",
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

rs_reload_run <- function(f, clean_all = FALSE){
  if(exists(".rs.restartR")){
    if(clean_all){
      rm(list = ls(envir = globalenv(), all.names = TRUE), envir = globalenv())
      Sys.sleep(0.1)
    }
    .rs.restartR(afterRestartCommand = core_re_run(f, in_wd = TRUE)$comm)
  }else{
    cat("\nNot in RStudio. Exiting\n")
  }
  invisible(0)
}

rs_job_run <- function(f, job_tag = "External Job"){
  if(exists(".rs.api.runScriptJob")){
    .rs.api.runScriptJob(path = core_re_run(f)$job, name = job_tag)
  }else{
    cat("\nNot in RStudio. Exiting\n")
  }
  invisible(0)
}

setup_stevedore_windows <- function(reload = FALSE){

  if(stevedore::docker_available()){
    cat("\n<docker_available> doing nothing\n")
    return(invisible(0))
  }

  if(reticulate::py_available()){
    if(exists(".rs.restartR")|exists(".rs.api.runScriptJob")){
      cat("\nPython loaded need to restart R-session or Start job\n")

      cat("\nRemoving env <r-fisher> is present.\n")
      reticulate::conda_remove("r-fisher")

      # prefer job
      if(exists(".rs.api.runScriptJob") & !reload){
        rs_job_run(make_ready_r_fisher_windows, job_tag = "Python conda env installation <r-fisher>")
        cat("\nAfter the setup please restart R-Session for effect\n")
        return(invisible(0))
      }else{
        rs_reload_run(make_ready_r_fisher_windows)
      }

    }else{
      cat("\nNot in RStudio. Restart R manually. Before loading {reticulate} try again.\n")
      return(invisible(0))
    }
  }else{
    make_ready_r_fisher_windows()
    return(invisible(0))
  }

}



dc <- stevedore::docker_client()

#dc$image$pull("igayen/privoxy-proton")

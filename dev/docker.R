
# ensure_docker_access

conda_is_fisher_present <- function(){
  cl <- reticulate::conda_list()
  "r-fisher" %in% cl$name
}

conda_is_fisher_loaded <- function(){
  out <- FALSE
  if(reticulate::py_available()){
    x <- reticulate::py_config()
    if(grepl("r-fisher",x$python)) out <- TRUE
  }
  out
}

conda_if_no_fisher_error<- function(){
  if(reticulate::py_available() & !conda_is_fisher_loaded()){
    stop(paste0(
      "{reticulate} loaded different conda environment.",
      " You need to restart R session."),
      call. = FALSE)
  }
}

conda_enable_fisher<- function(){

  if(reticulate::py_available()){
    conda_if_no_fisher_error()
  }else{
    reticulate::use_condaenv(condaenv = "r-fisher")

    reticulate::py_available(initialize = TRUE)

    conda_if_no_fisher_error()
  }
}

conda_fisher_create_with_docker <- function(fresh = FALSE){

  conda_if_no_fisher_error()

  fp <- conda_is_fisher_present()
  if(fp){
    if(fresh){
      reticulate::conda_remove(envname = "r-fisher")
    }
  }else{
    fresh <- TRUE
  }

  if(fresh){
    reticulate::conda_create(
      envname = "r-fisher",
      packages = c(
        # required by default + for {reticulate}
        "python","numpy",

        # required for {fisher} [note this can be outdated. Either there has to
        # be a mechanism or it has to be well managed by fisher]
        "selenium")
    )
  }

  reticulate::conda_install(envname = "r-fisher", packages = c("pywin32"))

  conda_enable_fisher()

  reticulate::conda_install(envname = "r-fisher", packages = c("docker","pypiwin32"), pip = TRUE)

  invisible(0)

}

conda_setup_stevedore_windows <- function(){

  if(conda_is_fisher_present()){

    conda_enable_fisher()

    if(stevedore::docker_available()){
      cat("\n<docker_available> doing nothing\n")
      return(invisible(0))
    }
  }



  if(reticulate::py_available()){
    if(conda_is_fisher_loaded()){
      conda_fisher_create_with_docker()
      try(detach("package:stevedore", unload = TRUE), silent = TRUE)
      return(invisible(0))
    }else{
      setup_framework_install_run(
        list(run = function() conda_fisher_create_with_docker(),
             conda_fisher_create_with_docker = conda_fisher_create_with_docker,
             conda_enable_fisher = conda_enable_fisher,
             conda_if_no_fisher_error = conda_if_no_fisher_error,
             conda_is_fisher_loaded = conda_is_fisher_loaded,
             conda_is_fisher_present = conda_is_fisher_present),
        tag = "Python conda env installation <r-fisher>")
    }
  }else{
    conda_fisher_create_with_docker()
    try(detach("package:stevedore", unload = TRUE), silent = TRUE)
    return(invisible(0))
  }

}


library(tidyverse)

workflows <- yaml::yaml.load(
  system("viash ns list -q '^workflows/(?!test_workflows)'", intern = TRUE)
)

outs <- map_df(workflows, function(wf) {
  cat("Running ", wf$namespace, "/", wf$name, "\n", sep = "")

  dir <- dirname(wf$build_info$config)
  tests <- wf$test_resources %>% keep(~ .$type == "nextflow_script")

  if (length(tests) == 0) {
    tibble(
      namespace = wf$namespace,
      functionality = wf$name,
      runner = "native",
      test_name = "tests",
      exit_code = -1L,
      duration = 0L,
      result = "MISSING"
    )
  } else {
    map_df(
      tests,
      function(test) {
        if (file.exists(paste0(dir, "/graph.dot"))) {
          file.remove(paste0(dir, "/graph.dot"))
        }
        args <- c(
          "run", ".",
          "-main-script", paste0(dir, "/", test$path),
          "-entry", test$entrypoint,
          "-profile", "docker,mount_temp,no_publish",
          "-with-dag", paste0(dir, "/graph.dot"),
          "-c", "src/workflows/utils/integration_tests.config",
          "-c", "src/workflows/utils/labels_ci.config",
          "-resume"
        )

        start_time <- Sys.time()
        out <- processx::run(
          "nextflow",
          args = args,
          error_on_status = FALSE,
          env = c("current", NXF_VER = "24.04.4")
        )
        stop_time <- Sys.time()
        duration <- ceiling(
          as.numeric(difftime(stop_time, start_time, unit = "sec"))
        )
        result <- if (out$status > 0) "FAILED" else "SUCCESS"
        if (out$status > 0) {
          cat(
            "========================== ERROR LOG ==========================\n",
            out$stdout,
            "===============================================================\n",
            sep = ""
          )
        }

        tibble(
          namespace = wf$namespace,
          functionality = wf$name,
          runner = "native",
          test_name = paste0(basename(test$path), "$", test$entrypoint),
          exit_code = out$status,
          duration = duration,
          result = result
        )
      }
    )
  }
})

write_tsv(outs, ".viash_log_integration.tsv")

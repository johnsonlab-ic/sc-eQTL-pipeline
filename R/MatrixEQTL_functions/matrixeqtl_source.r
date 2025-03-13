calculate_ciseqtl <- function(exp_mat, 
geno_mat, 
exp_loc, 
geno_loc, 
covmat = NULL, 
name = "celltype", 
cisDist = 1e6, 
pvOutputThreshold = 0, 
filter_trans_FDR = FALSE, 
pvOutputThreshold_cis = 1, 
optimize_pcs = FALSE, 
save_results = TRUE) {

  library(MatrixEQTL)
  library(data.table)
  library(dplyr)
  library(ggplot2)
  
  # Create SNP input
  geno_meqtl <- MatrixEQTL::SlicedData$new()
  geno_meqtl$CreateFromMatrix(as.matrix(geno_mat))
  
  expr_meqtl <- MatrixEQTL::SlicedData$new()
  expr_meqtl$CreateFromMatrix(as.matrix(exp_mat))

  
  if (!is.null(covmat)) {
    message("Including covariates (covmat != 'NULL').")
    covs <- rownames(covmat)
    message("Covs used: ", paste0(covs, sep = ", "))
    
    covs_meqtl <- MatrixEQTL::SlicedData$new()
    covs_meqtl$CreateFromMatrix(as.matrix(covmat))
    saveRDS(covmat, paste0(name, "_covs_used.rds"))
  } else {
    covs_meqtl <- MatrixEQTL::SlicedData$new()
  }
  
  # if (!optimize_pcs) {
    me <- MatrixEQTL::Matrix_eQTL_main(
      geno_meqtl,
      expr_meqtl,
      cvrt = covs_meqtl,
      useModel = MatrixEQTL::modelLINEAR,
      errorCovariance = numeric(),
      verbose = TRUE,
      output_file_name = NULL,
      output_file_name.cis = NULL,
      pvOutputThreshold.cis = pvOutputThreshold_cis,
      pvOutputThreshold = pvOutputThreshold,
      snpspos = geno_loc,
      genepos = exp_loc,
      cisDist = cisDist,
      pvalue.hist = FALSE,
      min.pv.by.genesnp = FALSE,
      noFDRsaveMemory = FALSE
    )
    return(me$cis$eqtls)
    # if (save_results) {
    #   save_eqtls <- function(eqtls, prefix) {
    #     if (!is.null(eqtls) && nrow(eqtls) > 0) {
    #       names(eqtls)[names(eqtls) == "statistic"] <- "t.stat"
    #       names(eqtls)[names(eqtls) == "pvalue"] <- "p.value"
    #       names(eqtls)[names(eqtls) == "snps"] <- "SNP"
    #       saveRDS(eqtls, paste0(name, "_", prefix, "_MatrixEQTLout.rds"))
    #     }
    #   }
      
    #   if (pvOutputThreshold_cis > 0) {
    #     save_eqtls(me$cis$eqtls, "cis")
    #   }
      
    #   if (pvOutputThreshold > 0) {
    #     eqtls <- if (pvOutputThreshold_cis > 0) me$trans$eqtls else me$all$eqtls
    #     if (filter_trans_FDR) {
    #       eqtls <- eqtls[eqtls$FDR < 0.2, ]
    #     }
    #     save_eqtls(eqtls, "trans_0.2FDR")
    #   }
    # }
    
    message(paste0("MatrixEQTL calculated for ", name, "."))
  # } else {
  #   message("Optimizing number of PCs to use..")
  #   best_num_pcs <- 0
  #   best_eqtls <- data.frame()  # Initialize with an empty data frame
  #   best_proportion_significant <- 0
  #   results <- data.frame(num_pcs = integer(), num_eqtls = integer())
    
  #   # Calculate PCs from the expression matrix
  #   pca <- prcomp(exp_mat, scale. = TRUE, center = TRUE)
  #   pcs <- pca$rotation
  #   max_pcs <- min(floor(ncol(pcs) / 10) * 10, n_indivs - 10, 100) 
  #   pcs <- pcs[, 1:max_pcs]
  #   pcs <- t(pcs)
  #   pcs <- pcs[, colnames(exp_mat)]
  #   # write.table(pcs, "pcs.txt")
    
  #   # Iterate over batches of 10 PCs, ensuring not to exceed the number of available PCs
  #   for (num_pcs in seq(10, min(ncol(pcs), max_pcs), by = 10)) {
  #     print(num_pcs)
  #     # Add PCs as covariates
  #     covs <- pcs[1:num_pcs, ]
  #   #   write.table(covs, "covs.txt")
  #   #   write.table(exp_mat, "exp_mat.txt")
  #     covs_meqtl <- MatrixEQTL::SlicedData$new()
  #     covs_meqtl$CreateFromMatrix(as.matrix(covs))
      
  #     # Run Matrix eQTL analysis
  #     me <- suppressMessages(MatrixEQTL::Matrix_eQTL_main(
  #       geno_meqtl,
  #       expr_meqtl,
  #       cvrt = covs_meqtl,
  #       useModel = MatrixEQTL::modelLINEAR,
  #       errorCovariance = numeric(),
  #       verbose = FALSE,
  #       output_file_name = NULL,
  #       output_file_name.cis = NULL,
  #       pvOutputThreshold.cis = pvOutputThreshold_cis,
  #       pvOutputThreshold = pvOutputThreshold,
  #       snpspos = geno_loc,
  #       genepos = exp_loc,
  #       cisDist = cisDist,
  #       pvalue.hist = FALSE,
  #       min.pv.by.genesnp = FALSE,
  #       noFDRsaveMemory = FALSE
  #     ))
      
  #     # Calculate the number of significant eQTLs (FDR < 0.05)
  #     if (pvOutputThreshold_cis > 0) {
  #       eqtls <- me$cis$eqtls
  #     } else {
  #       eqtls <- me$all$eqtls
  #     }
      
  #     if (!is.null(eqtls) && nrow(eqtls) > 0) {
  #       num_eqtls <- sum(eqtls$pvalue < 0.05)
        
  #       # Store the results
  #       results <- rbind(results, data.frame(num_pcs = num_pcs, num_eqtls = num_eqtls))
        
  #       # Update the best results if the current number of eQTLs is higher
  #       if (num_eqtls > best_proportion_significant) {
  #         best_proportion_significant <- num_eqtls
  #         best_num_pcs <- num_pcs
  #         best_eqtls <- eqtls
  #       }
  #     }
  #   }
  #   # saveRDS(eqtls,"eqtls.rds")
  #   # Save the best results
  #   if (save_results) {
  #     save_eqtls <- function(eqtls, prefix) {
  #       if (!is.null(eqtls) && nrow(eqtls) > 0) {
  #         names(eqtls)[names(eqtls) == "statistic"] <- "t.stat"
  #         names(eqtls)[names(eqtls) == "pvalue"] <- "p.value"
  #         names(eqtls)[names(eqtls) == "snps"] <- "SNP"
  #         saveRDS(eqtls, paste0(name, "_", prefix, "_MatrixEQTLout.rds"))
  #       }
  #     }
      
  #     if (pvOutputThreshold_cis > 0) {
  #       save_eqtls(best_eqtls, "cis")
  #     }
      
  #     if (pvOutputThreshold > 0) {
  #       eqtls <- if (pvOutputThreshold_cis > 0) best_eqtls else me$all$eqtls
  #       if (filter_trans_FDR) {
  #         eqtls <- eqtls[eqtls$FDR < 0.2, ]
  #       }
  #       save_eqtls(eqtls, "trans_0.2FDR")
  #     }
  #   }
    
    # Plot the number of eQTLs discovered per batch of 10 PCs
  #   plot_file <- paste0(name, "_num_eqtls_per_batch.png")
  #   ggplot(results, aes(x = num_pcs, y = num_eqtls)) +
  #     geom_line() +
  #     geom_point() +
  #     labs(title = "Number of eQTLs Discovered per Batch of 10 PCs",
  #          x = "Number of PCs",
  #          y = "Number of eQTLs") +
  #     theme_minimal() 
  #     ggsave(plot_file)
    
  #   message(paste0("MatrixEQTL calculated for ", name, " with ", best_num_pcs, " PCs."))
  # }
}
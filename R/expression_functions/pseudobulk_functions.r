# Import the pipe operator
library(dplyr)



get_gene_locations<-function(exp_mat){

  yourgenes<-rownames(exp_mat)

  genes<-EnsDb.Hsapiens.v86::EnsDb.Hsapiens.v86
  genes<-ensembldb::genes(genes)
  genes=as.data.frame(genes)

  # Check if more than 50% of yourgenes contain "ENSG"
  ensg_count <- length(grep("ENSG", yourgenes))
  total_genes <- length(yourgenes)

  if(ensg_count / total_genes > 0.5){

    message("More than 50% of genes are in Ensembl Gene ID format. Using gene_id.")
    genes=genes %>% filter(!gene_biotype=="LRG_gene") %>%
    dplyr::select(gene_id,seqnames,start,end) %>% 
    filter(seqnames %in% paste0(c(1:22,"X","Y"))) %>%
    filter(gene_id %in% yourgenes) %>%
    dplyr::rename(geneid=gene_id)

  }else{

    message("Less than 50% of genes are in Ensembl Gene ID format. Using gene_name.")

    genes=genes %>% filter(!gene_biotype=="LRG_gene") %>%
    dplyr::select(gene_name,seqnames,start,end) %>% 
    filter(seqnames %in% paste0(c(1:22,"X","Y"))) %>%
    filter(gene_name %in% yourgenes) %>%
    dplyr::rename(geneid=gene_name)
    
  }

  genes=genes %>% dplyr::rename(chr=seqnames,left=start,right=end) %>% mutate(chr=paste0("chr",chr))
  return(genes)

}

# Function to pseudobulk counts
pseudobulk_counts <- function(seuratlist, min.cells = 100, indiv_col = "Sample_ID", assay = "RNA", slot = "counts") {
  agg_count_list <- lapply(seuratlist, function(x) {
    Seurat::DefaultAssay(x) <- assay
    metadata <- x[[]]

    counts <- Seurat::GetAssayData(x, slot = slot)
    unique_ids <- unique(metadata[[indiv_col]])
    indiv_table <- metadata %>% dplyr::count(get(indiv_col))
    indiv_table <- indiv_table %>% dplyr::filter(n > min.cells)
    colnames(indiv_table) <- c("unique_ids", "n")
    unique_ids <- indiv_table$unique_ids
    n_indiv_start <- length(unique_ids)

    if (nrow(indiv_table) == 0) {
      # Return an empty DF if no individuals pass min.cells threshold
      emptydf <- data.frame(matrix(ncol = 0, nrow = nrow(counts)))
      rownames(emptydf) <- rownames(counts)
      return(emptydf)
    } else {
      cells <- rownames(metadata[metadata[[indiv_col]] == unique_ids[1], ])
      counts_2 <- Matrix::rowSums(counts[, cells])
      finalmat <- data.frame(counts_2)
      samplenames <- unique_ids[1]

      if (length(unique_ids) > 1) {
        for (i in 2:length(unique_ids)) {
          cells <- rownames(metadata[metadata[[indiv_col]] == unique_ids[i], ])
          sample <- unique_ids[i]
          counts_2 <- Matrix::rowSums(counts[, cells])
          finalmat <- cbind(finalmat, counts_2)
          samplenames <- c(samplenames, sample)
        }
      }
      colnames(finalmat) <- samplenames
      indiv_remain <- n_indiv_start - length(samplenames)

      return(finalmat)
    }
  })
  return(agg_count_list)
}


convert_geneids=function(genelist,
  format=c("entrezID","ENSEMBL","SYMBOL"),
  conversion=c("ENSEMBL","EntrezID","SYMBOL")){


  suppressMessages(symbols <- mapIds(org.Hs.eg.db, keys = genelist, keytype = format, column=conversion))

  symbols<-as.data.frame(symbols)
  symbols$pre_conversion<-rownames(symbols)
  genesbefore<-nrow(symbols)
  # symbols<-symbols[complete.cases(symbols),]

  genesafter<-genesbefore-nrow(symbols)

  if(genesafter>0 ){
    message(paste0(genesafter," genes were lost/didn't match Ensembl IDs. Double-check gene names!"))
    return(symbols)
  } else {
    return(symbols$symbols)
  }


}


params.outdir="/rds/general/user/ah3918/projects/puklandmarkproject/ephemeral/tmp/"
params.gds_file="/rds/general/user/ah3918/projects/roche/live/ALEX//PROCESSED_DATA/PROCESSED_GENOTYPE/FINAL/final_geno_440samples.gds"


// process create_genotype{

//     publishDir "${params.outdir}/MatrixEQTL_IO", mode: "copy"

//     // input:
//     // path genofile

//     output:
//     path "*"

//     // container "${baseDir}.container"
//    script:
//     """
//     Rscript -e 'source("..//genotype_functions/genotype_functions.r"); generate_genotype_matrix(gds_file="${params.gds_file}")'
//     """
//     // """
//     // Rscript -e 'library(GenomicRanges)'
//     // """

// }


process double_file_length {

    publishDir "${params.outdir}/", mode: "copy"

    input:
    path input_file

    output:
    path "doubled_${input_file.name}"

    script:
    """
    cat ${input_file} ${input_file} > doubled_${input_file.name}
    """
}

workflow{
    // create_genotype()
    double_file_length(input_file=params.inputfile)
}
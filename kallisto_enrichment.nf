#!/usr/bin/env nextflow

params.threads = 4
params.reads = "$projectDir/test/*_{1,2}.fastq.gz"
params.reference = "$projectDir/test/transcripts.fasta.gz"
params.single = false  // Set to true for single-end data
params.multiqc = "multiqc"
params.outdir = "output"

log.info """\
    L I G H T  - R N A BY A M M A R
    ===================================
    transcriptome: ${params.reference}
    reads        : ${params.reads}
    outdir       : ${params.outdir}
    threads      : ${params.threads}
    single-end   : ${params.single}
    """
    .stripIndent()

process INDEX {
    input:
    path transcriptome

    output:
    path 'transcripts_idx'

    script:
    """
    kallisto index -i transcripts_idx $transcriptome
    """
}

process QUANTIFICATION {
    tag "Kallisto on $sample_id"
    publishDir params.outdir, mode: 'copy'

    input:
    path transcripts_idx
    tuple val(sample_id), path(reads)

    output:
    path "$sample_id"

    script:
    if (params.single) {
        // Single-end reads
        """
        kallisto quant -i $transcripts_idx -o $sample_id -b 100 $reads --single -l 200 -s 20 -t $params.threads 2> "$sample_id".log
        """
    } else {
        // Paired-end reads
        """
        kallisto quant -i $transcripts_idx -o $sample_id -b 100 ${reads[0]} ${reads[1]} -t $params.threads 2> "$sample_id".log
        """
    }
}

process FASTQC {
    tag "FASTQC on $sample_id"

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}

process MULTIQC {
    publishDir params.outdir, mode: 'copy'

    input:
    path '*'

    output:
    path 'multiqc_report.html'

    script:
    """
    multiqc .
    """
}

process PRINT_PARAMS_R {
    publishDir params.outdir, mode: 'copy'

    input:
    val threads
    val reference
    val single
    val outdir

    output:
    file "r_params_output.txt"

    script:
    """
    Rscript -e "
        library(tidyverse)
        cat('Threads: $threads\n')
        cat('Reference: $reference\n')
        cat('Single-end: $single\n')
        cat('Output directory: $outdir\n')
        " > r_params_output.txt
    """
}
workflow {
    read_pairs_ch = Channel
        .fromFilePairs(params.reads, flat: params.single, checkIfExists: true)
        .map { sample_id, reads -> tuple(sample_id, reads) }

    index_ch = INDEX(params.reference)

    quant_ch = QUANTIFICATION(index_ch, read_pairs_ch)

    fastqc_ch = FASTQC(read_pairs_ch)

    MULTIQC(quant_ch.mix(fastqc_ch).collect())

    PRINT_PARAMS_R(params.threads, params.reference, params.single, params.outdir)
}

workflow.onComplete {
    log.info ( workflow.success ? 
        "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : 
        "Oops .. something went wrong" )
}

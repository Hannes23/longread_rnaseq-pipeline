// workflows/longread_rna.nf

// Importing modules
include { FASTQC } from '../modules/local/fastqc'
include { FASTPLONG } from '../modules/local/fastplong'
include { MINIMAP2 } from '../modules/local/minimap2'
include { ISOQUANT } from '../modules/local/isoquant'
include { SQANTI3; SQANTI3_REPORT } from '../modules/local/sqanti3'
include { SQANTI3_FILTER; SQANTI3_FILTER_REPORT } from '../modules/local/sqanti3_filter'
include { MULTIQC } from '../modules/local/multiqc'

// Workflow definition
workflow LONGREAD_RNA {

    // 1. VALIDATE INPUT
    if (params.input == null) {
        exit 1, "ERROR: Please provide a samplesheet via --input samplesheet.csv"
    }

    // 2. PARSE SAMPLESHEET
    Channel
        .fromPath(params.input)
        .splitCsv(header: true)
        .map { row ->
            def meta = [:]
            meta.id = row.sample
            def fastq = file(row.fastq)
            if (!fastq.exists()) {
                exit 1, "ERROR: FastQ file not found: ${row.fastq}"
            }
            return [ meta, fastq ]
        }
        .set { ch_reads }

    // 3. REFERENCES & ASSETS
    ch_genome = Channel.value(file(params.genome))
    ch_gtf    = Channel.value(file(params.gtf))
    
    // NEW: Define the path to your strict JSON filter rules
    ch_filter_rules = Channel.value(file("${projectDir}/assets/filtering.json"))

    // --- PIPELINE LOGIC ---
    

    // QC
    FASTQC(ch_reads)
    FASTPLONG(ch_reads)

    // Alignment
    MINIMAP2(FASTPLONG.out.reads, ch_genome)

    // IsoQuant (Correction, Discovery & Quantification)
    ISOQUANT(
        MINIMAP2.out.bam,
        ch_genome,
        ch_gtf
    )
    // SQANTI3 QC
    SQANTI3(
        ISOQUANT.out.gtf,       
        ISOQUANT.out.counts,
        ch_gtf,
        ch_genome
    )

    SQANTI3_REPORT(
        SQANTI3.out.original_classification,
        SQANTI3.out.junctions,
        SQANTI3.out.sqanti_params
    )

    // SQANTI3 FILTER
    SQANTI3_FILTER(
        SQANTI3.out.original_classification,
        SQANTI3.out.fasta,
        SQANTI3.out.corrected_gtf,
        ch_filter_rules
    )

    SQANTI3_FILTER_REPORT(
        SQANTI3.out.original_classification,        
        SQANTI3_FILTER.out.filtered_classification, 
        SQANTI3_FILTER.out.reasons         
    )

    // MultiQC
    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.html)
    ch_multiqc_files = ch_multiqc_files.mix(FASTPLONG.out.count)
    ch_multiqc_files = ch_multiqc_files.mix(SQANTI3_REPORT.out.html)
    ch_multiqc_files = ch_multiqc_files.mix(SQANTI3_FILTER_REPORT.out.pdf)

    MULTIQC(ch_multiqc_files.collect())

}
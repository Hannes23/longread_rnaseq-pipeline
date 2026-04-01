// workflows/longread_rna.nf

// Importing modules
include { FASTQC } from '../modules/local/fastqc'
include { FASTPLONG } from '../modules/local/fastplong'
include { MINIMAP2 } from '../modules/local/minimap2'
include { ISOQUANT } from '../modules/local/isoquant'
include { SQANTI3 } from '../modules/local/sqanti3'
include { SQANTI3_FILTER } from '../modules/local/sqanti3_filter'

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
            meta.id    = row.sample
            meta.group = row.condition // Make sure 'condition' is a column in your CSV
            def fastq = file(row.fastq)
            return [ meta, fastq ]
        }
        .set { ch_reads }

    // 3. REFERENCES & ASSETS
    ch_genome = Channel.value(file(params.genome))
    ch_gtf    = Channel.value(file(params.gtf))
    data_type = params.data_type
    ch_filter_rules = Channel.value(file("${projectDir}/assets/filtering.json"))

    // --- PIPELINE LOGIC ---

    // 1. QC
    FASTQC(ch_reads)
    FASTPLONG(ch_reads)

    // 2. Alignment
    MINIMAP2(FASTPLONG.out.reads, ch_genome, data_type)

    // 3. Grouping Logic (The most important part)
    // We take the Minimap2 output and bundle it by meta.group
    ch_grouped_inputs = MINIMAP2.out.bam
        .map { meta, bam, bai -> [ meta.group, bam, bai, meta.id ] }
        .groupTuple() 

    // 4. IsoQuant (Runs once per group)
    ISOQUANT (
        ch_grouped_inputs,
        ch_genome,
        ch_gtf,
        data_type
    )

    // 5. SQANTI3 (Runs once per group automatically)
    SQANTI3(
        ISOQUANT.out.gtf,       
        ISOQUANT.out.counts,
        ch_gtf,
        ch_genome
    )

    // 6. SQANTI3 FILTER (Runs once per group automatically)
    ch_classification = SQANTI3.out.original_classification
    .map { file ->
        def group_name = file.baseName.replace('_sqanti_classification', '')
        tuple(group_name, file)
    }

    SQANTI3_FILTER(
        ch_classification,
        SQANTI3.out.fasta,
        SQANTI3.out.corrected_gtf,
        ch_filter_rules
    )
}
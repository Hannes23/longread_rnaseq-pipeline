// workflows/longread_rna.nf

// Importing modules

include { FASTQC                                } from '../modules/local/fastqc'
include { FASTPLONG                             } from '../modules/local/fastplong'
include { MINIMAP2                              } from '../modules/local/minimap2'
include { TRANSCRIPT_CLEAN                      } from '../modules/local/transcriptclean'
include { TALON_INIT; TALON_RUN                 } from '../modules/local/talon'
include { SQANTI3                               } from '../modules/local/sqanti3'
include { SALMON_INDEX; SALMON_QUANT            } from '../modules/local/salmon'
include { MULTIQC                               } from '../modules/local/multiqc'


// Workflow definitions
workflow LONGREAD_RNA {                             

    // 1. Create Input Channel with Meta Map
    // Create input data stream
    ch_reads = Channel.fromPath(params.reads)   // find all files, initial input, ending in *fast.gz     
        .map { file ->                          // converting files to nf-core modules' structure
            def meta = [:]                      // create dictionary/map called "meta"
            meta.id = file.simpleName           // create key/name (eg. sampleA, extracted from sampleA.fastq.gz)
            meta.single_end = true              // flag indicating single-end reads ie. long-read seq
            return [ meta, file ]               // return tuple containing metadata map and actual file 
        }

    // 2. References
    // create channel that can be read multiple times, ie reference genomes need to be read multiple times
    ch_genome = Channel.value(file(params.genome))          
    ch_gtf = Channel.value(file(params.gtf))
    ch_transcripts = Channel.value(file(params.transcriptome))

    // --- PIPELINE LOGIC ---
    // run modules ie MODULE_NAME(input)
    // QC
    FASTQC(ch_reads)                                            // Use fastqs as input
    FASTPLONG(ch_reads)                                         // Use fastqs as input 

    // Alignment & Clean
    MINIMAP2(FASTPLONG.out.reads, ch_genome)                    // Use fastplong output as input and reference 
    TRANSCRIPT_CLEAN(MINIMAP2.out.bam, ch_genome)               // Use minimap bams as input and reference

    // Discovery (TALON)
    TALON_INIT(ch_gtf)                                          // Use gtf file to initialize talon db
    
    // Collect all samples for TALON
    TALON_RUN(
        TRANSCRIPT_CLEAN.out.bam.map{ it[1] }.collect(),        // Use bam file of transcript clean as input, ie collect --> use all samples at once
        TRANSCRIPT_CLEAN.out.bam.map{ it[2] }.collect(),        // Use indexed bam file 
        TALON_INIT.out.db,                                      // Use talon database
        ch_genome                                               // Use reference genome
    )

    SQANTI3(TALON_RUN.out.gtf, ch_gtf, ch_genome)               // Use talon output as input

    // Quantification (Salmon)
    SALMON_INDEX(ch_genome, SQANTI3.out.fasta)                   // Build indexed reference transcriptome using reference genome and SQANTI3 output
    SALMON_QUANT(ch_reads, SALMON_INDEX.out.index)               // Quantify against this transcriptome
    
    // MultiQC
    ch_multiqc_files = Channel.empty()                          // put all logs files together to run mutliqc
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip)
    ch_multiqc_files = ch_multiqc_files.mix(SALMON_QUANT.out.log)
    
    MULTIQC(ch_multiqc_files.collect())                         // run multioqc on this assembly
}
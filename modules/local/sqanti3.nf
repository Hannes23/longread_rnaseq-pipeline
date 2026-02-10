process SQANTI3 {
    label 'process_high_memory'

    input:
    path talon_gtf
    path gtf
    path genome

    output:
    // ADD THESE LINES so you can pass them to Salmon
    path "*_corrected.fasta"       , emit: fasta
    path "*_corrected.gtf"         , emit: gtf
    
    path "*_classification.txt"    , emit: classification
    path "*.html"                  , emit: report
    path "versions.yml"            , emit: versions

    script:
    """
    # SQANTI3 generates a .fasta and .gtf of the curated transcriptome automatically
    sqanti3_qc.py $talon_gtf $gtf $genome --cpus $task.cpus --report both --skipORF
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sqanti3: \$(sqanti3_qc.py --version 2>&1 | sed 's/SQANTI3 //')
    END_VERSIONS
    """
}
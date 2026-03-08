process ISOQUANT {

    input:
    path bams
    path bais
    val labels
    path genome
    path gtf
    val data_type

    output:
    path "isoquant_out/Combined/*.extended_annotation.gtf", emit: gtf
    path "isoquant_out/Combined/*.transcript_counts.tsv",   emit: counts
    path "isoquant_out/Combined/*.gene_counts.tsv",         emit: gene_counts, optional: true
    path "versions.yml",                                           emit: versions

    script:
    // Convert the Nextflow list of labels into a space-separated string
    def label_str = labels.join(' ')
    """
    echo "Running IsoQuant on ALL samples combined..."

    isoquant.py \\
        --reference ${genome} \\
        --genedb ${gtf} \\
        --bam ${bams} \\
        --labels ${label_str} \\
        --data_type ${data_type} \\
        --prefix Combined \\
        --output isoquant_out \\
        --threads ${task.cpus} \\
        --complete_genedb \\
        --genedb_output /tmp \\
        --sqanti_output \\
        --counts_format matrix \\
        --transcript_quantification with_ambiguous

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoquant: \$(isoquant.py --version | sed 's/IsoQuant //')
    END_VERSIONS
    """
}
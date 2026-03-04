process ISOQUANT {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(bam), path(bai)
    path genome
    path gtf
    val data_type

    output:
    path "isoquant_out/${meta.id}.extended_annotation.gtf", emit: gtf
    path "isoquant_out/${meta.id}.transcript_counts.tsv",   emit: counts
    path "isoquant_out/${meta.id}.gene_counts.tsv",         emit: gene_counts, optional: true
    path "versions.yml",                                    emit: versions

    script:
    def prefix = meta.id
    """
    # Run IsoQuant with optimized HPC and Quantification flags
    isoquant.py \\
        --reference ${genome} \\
        --genedb ${gtf} \\
        --bam ${bam} \\
        --data_type ${data_type} \\
        --prefix ${prefix} \\
        --outdir isoquant_out \\
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
process ISOQUANT {
    tag "${group_name}" 
    
    input:
    tuple val(group_name), path(bams), path(bais), val(labels)
    path genome
    path gtf
    val data_type

    output:
    // Dynamic output path based on the group name
    path "isoquant_out/${group_name}/*.extended_annotation.gtf", emit: gtf
    path "isoquant_out/${group_name}/*.transcript_counts.tsv",   emit: counts
    path "versions.yml",                                        emit: versions

    script:
    def label_str = labels.join(' ')
    """
    python -m isoquant\\
        --reference ${genome} \\
        --genedb ${gtf} \\
        --bam ${bams} \\
        --labels ${label_str} \\
        --data_type ${data_type} \\
        --prefix ${group_name} \\
        --output isoquant_out \\
        --threads ${task.cpus} \\
        --complete_genedb \\
        --genedb_output . \\
        --sqanti_output \\
        --counts_format matrix \\
        --transcript_quantification with_ambiguous

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoquant: \$(python -m isoquant --version | sed 's/IsoQuant //')
    END_VERSIONS
    """
}
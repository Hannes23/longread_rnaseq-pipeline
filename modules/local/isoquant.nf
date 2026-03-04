process ISOQUANT {
    tag "$meta.id"
    

    input:
    tuple val(meta), path(bam), path(bai)
    path genome
    path gtf

    output:
    path "isoquant_out/${meta.id}.extended_annotation.gtf", emit: gtf
    path "isoquant_out/${meta.id}.transcript_counts.tsv",   emit: counts
    path "versions.yml",                                    emit: versions

    script:
    def prefix = meta.id
    """
    # Run IsoQuant
    isoquant.py \\
        --reference ${genome} \\
        --genedb ${gtf} \\
        --bam ${bam} \\
        --data_type pacbio_ccs \\
        --prefix ${prefix} \\
        --outdir isoquant_out \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        isoquant: \$(isoquant.py --version | sed 's/IsoQuant //')
    END_VERSIONS
    """
}
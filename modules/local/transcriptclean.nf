process TRANSCRIPT_CLEAN {
    tag "$meta.id"
    label 'process_medium'

    input:
    tuple val(meta), path(bam), path(bai)
    path genome

    output:
    tuple val(meta), path("*_clean.sorted.bam"), path("*_clean.sorted.bam.bai"), emit: bam
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    python /usr/local/bin/TranscriptClean.py --sam $bam --genome $genome --outprefix ${prefix}_clean --threads $task.cpus
    samtools view -bS ${prefix}_clean_clean.sam | samtools sort -@ $task.cpus -o ${prefix}_clean.sorted.bam
    samtools index ${prefix}_clean.sorted.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        transcriptclean: 2.0.2
    END_VERSIONS
    """
}
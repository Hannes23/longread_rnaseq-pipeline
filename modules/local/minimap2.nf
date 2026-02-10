process MINIMAP2 {
    tag "$meta.id"
    label 'process_high'

    input:
    tuple val(meta), path(reads)
    path genome

    output:
    tuple val(meta), path("*.bam"), path("*.bam.bai"), emit: bam
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''                  // find extra arguments in modules.config
    def prefix = task.ext.prefix ?: "${meta.id}"    // Sets the output filename to the sample ID
    """
    minimap2 $args -t $task.cpus $genome $reads > ${prefix}.sam | samtools view -bS ${prefix}.sam | samtools sort -@ $task.cpus -o ${prefix}.sorted.bam
    samtools index ${prefix}.sorted.bam
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version 2>&1)
    END_VERSIONS
    """
}
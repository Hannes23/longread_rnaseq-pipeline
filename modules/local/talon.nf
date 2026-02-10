process TALON_INIT {
    label 'process_medium'

    input:
    path gtf

    output:
    path "talon.db", emit: db
    path "versions.yml", emit: versions

    script:
    """
    talon_initialize_database --f $gtf --g hg38 --a gencode --o talon
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$(talon --version 2>&1 | sed 's/TALON //')
    END_VERSIONS
    """
}

process TALON_RUN {
    label 'process_high_memory' // Needs 400GB!

    input:
    // We pass a LIST of files, not a single tuple
    path bams 
    path bais
    path db
    path genome

    output:
    path "talon_results*", emit: results
    path "talon_results_talon.gtf", emit: gtf
    path "versions.yml", emit: versions

    script:
    """
    echo "sample,dataset,platform,reads" > talon_config.csv
    for bam in ${bams}; do
        s_id=\$(basename \$bam .sorted.bam)
        echo "\$s_id,\$s_id,SequelII,\$bam" >> talon_config.csv
    done

    talon --f talon_config.csv --db $db --build hg38 --o talon_results --threads $task.cpus
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        talon: \$(talon --version 2>&1 | sed 's/TALON //')
    END_VERSIONS
    """
}
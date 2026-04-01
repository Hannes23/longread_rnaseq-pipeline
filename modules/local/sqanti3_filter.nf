process SQANTI3_FILTER {
    tag "SQANTI3_Filter"
    

    input:
    tuple val(group_name), path(original_classification)
    path corrected_fasta
    path corrected_gtf
    path filter_json




    output:
    path "sqanti_filter_out/${group_name}/*",                      emit: results
    path "versions.yml",                              emit: versions

    script:
    """
    set -euo pipefail

    mkdir -p sqanti_filter_out

    echo "1. Adding Roy score..."
    # Nextflow automatically mounts anything in your pipeline's 'bin/' folder 
    # into the container's PATH, so you can just call the python script directly!
    add_roy_score.py \\
        ${original_classification} \\
        scored_classification.txt

    echo "2. Running SQANTI3 rules filter & Reporting..."
    # THE FIX: Call the tool directly and REMOVE --skip_report
    sqanti3_filter.py rules \\
        --sqanti_class scored_classification.txt \\
        -j ${filter_json} \\
        --filter_isoforms ${corrected_fasta} \\
        --filter_gtf ${corrected_gtf} \\
        -d sqanti_filter_out \\
        -o sqanti_filter_out \\
        --skip_report 
        
    echo "3. Capturing version..."
    # Capture version, redirecting stderr to stdout, and taking the first line
    SQ_VERSION=\$(sqanti3_filter.py --version 2>&1 | head -n1 | sed 's/SQANTI3 //g' | xargs)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sqanti3: \$SQ_VERSION
    END_VERSIONS
    """
}
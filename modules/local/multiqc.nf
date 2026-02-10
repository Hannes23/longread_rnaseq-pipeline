process MULTIQC {
    label 'process_low'

    input:
    path multiqc_files

    output:
    path "multiqc_report.html", emit: report
    path "versions.yml"       , emit: versions

    script:
    """
    multiqc .
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
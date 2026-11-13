process DRAGEN {
    // Dragen requires specific hardware (FPGA) to run.
    // This process is therefore only executed on Illumina® BioInsight Platform Core / Illumina Connected Analytics (ICA) compute nodes with FPGA support.
    // Test only contain a stub of the process, which can be executed on any compute node, but does not perform any actual processing.
    tag "${meta.id}"
    label 'process_fpga'

    // Dragen 4.2.4-2 (F2 compatible container)
    container '079623148045.dkr.ecr.eu-central-1.amazonaws.com/cp-prod/f1b7ad6a-11ac-4bc1-b705-b275ff2887ad:latest'

    input:
    tuple val(meta), path(r1_fastq), path(r2_fastq)
    path fastq_list
    tuple val(meta2), path(ref_dir)
    path repeat_genotype_specs

    output:
    tuple val(meta), path("*"), emit: output
    tuple val(meta), path('*.csv'), emit: csv
    tuple val(meta), path("${prefix}.bam"), path("${prefix}.bam.bai"), emit: bam_bai
    tuple val(meta), path("${prefix}.wgs_coverage_metrics.csv"), optional: true, emit: wgs_coverage_metrics
    tuple val(meta), path("${prefix}.cnv_metrics.csv"), optional: true, emit: cnv_metrics
    tuple val(meta), path("${prefix}.mapping_metrics.csv"), optional: true, emit: mapping_metrics
    tuple val(meta), path("${prefix}.ploidy_estimation_metrics.csv"), optional: true, emit: ploidy_estimation_metrics
    tuple val(meta), path("${prefix}.gvcf_metrics.csv"), optional: true, emit: gvcf_metrics
    tuple val(meta), path("${prefix}.tn.bw"), path("${prefix}.hard-filtered.baf.bw"), optional: true, emit: igv_bw
    tuple val("${task.process}"), val('dragen'), eval("dragen --version 2>&1 | sed 's/^dragen Version //'"), topic: versions, emit: versions_dragen

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    def repeat_specs = repeat_genotype_specs ? "--repeat-genotype-enable true --repeat-genotype-specs ${repeat_genotype_specs}" : ""
    """
    /opt/edico/bin/dragen --partial-reconfig HMM --ignore-version-check true

    /opt/edico/bin/dragen --lic-instance-id-location /opt/instance-identity \\
        --ref-dir ${ref_dir} \\
        --fastq-list ${fastq_list} \\
        --fastq-list-sample-id ${meta.id} \\
        --output-file-prefix ${prefix} \\
        --output-directory ./ \\
        --intermediate-results-dir /scratch \\
        ${repeat_specs} \\
        ${args}
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    """
    echo ${args}

    touch ${prefix}.bam
    touch ${prefix}.bam.bai
    touch ${prefix}.wgs_coverage_metrics.csv
    touch ${prefix}.cnv_metrics.csv
    touch ${prefix}.mapping_metrics.csv
    touch ${prefix}.ploidy_estimation_metrics.csv
    touch ${prefix}.gvcf_metrics.csv
    touch ${prefix}.tn.bw
    touch ${prefix}.hard-filtered.baf.bw
    """
}

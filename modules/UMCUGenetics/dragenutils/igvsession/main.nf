process DRAGENUTILS_IGVSESSION {
    tag "${meta.id}"
    label 'process_single'

    // TODO: Update all dragen-utils containers to 1.1.0 once the new version is released
    container 'ghcr.io/umcugenetics/dragen-utils:sha-dfcf600'

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(tn_bw), path(filtered_baf_bf)

    output:
    tuple val(meta), path("${prefix}_IGV_srWGS_SampleQC_session.xml"), emit: igv_session
    tuple val("${task.process}"), val('dragenutils'), eval("dragen-utils --version"), topic: versions, emit: versions_dragenutils

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    dragen-utils igv_session \\
        ${meta.id} \\
        ${bam} \\
        ${tn_bw} \\
        ${filtered_baf_bf}
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_IGV_srWGS_SampleQC_session.xml
    """
}
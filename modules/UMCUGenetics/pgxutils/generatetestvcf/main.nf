process PGXUTILS_GENERATETESTVCF {
    tag "${meta.id}"

    container "pgx-utils:0.1.0"

    input:
    tuple val(meta), path(pgx_tables)
    val(gene)

    output:
    tuple val([id: gene]), path("*.diplotypes.vcf.gz"), emit: vcf
    tuple val([id: gene]), path("*.diplotypes.vcf.gz.tbi"), emit: idx
    tuple val([id: gene]), path("*.expected-results.tsv"), emit: expected_results

    script:
    def args = task.ext.args ?: ""
    """
    pgx_utils generate-test-vcf \\
        ${args} \\
        --tables ${pgx_tables}
    """

    stub:
    """
    touch ${gene}.diplotypes.vcf.gz
    touch ${gene}.diplotypes.vcf.gz.tbi
    touch ${gene}.expected-results.tsv
    """


}

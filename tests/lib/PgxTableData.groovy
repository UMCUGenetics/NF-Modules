// Helper function to download pgx table files and stage them in a directory
class PgxTableData {
    static void stageTables(String targetDir = null) {
        def url = System.getenv("MODULES_TESTDATA_BASE") ?:
            "https://raw.githubusercontent.com/UMCUGenetics/DxNextflowTestData/main/Modules/"
        def dir = new File(targetDir ?: "pgx_tables")
        dir.mkdirs()
        ["allele-table.csv","diplotype-table.csv","equation-table.csv","gene-table.csv"].each { n ->
            new File(dir, n).withOutputStream { out ->
                out << new URL("${url}/pgxutils/${n}").openStream()
            }
        }
    }
}

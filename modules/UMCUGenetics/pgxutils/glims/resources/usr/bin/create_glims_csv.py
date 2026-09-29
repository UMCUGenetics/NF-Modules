#!/usr/bin/env python3
import pandas as pd
from pathlib import Path
from typing import Annotated
import typer


app = typer.Typer(add_completion=False, help="Create a PGx input file for GLIMS")

ACTIVITY = {
    "normal function":    ("actief", "actieve"),
    "decreased function": ("verminderd actief", "verminderd actieve"),
    "increased function": ("verhoogd actief", "verhoogd actieve"),
    "inactive":           ("inactief", "inactieve"),
}
ORDER = list(ACTIVITY)

def format_phenotype(phenotype):
    match phenotype:
        case "Normal Metabolizer":
            return "NM"
        case "Intermediate Metabolizer":
            return "IM"
        case "Poor Metabolizer":
            return "PM"
        case "Ultrarapid Metabolizer":
            return "UM"
        case _:
            return phenotype


def lookup_allele_activity(allele, gene_alleles):
    return gene_alleles.loc[gene_alleles["StarAllele"] == allele, "Function"].iloc[0]

def generate_allele_activity_explanation(allele_activities):
    a, b = sorted((x.strip().lower() for x in allele_activities), key=ORDER.index)
    if a == b:
        return f"2 {ACTIVITY[a][1]} allelen"
    return f"1 {ACTIVITY[a][0]} allel en 1 {ACTIVITY[b][0]} allel"

def generate_allele_activity_summary(phenotype, gene_name):
    description = {
        "NM": "normaal",
        "IM": "verlaagd",
        "PM": "sterk verlaagd of afwezig",
        "UM": "verhoogd"
    }

    return f"{gene_name} activiteit is {description[phenotype]} op basis van het genotype."

def format_glims_row(row, gene_name, gene_alleles):

    genotype =  row["Genotype"]
    phenotype =  row["Phenotype"]
    phenotype_fmt = format_phenotype(phenotype)
    searched_alleles_txt = f"Onderzoek op {gene_name}: " + ", ".join(gene_alleles["StarAllele"])

    allele_activities = [lookup_allele_activity(allele, gene_alleles) for allele in genotype.split('/')]
    allele_activity_explanation = generate_allele_activity_explanation(allele_activities)
    allele_activity_summary = generate_allele_activity_summary(phenotype_fmt, gene_name)
    betekenis = f"Betekenis: {allele_activity_explanation} {allele_activity_summary}"

    conclusion_txt = ". ".join([
        f"Genotype: {gene_name} {genotype}",
        f"Voorspeld fenotype: {phenotype} ({phenotype_fmt})",
        searched_alleles_txt,
        betekenis,
        "Mate van effect is geneesmiddel afhankelijk. Voor overleg: dienstdoende ziekenhuisapotheker, tel. 74488."
    ])

    print(conclusion_txt)
    glims_row = [ row["Sample"], gene_name, genotype, phenotype_fmt, conclusion_txt ]

    return glims_row


@app.command()
def main(
    pgx_tsv: Annotated[
        Path,
        typer.Option(
            "--tsv",
            exists=True,
            dir_okay=False,
            readable=True,
            help="Combined PGx result tsv"
        )
        ],
    allele_table: Annotated[
        Path,
        typer.Option(
            "--alleles",
            exists=True,
            dir_okay=False,
            readable=True,
            help="PGx star-allele table"
        )
    ],
    output: Annotated[
        Path,
        typer.Option(
            '--output',
            help="Output csv file name"
        )
    ]
    ):

    gene_name = pgx_tsv.stem.split("_")[0]
    allele_table = pd.read_csv(allele_table, sep=',')
    gene_alleles = allele_table[allele_table["Gene"] == gene_name]


    pgx_df = pd.read_csv(pgx_tsv, sep="\t").rename(columns={"Unnamed: 0": "Sample"})


    glims_df = pgx_df.apply(format_glims_row, gene_name=gene_name, gene_alleles=gene_alleles, axis=1, result_type="expand")
    glims_df.columns = ["Sample", "Gen", "Genotype", "Conclusie", "Conclusie_text"]

    glims_df.to_csv(output, sep=";", index=False)

if __name__ == "__main__":
    app()

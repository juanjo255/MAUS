## This is to plot Bracken results per sample along 
## with diversity metric (shannon so far)
import pandas as pd
from plotly.subplots import make_subplots
import plotly.graph_objects as go

min_abundance=1
samples=6
## Open file
bracken_file=pd.read_csv(filepath_or_buffer='/Volumes/PiconCossio/biocomp_tools/MAUS/utils/braken_output_G1_G2.txt', 
                         delimiter='\t', skiprows=8)

## Compute relative abundance (RelAbun)
def compute_relative_abun (df, number_samples=6):
    for i in range(1, number_samples+1):
        df[f"G{i}_1_RelAbun"] = df[f"G{i}_1_lvl"]/df[f"G{i}_1_lvl"].sum() * 100

## Filter by abundance 
def filter_by_abundance_conditional (df, number_samples, min_abundance, min_samples):
    ## This is intended to mimic the taxa filter by abundance conditionally of qiime2
    ## Select taxa that have at least n abundance in at least n samples 
    df = df [(df.iloc[:,number_samples*-1:] >= min_abundance).sum(axis=1) > min_samples]
    return df

## Plot
def plot_stacked(df, sample_names, 
                 title_plot="Relative abundance V3-V4 Kraken2-Bracken"):
    ## It must be this way, remember some Genus have same name, like uncultured 
    sample_names=df.columns
    fig = make_subplots(rows=2, cols=1)
    for i in range(0, len(df["name"])):
        fig.add_trace(go.Bar(name=df.iloc[i,0].strip(),
                            x=sample_names,y=df.iloc[i,1:]),
                    row=1, col=1)

    fig.update_layout(barmode='stack',
        autosize=True,
        width=1200,
        height=800,
        title_text=title_plot)
    fig.show()



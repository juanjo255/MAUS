# MAUS
> Metagenomic Analysis UniSeq (MAUS)

This pipeline is for the analysis of metagenomic Illumina sequencing.


## Pipeline overview
1. Trimming with FastP.
2. Read classification with Kraken2
3. Abundance estimation with Bracken.
4. Alpha diversity calculation with KrakenTools. 

## Installation

It's encourage to use a conda/mamba enviroment.

For Linux:

```
git clone https://github.com/juanjo255/MAUS.git
mamba create -n MAUS -c bioconda fastp kraken2 bracken 
```

## Usage example

A few motivating and useful examples of how your product can be used. Spice this up with code blocks and potentially more screenshots.

_For more examples and usage, please refer to the [Wiki][wiki]._


## Meta

Your Name – [@YourTwitter](https://twitter.com/dbader_org) – YourEmail@example.com

Distributed under the XYZ license. See ``LICENSE`` for more information.

[https://github.com/yourname/github-link](https://github.com/dbader/)


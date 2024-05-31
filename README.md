# MAUS
> Metagenomic Analysis UniSeqs (MAUS)

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
mamba create -n MAUS -c bioconda fastp kraken2 bracken krona 
```

## Usage example

* For help message
  ```
  ./MAUS_cli.sh -h
  ```
  
  ```
    Options:
        -1        Input R1 paired end file. [required].
        -2        Input R2 paired end file. [required].
        -d        Database for kraken. if you do not have one, create one before using this pipeline. [required].
        -n        Build kraken2 and Bracken database (Use with -g for library download). [False].
        -g        Libraries. It can accept a comma-delimited list with: archaea, bacteria, plasmid, viral, human, fungi, plant, protozoa, nr, nt, UniVec, UniVec_Core. [kraken2 standard].
        -t        Threads. [4].
        -w        Working directory. Path to create the folder which will contain all MAUS information. [./MAUS_result].
        -z        Different output directory. Create a different output directory every run (it uses the date and time). [False].
        -f        FastP options. [\" \"].
        -l        Read length (Bracken). [100].
        -c        Classification level (Bracken) [options: D,P,C,O,F,G,S,S1,etc]. [F]
        -s        Threshold before abundance estimation (Bracken). [0].
        -k        kmer length. (Kraken2,Bracken).[35]

        *         Help.
  
  ```

## Twitter/X

[@Juanpicon255](https://x.com/Juanpicon255)

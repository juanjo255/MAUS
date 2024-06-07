![MAUS_logo](Images/MAUS_logo.png)

> Metagenomic Analysis UniSeqs (MAUS)


This pipeline is for the analysis of metagenomic Illumina sequencing.


## Pipeline overview

![pipelineChart](Images/MAUS_pipeline_chart.png)

## Installation

It's encouraged to use a conda/mamba enviroment.

For Linux:

```
mamba create -n MAUS -c bioconda fastp kraken2 bracken krona fastqc tqdm
pip install multiqc
git clone https://github.com/juanjo255/MAUS.git
cd MAUS
export PATH=$PATH:$(pwd)/kraken2_build
```
NOTES:
* The folder ```Kraken2_build```is required to be in the path 
* MultiQC is installed with pip because it works better than conda both in Linux and MacOS

## Usage intructions

* If for any reason you got problems during taxonomy and libraries downloading, you can resume the download in this way:

  ```
  k2 download-taxonomy --db path/to/database
  k2 download-library --db path/to/database --library "bacteria, fungi"
  ```

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

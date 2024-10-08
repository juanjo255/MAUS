## Default Options
wd="."
output_dir="maus_result"
prefix1=""
prefix2=""
threads=4
fastp_options=""
deactivate_fastp=0
deactivate_fastqc=0
read_len=100
classification_level="F"
threshold_abundance=0
kmer_len=35
build_db=0
libraries="bacteria,archaea,viral,human,UniVec_Core"

## Executable path
# FIXME 
# This part could generate problems, I am trying just to get the executable path to locate other folders
if which MAUS_cli.sh > /dev/null 2>&1; then
    ## This wont work for a while I guess. This is thought for a wet dream of using in anaconda or nextflow
    exec_path=$(grep -o ".*/" $(which MAUS_cli.sh))
else
    if [ "$(grep -o "/" <<< $0 | wc -l)" -gt 0 ]; then
        exec_path=$(grep -o ".*/" <<< $0)
    else
        exec_path="./"
    fi
fi


MAUS_help() {
    echo "
    MAUS - Metagenome Analyse pipeline UniSeqs

    Author:
    Juan Picon Cossio
    Jhoanna Tejada Moreno
    Gustavo Gámez de las Armas

    Version: 0.1

    Usage: 
    MAUS_cli.sh [options] -1 reads_R1.fastq -2 reads_R2.fastq
    or 
    MAUS_cli.sh [options] -3 path/to/dir/pairedReads



    Options:
    Required:

        -1        Input R1 paired end file. [required].
        -2        Input R2 paired end file. [required].
        -3        Directory with R1 and R2 files. [required].
        -d        Database for Kraken2 and Bracken. if you do not have one, you need to create it first. Check flag -n and -g. [required].
    
    Optional:

        -r        Deactivate fastQC. Adding this option will deactivate quality assessment with fastqc. [False] 
        -n        Build kraken2 and Bracken database. Adding this option will activate database construction (Use with -g or -e for library download). [False].
        -g        Libraries. It can accept a comma-delimited list with: archaea, bacteria, plasmid, viral, human, fungi, plant, protozoa, nr, nt, UniVec, UniVec_Core. [kraken2 standard].
        -e        Special library. One of: greengenes, silva, rdp.
        -t        Threads. [4].
        -w        Working directory. Path to create the folder which will contain all MAUS information. ["."].
        -z        Different output directory. Create a different output directory every run (it uses the date and time). [False].
        -p        Deactivate FastP. Adding this option will deactivate FastP filtering [False]
        -f        FastP options. [\" \"].
        -l        Read length (Bracken). [100].
        -c        Classification level (Bracken). It can be 1 level or several separated by comma [options: D,P,C,O,F,G,S]. [F] or [P,F,G]
        -s        Threshold before abundance estimation (Bracken). [0].
        -k        kmer length. (Kraken2,Bracken).[35]
        *         Help.
    "
    exit 1
}
while getopts '1:2:3:d:rng:e:t:w:z:pf:l:c:s:k:' opt; do
    case $opt in
        1)
        input_R1_file=$OPTARG
        ;;
        2)
        input_R2_file=$OPTARG
        ;;
        3)
        path_to_dir_paired=$OPTARG
        ;;
        d)
        kraken2_db=$OPTARG
        ;;
        r)
        deactivate_fastqc=1
        ;;
        n)
        build_db=1
        ;;
        g)
        libraries=$OPTARG
        ;;
        e)
        special_library=$OPTARG
        ;;
        t)
        threads=$OPTARG
        ;;
        w)
        wd=$OPTARG
        ;;
        z)
        output_dir="MAUS_result_$(date  "+%Y-%m-%d_%H-%M-%S")/"
        ;;
        p)
        deactivate_fastp=1
        ;;
        f)
        fastp_options=$OPTARG
        ;;
        l)
        read_len=$OPTARG
        ;;
        c)
        classification_level=$OPTARG
        ;;
        s)
        threshold_abundance=$OPTARG
        ;;
        k)
        kmer_len=$OPTARG
        ;;
        *)
        MAUS_help
        ;;
    esac
done

#### OPTIONS CHECKING #####
## If no option given, print help
if [ $OPTIND -eq 1 ]; then MAUS_help; fi

if [ -z $kraken2_db ]; then echo "ERROR => Kraken2 database is missing"; MAUS_help; fi

## Check if working directory has the last slash
if ! [ ${wd: -1} = / ];
then 
    wd=$wd"/"
fi


#### FUNCTIONS FOR PIPELINE ####

create_wd (){
    ## Check if output directory exists
    if [ -d $1 ];
    then
        echo " "
        echo "Directory $1 exists."
        echo " "
    else 
        mkdir -p $1
        echo " "
        echo "Directory $1 created"
        echo " " 
    fi
}

concat_paired_end(){
    # here R1 and R2 files are concat for kraken2 in this way:
    # @R1 header
    # sequenceR1xsequenceR2
    if [ ${input_R1_file: -2} = "gz" ];
    then 
        cmd="zcat"
    else
        cmd="cat"
    fi

    paste <($cmd "$input_R1_file") <($cmd "$input_R2_file") | awk '{
    if (NR % 4 == 1) {  # Header lines
        print $1 "x" $2;
    } else if (NR % 4 == 2) {  # Sequence lines
        print $1 "x" $2
    }
      else if (NR % 4 == 3) {  # + lines
                print $1;
    } else if (NR % 4 == 0) {  # Quality lines
        print $1  $2;
    }
    }' >> $1

    echo ""
    num_reads=$(cat $1 | grep -c "^@")
    echo "{$num_reads} Paired-end reads concatenated and written to $1"
}

## FastP filtering
fastp_filter (){
    if [ $deactivate_fastp -eq 0 ];
    then
        echo " "
        echo "**** Quality filter with fastp *****"
        echo " "
        merge_mode=$(echo $fastp_options | grep -Ewo -- "-m|--merge")
        ## Modify fastp options
        ## This is because in merge mode I need an extra file for each reads
        ## The pipeline is for looping through several files so I need to make a file for each new paired-end
        if ! [ -z "$merge_mode" ];then
            fastp_options_backup=$fastp_options
            fastp_options="$fastp_options --merged_out $wd$prefix1.merged.fastq"
        fi

        echo "FastP options: $fastp_options"
        fastp --thread $threads $fastp_options -i $input_R1_file -I $input_R2_file -o $wd$prefix1".filt.fastq" -O $wd$prefix2".filt.fastq" \
            -j $wd$prefix1".json" -h $wd$prefix1".html"
           
        if ! [ -z "$merge_mode" ];then
           ## Use the merged reads and concat unmerged for kraken2
           ## I do it in this way because I am fcking lazy
           ## and this was created a lot after most of the pipeline were built
           ## To avoid creating more varibles I will keep the same ones
            input_R1_file=$wd$prefix1".filt.fastq"
            input_R2_file=$wd$prefix2".filt.fastq"
            concat_paired_end $wd$prefix1".concat.fastq"
            input_R1_file=$wd$prefix1".merged.fastq"
            input_R2_file=$wd$prefix1".concat.fastq"
        else
            # Use the filtered reads in the rest of the pipeline
            paired_flag_kraken2="--paired"
            input_R1_file=$wd$prefix1".filt.fastq"
            input_R2_file=$wd$prefix2".filt.fastq"
        fi
        fastp_options=$fastp_options_backup
    fi
}

quality_assess_fastqc(){
    if [ $deactivate_fastqc -eq 0 ];
    then
        out_dir="quality_check"
        create_wd $wd$out_dir && \
        fastqc -q -t $threads -o $wd$out_dir $input_R1_file $input_R2_file && \
        multiqc $wd$out_dir --clean-up --outdir $wd$out_dir
    fi
}

kraken2_build_db (){
    echo " "
    echo "**** Downloading required files for kraken2 database *****"
    echo " "
    if ! [ -z $special_library ];
    then 
        echo " "
        echo "**** Downloading special database: $special_library *****"
        echo " "
        k2 build --db $kraken2_db --special $special_library
    else
        ## Download taxonomy
        if [ -f $kraken2_db"/taxonomy/nucl_gb.accession2taxid" ] || [ -f $kraken2_db"/taxonomy/nucl_wgs.accession2taxid" ]; then
            echo "Taxonomy files exist"
        else
            k2 download-taxonomy --db $kraken2_db
        fi

        ## Download libraries
        k2 download-library --db $kraken2_db --library $libraries && kraken2-build --build --db $kraken2_db --threads $threads
    fi
}
## bracken build database
bracken_build_db (){
    echo " "
    echo "**** Building Bracken database *****"
    echo " "
     if ! [ -z $special_library ];
    then 
        $exec_path"/Bracken/bracken-build" -d $kraken2_db -t $threads -k $kmer_len -l $read_len
    else
        $exec_path"/Bracken/bracken-build" -d $kraken2_db -t $threads -k $kmer_len -l $read_len && kraken2-build --clean --db $kraken2_db
    fi
    echo " "
    echo "**** Unneeded files were removed *****"
    echo " "
}

## Kraken2 classification
Kraken2_classification (){
    echo " "
    echo "**** Read classification with Kraken2 *****"
    echo " "
    kraken2 $paired_flag_kraken2 --threads $threads --db $kraken2_db --report $wd$prefix1".kraken2_report" --report-minimizer-data \
        --output $wd$prefix1".kraken2_output" $input_R1_file $input_R2_file 
}

## Bracken abundance estimation
bracken_estimation (){
    echo " "
    echo "**** Abundance estimation with Bracken *****"
    echo " "
    IFS="," read -a tax_lvls <<< "$classification_level"
    for tax_level in "${tax_lvls[@]}";
    do
        bracken -d $kraken2_db -i "$wd$prefix1.kraken2_report" -r $read_len -l $tax_level -t $threshold_abundance \
            -o "$wd$prefix1.$tax_level.bracken_output"
    done
}

## Krona visualization of Bracken results
alpha_diversity (){
    echo " "
    echo "**** Computing Alpha metrics *****"
    echo " "
    for i in "Sh" "BP" "Si" "ISi" "F"
    do 
        $exec_path"/KrakenTools/DiversityTools/alpha_diversity.py" \
        --filename  $wd$prefix1"."$tax_level".bracken_output" --alpha $i >> $wd$prefix1".alphaDiversity.tsv"
    done 
}

## Krona visualization of Bracken results
krona_plot (){
    echo " "
    echo "**** Setting up Krona *****"
    echo " "
    ktUpdateTaxonomy.sh && \
    echo "**** Plotting Kraken results with Krona *****"
    echo " "
    #ktImportTaxonomy -o $wd$prefix1.krona.html" $wd$prefix1.bracken_output"
    $exec_path"/KrakenTools/kreport2krona.py" -r $wd$prefix1".kraken2_report" -o $wd".kraken2_report.krona.txt"
    ktImportText  $wd".kraken2_report.krona.txt" -o $wd$prefix1".krona.html"
}

## PIPELINE EXECUTION ORDER
pipeline(){
    fastp_filter && quality_assess_fastqc \
    && Kraken2_classification && bracken_estimation && krona_plot && alpha_diversity
}

set_name_for_outfiles(){
## PREFIX name to use for the resulting files
        prefix1=$(basename $input_R1_file)
        prefix1=${prefix1%%.*}
        prefix2=$(basename $input_R2_file)
        prefix2=${prefix2%%.*}
}

## PIPELINE EXECUTION
pipeline_exec (){
    if [ $build_db -eq 1 ];
    then
        check_db=$(kraken2-inspect --skip-counts --threads $threads --db $kraken2_db 2> /dev/null)
        if [ -z "$check_db" ];
        then
            echo "**** Building databases for kraken2 and Bracken *****"
            echo " " 
            kraken2_build_db && bracken_build_db && pipeline
        else
            echo "Kraken database exists. Skipping downloading"
            pipeline
        fi
    else
        pipeline
    fi
}

## Check if files or directory with files was given
## Check required files are available
if ! [ -z "$path_to_dir_paired" ];
then
    for i in $(find $path_to_dir_paired -name *.fastq* | grep -o ".*_1\..*")
    do
        echo "running MAUS for"  $(basename $i)
        input_R1_file=$i
        input_R2_file=$(echo "$i" | sed 's/_1\./_2\./')

        # Asign a name for the dir base on the reads name
        prefix=$(basename $input_R1_file)
        output_dir="${prefix%_*}/"

        # RUN MAUS
        set_name_for_outfiles
        create_wd $wd$output_dir &&
        keep_wd_body=$wd
        wd=$wd$output_dir
        echo "results will be saved at" $wd

        pipeline_exec
        wd=$keep_wd_body
        
    done
else
    if [ -z "$input_R1_file" ]; then echo "ERROR => File 1 is missing"; MAUS_help; fi
    if [ -z "$input_R2_file" ]; then echo "ERROR => File 2 is missing"; MAUS_help; fi
    
    set_name_for_outfiles
    create_wd $wd$output_dir &&
    wd=$wd$output_dir
    pipeline_exec
fi

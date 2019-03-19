#!/usr/bin/env nextflow

params.pneu = "/hpc-home/leviet/data/strep/pneu.list"
params.non_pneu = "/hpc-home/leviet/data/strep/non_pneu.list"


params.output = "kmc_pneu"

threads = 8

//kmers = [21,31,33,105,110,115,120,125,130,135,140,145,150,160,170,200,210,220,230,235,240,245,250,255]
kmers = [155,165,175,180,185,190,195]
params.freq = 2

process kmc {
    publishDir "${params.output}/k_${k}", mode: "copy"
    
    tag {"kmc on - " + k}
    
    container "kmc.sif"
    // maxForks 2
    cpus 8
    memory '16.GB'

    input:
    file(params.pneu)
    file(params.non_pneu)
    each k from kmers
    
    output:
    set val(k), file("pneu_${k}.kmc_pre"), file("pneu_${k}.kmc_suf"), file("non_pneu_${k}.kmc_pre"),  file("non_pneu_${k}.kmc_suf") into kmc_simple_ch


    script:
    
    """
    mkdir tmp_dir_pneu
    mkdir tmp_dir_non_pneu

    kmc -fm -k${k} -m16 -jpneu.json @${params.pneu} pneu_${k} tmp_dir_pneu
    kmc -fm -k${k} -m16 -jnon_pneu.json @${params.non_pneu} non_pneu_${k} tmp_dir_non_pneu
    """
}

process kmc_tools {
    publishDir "${params.output}/k_${k}", mode: "move"
    
    tag {"kmc_tools - " + k}
    
    container "kmc.sif"
    // maxForks 2
    cpus 8
    memory '16.GB'

    input:
    set val(k), file("pneu_${k}.kmc_pre"), file("pneu_${k}.kmc_suf"), file("non_pneu_${k}.kmc_pre"),  file("non_pneu_${k}.kmc_suf") from kmc_simple_ch
    
    output:
    file("*.hist")
    file("*.fa")
    

    script:
    
    """
    kmc_tools simple pneu_${k} -ci2 non_pneu_${k} -ci2 intersect intersect_${k}  kmers_subtract  pneu_only_${k} reverse_kmers_subtract non_pneu_only_${k}
    kmc_tools transform pneu_only_${k} dump pneu_only_${k}.fa histogram pneu_only_${k}.hist
    kmc_tools transform non_pneu_only_${k} dump non_pneu_only_${k}.fa histogram non_pneu_only_${k}.hist
    kmc_tools transform intersect_${k} dump intersect_${k}.fa histogram intersect_${k}.hist
    """
}



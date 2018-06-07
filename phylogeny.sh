#!/bin/bash
## Note: outgroups may be setted as arguments at command line, seperated by a space.
  
touch log.txt 
mkdir bucky_files
mkdir ./Output/Treefiles ./Output/MaffClustalMrbayes ./Output/SuperMatrix
perl ./Scripts/orthphyl.pl    # align single-copy orthologs, build BI trees of each orthologus group by MrBayes.
bucky -n 10000000 -c 2 -o ./bucky_files/a1 ./bucky_files/*.in  # bayesian concordance analysis for tree topologies of each single-copy orthologus group. 
perl ./Scripts/raxml.pl $@    # select the single-copy orthologus groups with concordance single and combine their sequences into super alignment matrix, then build ML tree.
mv RAxML* ./Output/Treefiles/
mv Gene_family* ./Output/MaffClustalMrbayes/
mv bucky_files ./Output/
mv superalignment* ./Output/SuperMatrix/

rm onegroup.fasta mbbatch.txt log.txt

 

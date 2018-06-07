#!/bin/bash
## Note: outgroups may be setted as arguments at command line, seperated by a space.
  
mkdir ./Output/Coorthtrees
perl ./Scripts/coorthphyl.pl $@    # select the single-copy orthologus groups with concordance single and combine their sequences into super alignment matrix, then build ML tree.
rm onegroup.fasta 

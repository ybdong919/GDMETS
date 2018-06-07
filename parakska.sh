#!/bin/bash

mkdir ./Output/paralog_CDS
for parafile in ./Output/*paralog_seq.txt
do 
   perl ./Scripts/para_cds_output.pl ${parafile}
done
rm onefamilygenes.fasta information.txt alignment*
rm yn00.ctl rub rst* 2YN*

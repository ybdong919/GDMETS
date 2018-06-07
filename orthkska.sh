#!/bin/bash

mkdir ./Output/ortholog_CDS
perl ./Scripts/orth_cds_output.pl
rm onefamilygenes.fasta information.txt alignment*
rm yn00.ctl rub rst* 2YN*

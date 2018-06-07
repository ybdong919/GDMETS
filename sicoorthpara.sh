#!/bin/bash

##### Note1: Three commandline arguments are required, which are the number of tested samples, user accout name and keywords in MySQL.
##### Note2: Before running the shell script, make sure 1) Trinity (version:trinityrnaseq_r20131110) has been correctly installed;
#####                                                   2) MySQL server (version: mysql-5.1.42-linux-x86_64-glibc23) has been correctly installed;
#####                                                   3) MySQL server has been started (./bin/mysqld_safe --defaults-file=mysql.cnf &);
#####                                                   4) Root account in MySQL has been created;
#####                                                   5) User account (such as, named as "schema", keywords as "1234") in MySQL has been created;
#####                                                   6) Perl modules DBI, DBD::mysql and Data::Dumper are all installed and working;
#####                                                   7) orthomcl (orthomclSoftware-v2.0.9) has been correctly installed;
#####                                                   8) orthomcl.config file has been filled out and copied to the directory ".../SiGeOrtholog/my_orthomel_dir/"
#####                                                   9) mcl has been correctly installed.

##### Step1: To generate contigs by de novo transcriptome assembly in Trinity.
##### Step2: To generate gene family cluster using orthomcl software.
##### Step3: To generate single copy orthologs by custom perl script.

perl ./Scripts/createdb.pl $2 $3    # create a new empty 'orthomcl' database in MySQL
orthomclInstallSchema ./my_orthomcl_dir/orthomcl.config
mv ./Data/*.gz ./
mkdir ./Output/Fasta
for leftarge in *left.fq.gz
do
  rightarge=$(echo ${leftarge} | sed 's/left/right/') 
  #echo ${rightarge} 
  Trinity.pl --seqType fq --JM 3G --left ${leftarge} --right ${rightarge} --output ${leftarge}_trinity_dir    # de novo contig-assembly from transcriptome reads (Trinity version: Trinityrnaseq_r20131110)
  newname=$(echo ${leftarge}|sed 's/\.left\.fq\.gz//') 
  echo ${newname} >> sample_name_list.txt
  
  mv ./${leftarge}_trinity_dir/Trinity.fasta ./Output/Fasta/${newname}.fasta
  rm -r ${leftarge}_trinity_dir
  rm *.fq
  
  #####Using orthomcl software, to generate gene family clusters
  orthomclAdjustFasta ${newname} ./Output/Fasta/${newname}.fasta 1    # the name of the file in fasta format created by this command should only include one dot before suffix "fasta" (namely, '.fasta'). Such as "abc_10k.fasta" is right, but "abc.10k.fasta" is wrong. The latter will cause running wrong in the next command "orthomclFilterFasta"
  mkdir compliantFasta
  mv *.fasta ./compliantFasta/ 
done
mv ./*.gz ./Data/
orthomclFilterFasta ./compliantFasta/ 30 20    
makeblastdb -in goodProteins.fasta -dbtype nucl -out goodProteinsDB
blastall -v 100000 -b 100000 -m 8 -d goodProteinsDB -i goodProteins.fasta -p blastn -o ava.txt
orthomclBlastParser ava.txt ./compliantFasta/ > ./similarSequences.txt
orthomclLoadBlast ./my_orthomcl_dir/orthomcl.config ./similarSequences.txt
orthomclPairs ./my_orthomcl_dir/orthomcl.config orthomcl_pairs_log cleanup=no
orthomclDumpPairsFiles ./my_orthomcl_dir/orthomcl.config
mcl mclInput --abc -I 1.5 -o mclOutput
orthomclMclToGroups Gene_family 1 <mclOutput> ./Output/groups.txt

perl ./Scripts/singlecopyorthologs.pl $1  #generate and output single copy orthologs including all species
perl ./Scripts/paralogs.pl      #generate and output paralogs files
perl ./Scripts/coortholog.pl $1   #generate and output co-orthologs including all species
mv goodProteins.fasta ./Output/
mv sample_name_list.txt ./Output/
rm good* ava.txt mcl* poorProteins.fasta similarSequences.txt orthomcl_pairs_log
rm -r pairs compliantFasta
rm -r ./Output/Fasta
perl ./Scripts/dropdb.pl $2 $3     #drop the'orthomcl' database used above in MySQL




#!/usr/bin/perl -w
# commandline argments as outgroups are optional.

my $file="./Output/all_species_co_ortholog_seq.txt";
open (INFILE,'<',$file) or die;
my @infile=<INFILE>;
my @grouptitle;
my %seqs;
my $inum=0;
my $jnum=0;
foreach (@infile){
	if (/^Gene/){
		chomp $_;
		$_=~s/:$//;
	   $grouptitle[$inum]=$_;
	   #print $seqtitle[$inum];
	   $jnum=$inum;
	   $inum +=1;	   
	}else{
       $seqs{$grouptitle[$jnum]} .= $_;      
    }
}
foreach my $title (@grouptitle){	
	my $musclefile=$title."_align.phy";
	my $familyseqs=$seqs{$title};
	$familyseqs=~s/\|.*//g;	
	my @familyseqs_line=split/\n/,$familyseqs;
	my $numover=1;
	my @outgroupnames;
	my $outgroupnum=0;
	OUTER: foreach (@familyseqs_line){
		if (/^>/){			
            foreach my $argu (@ARGV){
				if ($_=~/\Q$argu/){
				    $_ .= "@".$numover;
				    $numover +=1;
				    $outgroupnames[$outgroupnum]=$_;
				    $outgroupnames[$outgroupnum]=~s/^>//;
				    #print $outgroupnames[$outgroupnum];
				    $outgroupnum +=1;
				    next OUTER;				    
				}			
			}
			$_ .= "#".$numover;
			$numover +=1;			
		}				
    }
	my $revisedfamilyseqs=join"\n", @familyseqs_line;		
	open (OUTFILE,'>',"onegroup.fasta") or die;
	print OUTFILE $revisedfamilyseqs;
	system ("muscle -in onegroup.fasta -phyiout $musclefile"); # align each co-orhtolog group and output PHYLIP format by MUSCLE 
	my $outgrouparg=@outgroupnames;
	if ($outgrouparg==0){
		system ("raxmlHPC -f a -# 100 -m GTRGAMMA -s $musclefile -n trees -x 1234");
	}else{
		my $outgroupstring = join (',', @outgroupnames);
		system ("raxmlHPC -f a -# 100 -m GTRGAMMA -o $outgroupstring -s $musclefile -n trees -x 1234");
	}	
	system ("mkdir ./Output/Coorthtrees/$title");
	system ("mv RAxML* ./Output/Coorthtrees/$title");
	system ("mv $musclefile* ./Output/Coorthtrees/$title");
    close OUTFILE;
}
close INFILE;


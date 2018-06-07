#!/usr/bin/perl -w
# commandline argments as outgroups are optional. 
# select the genes with concordance phylogeny single to joint their alignments into super-matrix. Then build phylogeny tree using RaxML 
open (CONTREE,'<',"./bucky_files/a1.concordance") or die;
my @contree=<CONTREE>;
my $i=0;
my $contree;
foreach (@contree){
    $i+=1;
	if(/^Population Tree/){
	   $contree=$contree[$i];
	   chomp $contree;
	   #print $contree;
	   last;
	}
}

open (GENENUM,'<',"./bucky_files/a1.gene")or die;
my @genenum=<GENENUM>;
my @grouptitle;
my %seqs;
my $inum=0;
my $jnum=0;
foreach (@genenum){
	if (/^Gene/){
		chomp $_;
		$_=~s/:$//;
	   $grouptitle[$inum]=$_;
	   #print $grouptitle[$inum];
	   $jnum=$inum;
	   $inum +=1;	   
	}else{
       $seqs{$grouptitle[$jnum]} .= $_;      

    }
}

my @numgene;
my $k=0;
foreach (@grouptitle){
	#print "$_\n";
	#print $contree;
	#print $seqs{$_};
    if($seqs{$_}=~/\Q$contree/g){
       $numgene[$k]=substr($_,5);
       #print "$numgene[$k]\n";
       $k +=1;
    }
}

open (GENEINPUT,'<',"./bucky_files/a1.input")or die;
my @geneinput=<GENEINPUT>;
my $geneinputnum=@geneinput;
my @genenamelist;
my $g=0;
foreach my $num (@numgene){
	#print "$num";
	
	for(my $i=2;$i< $geneinputnum-1;$i++){
		#print $line;
		my $line=$geneinput[$i];
		$line=~s/^\s+//;
		
		my @line= split/\s/,$line;
		#my $numline=@line;
		#print "$numline\n";		
		if($line[0] == $num){			
			my @cells=split/\/|\./,$line[1];
			$genenamelist[$g]=$cells[3].".fasta";
			#print "$genenamelist[$g]\n";
			$g +=1;
			last;
	    }
	}	
}

open (GROUPSEQS,'<',$genenamelist[0])or die;
my @groupseqs=<GROUPSEQS>;
my @samplenames;
my %sequences;
my $numx=0;
my $numy=0;
foreach (@groupseqs){
	chomp $_;
	if (/^>/){
	   $samplenames[$numx]=$_;
	   #print $seqtitle[$inum];
	   $numy=$numx;
	   $numx +=1;	   
	}else{
       $sequences{$samplenames[$numy]} .= $_;      
    }
}

my $many=@genenamelist;
for (my $i=1;$i<$many;$i++){
	open (GROUPSEQX,'<',$genenamelist[$i])or die;
	my @groupseqx=<GROUPSEQX>;
	my @xname;
	my %xhash;
	my $xi=0;
	my $xj=0;
	foreach (@groupseqx){
		chomp $_;
		if (/^>/){
			$xname[$xi]=$_;
			$xj=$xi;
			$xi +=1;
		}else{
		    $xhash{$xname[$xj]} .=$_;
		}
	}
	foreach (@xname){
	   $sequences{$_} .=$xhash{$_};	
	}
	close GROUPSEQX;	
}

my $seqkey;
my $seqvalue;
open (SUPERFASTA,'>',"superalignments.fasta") or die;
while (($seqkey, $seqvalue)=each %sequences){
	print SUPERFASTA "$seqkey\n$seqvalue\n";
}
close SUPERFASTA;
close GROUPSEQS;
close GENEINPUT;
close GENENUM;
close CONTREE;

system ("clustalw superalignments.fasta -convert -output=PHYLIP");  # convert FASTA into PHYLIP by ClustalW
my $outgrouparg=@ARGV;
if ($outgrouparg==0){
   system ("raxmlHPC -f a -# 500 -m GTRGAMMA -s superalignments.phy -n trees -x 1234");
}else{
   my $outgroupstring = join (',', @ARGV);
   system ("raxmlHPC -f a -# 500 -m GTRGAMMA -o $outgroupstring -s superalignments.phy -n trees -x 1234");
}

#!/usr/bin/perl -w

my $file="./Output/single_copy_ortholog_seq.txt";
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
	my $mafftfile=$title."_align.fasta";
	my $familyseqs=$seqs{$title};
	$familyseqs=~s/\|.*//g;
	open (OUTFILE,'>',"onegroup.fasta") or die;
	print OUTFILE $familyseqs;
	system ("mafft --auto onegroup.fasta > $mafftfile");    # align each single-copy orhtolog-group by MAFFT 
	
	system ("clustalw $mafftfile -convert -output=NEXUS");  # convert FASTA into NEXUS by ClustalW
	
	#my $nexus=$title."_align.nxs";
	#open (NEXUS,'<',$nexus) or die;
	#my @nexus=<NEXUS>;
	#foreach (@nexus){   
	 #   $_=~s/\|.*\n/\n/;                 # mybayes can not identify "|" sign, so replace "|" with "_".
	#}
	my $mbnexus=$title."_align.nxs";
	#open (MBNEXUS,'>',$mbnexus) or die;
	#foreach (@nexus){
	 #   print MBNEXUS $_;
	#}
	
	open (MBBATCH,'>',"mbbatch.txt")or die;
	#print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\nMcmc ngen=10000000 samplefreq=1000 file=$mbnexus1;\nMcmc file=$mbnexus2;\nMcmc file=$mbnexus3;\nquit;";
	#print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\nMcmc ngen=10000 samplefreq=10;\nsump burnin=250;\nsumt burnin=250;\nquit;";
	print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\nMcmc ngen=10000000 samplefreq=1000;\nquit;";
	#print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\nMcmc ngen=10000 samplefreq=10;\nquit;";
	
	############################################## set outgroup argument in Mrbayes. Note: only one outgroup is allowed in Mybayes software！############################################
	## my $outgrouparg=@ARGV;
    ## if ($outgrouparg==0){
    ##      print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\nMcmc ngen=10000 samplefreq=10;\nquit;";
    ## }else{
    ##     my $outgroupstring = join (',', @ARGV);
    ##     print MBBATCH "set autoclose=yes nowarn=yes;\nExecute $mbnexus;\nlset nst=6 rates=invgamma;\noutgroup $outgroupstring;\nMcmc ngen=10000 samplefreq=10;\nquit;";
    ## }
	######################################################################################################################################################################################
		
	system ("mb mbbatch.txt log.txt");     # generate BI trees of each single-copy-orhtolog group by MrBayes in batch mode.	
	system ("mbsum -n 2500 -o ./bucky_files/$mbnexus.in $mbnexus.run?.t");   # if change MBBATCH, this line also need change!
	#close NEXUS;
	#close MBNEXUS;	
	close MBBATCH;
    close OUTFILE;
}
close INFILE;

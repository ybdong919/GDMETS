#!/usr/bin/perl -w
#### PartI: get CDS of each mRNA sequences
my $input=$ARGV[0];
my $samplename=$input;
$samplename=~s/^\.\/Output\///;
$samplename=~s/_seq.txt$//;

open (INPUT,'<',$input)or die;
my @input=<INPUT>;
my @familynames;
my %sequences;
my $numx=0;
my $numy=0;
foreach (@input){
	
	if (/^Gene_family/){
	   chomp $_;
	   $_=~s/:$//;
	   $familynames[$numx]=$_;
	   #print $seqtitle[$inum];
	   $numy=$numx;
	   $numx +=1;	   
	}else{
	   
       $sequences{$familynames[$numy]} .= $_;      
    }
}
system ("mkdir ./Output/paralog_CDS/$samplename");
foreach (@familynames){
   open (OUTPUT,'>',"onefamilygenes.fasta")or die;
   print OUTPUT $sequences{$_};
   close OUTPUT;   
   system ("ESTScan -M ./args/Arabidopsis_thaliana.smat -o ./Output/paralog_CDS/$samplename/$_.fasta -ft information.txt onefamilygenes.fasta");
   
   #### Part II ##########################################################################################
   #### an empty gene_family_cds.fasta file means that no CDS regions are found by ESTScan !!! ##########
   if (-z "./Output/paralog_CDS/$samplename/$_.fasta"){
       next;  
   }
   
   #### For FASTA files, X to A, and then to delete stop codon at the end of sequence. ########################
   open (FASTAFILTER,'<',"./Output/paralog_CDS/$samplename/$_.fasta") or die;
   my @fastafilter=<FASTAFILTER>;
   my $linesnum=@fastafilter;   	         
   for (my $i=0; $i<$linesnum; $i++){
	   if ($fastafilter[$i]!~/^>/){
		   $fastafilter[$i]=~s/x/a/g;
	       $fastafilter[$i]=~s/X/A/g;	
	   }	   
	   if ($i>1 && $fastafilter[$i]=~/^>/ && $fastafilter[$i-1]=~/(taa\n)$|(tga\n)$|(tag\n)$|(TAA\n)$|(TGA\n)$|(TAG\n)$/){
		   $fastafilter[$i-1]=~s/(taa\n)$|(tga\n)$|(tag\n)$|(TAA\n)$|(TGA\n)$|(TAG\n)$/\n/;		   
	   }	   
   }   
   $fastafilter[$linesnum-1]=~s/(taa\n)$|(tga\n)$|(tag\n)$|(TAA\n)$|(TGA\n)$|(TAG\n)$/\n/;
   open (OUTPUTFILTER,'>',"./Output/paralog_CDS/$samplename/$_.filter.fasta") or die;
   foreach my $aa (@fastafilter){
        print OUTPUTFILTER $aa; 	   
   }
   close FASTAFILTER;
   close OUTPUTFILTER;
   
   #### To align sequences in each paralogous group, and then to convert FASTA into PAML format  ##################
   system ("mafft --auto ./Output/paralog_CDS/$samplename/$_.filter.fasta >alignment");
   system ("clustalw alignment -convert -output=GDE");
   system ("clustalw alignment -convert -output=PHYLIP");
   my $firstlinename;
   open (PHYFILE,'<',"alignment.phy")or die;
   open (GDEFILE,'<',"alignment.gde")or die;
   my @phyfile=<PHYFILE>;
   $firstlinename=$phyfile[0];
   my @gdefile=<GDEFILE>;
   foreach my $gdeline (@gdefile){
	   $gdeline=~s/^#//;
   }
     
   my $pamlformatfile="./Output/paralog_CDS/$samplename/$_.paml";
   open (PAMLFORMAT,'>',$pamlformatfile)or die;
   print PAMLFORMAT "$firstlinename";
   foreach my $onerow (@gdefile){
      print PAMLFORMAT $onerow;   
   }   
   close PAMLFORMAT;
   close GDEFILE;
   close PHYFILE;   
   
   #### PartIII: to get ds and dn values of every pairs in each paralogous group ######################
   #### to fill out CTL file in folder "args".
   open (CTL,'<',"./args/yn00.ctl") or die;
   open (FILLEDCTL,'>',"yn00.ctl") or die;
   my @ctl=<CTL>;
   $ctl[0]=~s/\r\n//;
   $ctl[1]=~s/\r\n//;
   $ctl[0].="./Output/paralog_CDS/$samplename/$_.paml"."\n";
   $ctl[1].="./Output/paralog_CDS/$samplename/$_.yn"."\n";
   foreach (@ctl){
       print FILLEDCTL $_;
   }
   close CTL;
   close FILLEDCTL;
   
   system ("yn00"); # to run yn00 in PAML software.
   
   #### to extract the line with ds, dn from *.yn file.
   open (DSDN,'<',"./Output/paralog_CDS/$samplename/$_.yn")or die;
   open (DSDNFILE,'>>',"./Output/paralog_dsdn.txt")or die;
   my @dsdn=<DSDN>;
   my $ynlines=@dsdn;
   my @dsdnfile;
   my $dsdnline=0;
   for (my $i=0;$i<$ynlines;$i++){
	   if ($dsdn[$i]=~/^seq\. seq\./){
		   $dsdnfile[$dsdnline]="files"."\t".$dsdn[$i];
		   $dsdnfile[$dsdnline]=~s/ +/\t/g;
		   if (-z "./Output/paralog_dsdn.txt"){
			   print DSDNFILE $dsdnfile[$dsdnline];
		   }
		   my $j=$i+2;
		   until ($dsdn[$j]=~/^\s*$/){
			   $dsdnline +=1;
			   $dsdnfile[$dsdnline]=$dsdn[$j];
			   $dsdnfile[$dsdnline]=~s/ +/\t/g;
			   $dsdnfile[$dsdnline]=$samplename."/".$_.$dsdnfile[$dsdnline];
			   print DSDNFILE $dsdnfile[$dsdnline]; 		   
			   $j +=1;			   
		   }
		   last;		   
	   }
   }
   close DSDN; 
}
close INPUT;
close DSDNFILE;

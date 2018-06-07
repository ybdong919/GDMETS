#!/usr/bin/perl -w

my $input="./Output/single_copy_ortholog_seq.txt";
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
foreach (@familynames){
	my $onefamilyseqs=$sequences{$_};
	$onefamilyseqs=~s/\|.*//g;
   open (OUTPUT,'>',"onefamilygenes.fasta")or die;
   print OUTPUT $onefamilyseqs;
   close OUTPUT;   
   system ("ESTScan -M ./args/Arabidopsis_thaliana.smat -o ./Output/ortholog_CDS/$_.fasta -ft information.txt onefamilygenes.fasta");
   
   #### Part II ##########################################################################################
   #### an empty gene_family_cds.fasta file means that no CDS regions are found by ESTScan !!! ##########
   if (-z "./Output/ortholog_CDS/$_.fasta"){
       next;  
   }
   
   #### For FASTA files, X to A, and then to delete stop codon at the end of sequence. ########################
   open (FASTAFILTER,'<',"./Output/ortholog_CDS/$_.fasta") or die;
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
   open (OUTPUTFILTER,'>',"./Output/ortholog_CDS/$_.filter.fasta") or die;
   foreach my $aa (@fastafilter){
        print OUTPUTFILTER $aa; 	   
   }
   close FASTAFILTER;
   close OUTPUTFILTER;
   
   #### To align sequences in each ortholog group, and then to convert FASTA into PAML format  ##################
   system ("mafft --auto ./Output/ortholog_CDS/$_.filter.fasta >alignment");
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
     
   my $pamlformatfile="./Output/ortholog_CDS/$_.paml";
   open (PAMLFORMAT,'>',$pamlformatfile)or die;
   print PAMLFORMAT "$firstlinename";
   foreach my $onerow (@gdefile){
      print PAMLFORMAT $onerow;   
   }   
   close PAMLFORMAT;
   close GDEFILE;
   close PHYFILE;   
   
   #### PartIII: to get ds and dn values of every pairs in each ortholog group ######################
   #### to fill out CTL file in folder "args".
   open (CTL,'<',"./args/yn00.ctl") or die;
   open (FILLEDCTL,'>',"yn00.ctl") or die;
   my @ctl=<CTL>;
   $ctl[0]=~s/\r\n//;
   $ctl[1]=~s/\r\n//;
   $ctl[0].="./Output/ortholog_CDS/$_.paml"."\n";
   $ctl[1].="./Output/ortholog_CDS/$_.yn"."\n";
   foreach (@ctl){
       print FILLEDCTL $_;
   }
   close CTL;
   close FILLEDCTL;
   
   system ("yn00"); # to run yn00 in PAML software.
   
   #### to extract the line with ds, dn from *.yn file.
   open (DSDN,'<',"./Output/ortholog_CDS/$_.yn")or die;
   open (DSDNFILE,'>>',"./Output/ortholog_dsdn.txt")or die;
   my @dsdn=<DSDN>;
   my $ynlines=@dsdn;
   my @dsdnfile;
   my $dsdnline=0;
   
   my @name_num;
   for (my $i=0;$i<$ynlines;$i++){
	   if ($dsdn[$i]=~/^Use runmode/){
		   my $iny=$i+2;
		   my $inx=0;
		   until ($dsdn[$iny]=~/^\s*$/){
			     my @namecells=split/ +/,$dsdn[$iny];
			     chomp $namecells[0];
		         $name_num[$inx]=$namecells[0];
		         $iny +=1;
		         $inx +=1;		   
	       }
	   }	   
	   
	   if ($dsdn[$i]=~/^seq\. seq\./){
		   $dsdnfile[$dsdnline]="files"."\t".$dsdn[$i];
		   $dsdnfile[$dsdnline]=~s/ +/\t/g;
		   $dsdnfile[$dsdnline]=~s/seq\.\tseq\./spec1\tspec2/;
		   if (-z "./Output/ortholog_dsdn.txt"){
			   print DSDNFILE $dsdnfile[$dsdnline];
		   }
		   my $j=$i+2;
		   until ($dsdn[$j]=~/^\s*$/){
			   $dsdnline +=1;
			   $dsdnfile[$dsdnline]=$dsdn[$j];
			   $dsdnfile[$dsdnline]=~s/ +/\t/g;
			   $dsdnfile[$dsdnline]=$_.$dsdnfile[$dsdnline];
			   my @outputline=split/\t/,$dsdnfile[$dsdnline];
			   my $z=$outputline[1]-1;
			   my $v=$outputline[2]-1;
			   $outputline[1]=$name_num[$z];
			   $outputline[2]=$name_num[$v];
			   $dsdnfile[$dsdnline]=join "\t", @outputline;
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

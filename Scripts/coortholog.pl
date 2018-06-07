#!/usr/bin/perl -w

##### One commandline argument is required.
##### Step1: generate a name list of co-orthologs including all species #####
my $inputfile="./Output/groups.txt";
open (ALLGROUPS,'<',$inputfile) or die;
my @allgroups=<ALLGROUPS>;
my $i=0;
my @coortholog;
#print "$ARGV[0]\n";

foreach my $oneline (@allgroups){
   chomp $oneline;
   #print "$oneline\n";
   my @columns=split / /, $oneline;
   
   my $num=@columns;
   #print "$num\n";
   my $samples=$num-1;
   
   if ($samples > $ARGV[0]){
       my $firsttitle=shift(@columns);
       #print "$firsttitle\n";
       my %hush;
       foreach my $othertitle (@columns){
		   #print "$othertitle\n";
	       my @subtitles=split/\|/, $othertitle;
	       #my $testnum=@subtitles;
	       #print "$testnum\n";
	       #print "$subtitles[0]";
	       $hush{$subtitles[0]}=$subtitles[1];           	   
	   }	   
	   my @keys=keys %hush;
	   my $keynum=@keys;
	   #print "$keynum\n";
	   if ($keynum==$ARGV[0]){
		  $coortholog[$i]=$oneline; 
		  $i +=1;  
	   }	   
   }
}

open (OUTPUT,'>',"./Output/all_species_co_ortholog_list.txt")or die;
foreach (@coortholog){
   print OUTPUT "$_\n";
} 

close OUTPUT;
close ALLGROUPS;

##### Step2: generate all_species_co_ortholog_seq.fasta file including sequences in fasta format #####
my $input2="./Output/all_species_co_ortholog_list.txt";
my $input3="goodProteins.fasta";
open (LISTFILE,'<',$input2)or die;
open (SEQUENCES,'<',$input3)or die;
open (OUTPUT2,'>>',"./Output/all_species_co_ortholog_seq.txt")or die;

my @input2=<LISTFILE>;
my @input3=<SEQUENCES>;
my @seqtitle;
my %seqs;
my $inum=0;
my $jnum=0;
foreach (@input3){
	if (/^>/){
	   $seqtitle[$inum]=$_;
	   #print $seqtitle[$inum];
	   $jnum=$inum;
	   $inum +=1;
	   
	}else{
       $seqs{$seqtitle[$jnum]} .= $_;
       
    }
}
#print $seqs{$seqtitle[$jnum]};

my @input2title;
my $numinput2=@input2;
for (my $i=0;$i<$numinput2;$i++){
	chomp $input2[$i];
	my @column2=split/ /, $input2[$i];
    $input2title[$i]=$column2[0];
    #print "$input2title[$i]\n";
    print OUTPUT2 "$input2title[$i]\n";
    shift @column2;
    foreach my $colu (@column2){
		chomp $colu;
		#print "$colu\n";
		foreach my $seqtit (@seqtitle){           
            my $seqtitpart= $seqtit;
            chomp $seqtitpart;
            $seqtitpart=~s/^>//;		
			if ($seqtitpart eq $colu){               
			   print OUTPUT2 "$seqtit$seqs{$seqtit}"; 
			}	
	    }
    }    
}

close OUTPUT2;
close LISTFILE;
close SEQUENCES;


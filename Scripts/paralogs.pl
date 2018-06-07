#!/usr/bin/perl -w

##### 1: generate paralog list file for each sample #####
##### 2: generate paralog sequences for each sample #####

my $inputseq="goodProteins.fasta";
open (SEQUENCES,'<',$inputseq)or die;
my @inputseq=<SEQUENCES>;
my @seqtitle;
my %seqs;
my $inum=0;
my $jnum=0;
foreach (@inputseq){
	if (/^>/){
	   $seqtitle[$inum]=$_;	   
	   $jnum=$inum;
	   $inum +=1;	   
	}else{
       $seqs{$seqtitle[$jnum]} .= $_;       
    }
}

my $sample_names="sample_name_list.txt";
my $inputfile="./Output/groups.txt";
open (ALLGROUPS,'<',$inputfile) or die;
open (NAMELIST,'<',$sample_names) or die;
my @allgroups=<ALLGROUPS>;
my @samplenames=<NAMELIST>;
foreach my $samplename (@samplenames){
   	chomp $samplename;
   	my $output="./Output/".$samplename."_paralog_list.txt";
   	open (OUTPARALOG,'>',$output) or die;
   	my @paralogs;
   	my $i =0;
	foreach my $oneline (@allgroups){
        chomp $oneline;
        my @columns=split / /, $oneline;
        my $num=@columns;
        my $samples=$num-1;
        my $firsttitle=shift(@columns);
        my $addsamplename;
        my $samplex=0;
        foreach my $sampletitle (@columns){			
	       if ($sampletitle=~/\Q$samplename/){
			   $addsamplename .= " ".$sampletitle;
			   $samplex +=1;			   
		   }	                	   
	    }	   
        if ($samplex > 1){
			$paralogs[$i]=$firsttitle.$addsamplename;
			$i +=1;
		}
	}
	foreach (@paralogs){
		print OUTPARALOG "$_\n";		
	}
	close OUTPARALOG;
	
	my $output2="./Output/".$samplename."_paralog_seq.txt";
	open (OUTPUT2,'>', $output2) or die;
	my @input2title;
    my $numinput2=@paralogs;
    for (my $i=0;$i<$numinput2;$i++){
	    chomp $paralogs[$i];
	    my @column2=split/ /, $paralogs[$i];
        $input2title[$i]=$column2[0];
        #print "$input2title[$i]\n";
        print OUTPUT2 "$input2title[$i]\n";
        shift @column2;
        foreach my $colu (@column2){
			chomp $colu;                                        ## debug ##
		   #print "$colu";                                  
		    foreach my $seqtit (@seqtitle){
				my $seqtitpart= $seqtit;                        ## debug ## 
                chomp $seqtitpart;                              ## debug ##
                $seqtitpart=~s/^>//;                            ## debug ##
			    if ($seqtitpart eq $colu){                      ## debug ##
			       print OUTPUT2 "$seqtit$seqs{$seqtit}";
			    }
	        }
        }    
     }
	 close OUTPUT2;	
}
close NAMELIST;
close ALLGROUPS;
close SEQUENCES;


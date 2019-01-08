$input=$ARGV[0];
$output=$ARGV[1];
$catalog=$ARGV[2];
$catalog_idx=$ARGV[3];
$tag=$ARGV[4];
chomp($input);
chomp($output);
chomp($catalog);
chomp($catalog_idx);
chomp($tag);
print "INPUT:$input\nOUTPUT:$output\nCATALOG:$catalog\nCATALOG_INDEX:$catalog_idx\nTAG:$tag\n";
@catalog=split(',',$catalog);
@catalog_idx=split(',',$catalog_idx);
@tag=split(',',$tag);
my @index;
for($i=0;$i<@catalog_idx;$i++){
	open(IDX,$catalog_idx[$i]) or die "no file found $catalog_idx\n";
	my @temp;
	while(<IDX>){
		chomp($_);
		if($_ !~ m/^#/ & $_ !~ m/^_/){
			@t=split("\t",$_);
			push(@temp,$t[0]);
		}
	}
	close(IDX);
	$tmp=join("\t",@temp);
	push(@index,$tmp);
	undef @temp;
}

sub annotate {
	@args=split(',',$_[0]);
	$tabix=$args[0];
	$chr=$args[1];
	$start=$args[2];
	$stop=$args[3];
	$catalog=$args[4];
	$catalog_idx=$args[5];
	@idx=split("\t",$catalog_idx);
	if(@args>6){
		$ref=$args[6];
		$alt=$args[7];
	}
	$sys="$tabix $catalog $chr".':'.$start.'-'.$stop;
	chomp($sys);
	
	$line=`$sys`;
	#die "$sys\n$line\n";
	chomp($line);
	@lines=split("\n",$line);
	$final_res="";
	for($i=0;$i<@lines;$i++){
		@temp=split("\t",$lines[$i]);
		$temp[3]=~ s/^{//g;
		$temp[3]=~ s/}$//g;
		@array=split(',',$temp[3]);
		
		my %final;
		for($k=0;$k<@array;$k++){
			@keys=split(':',$array[$k]);
			$key=$keys[0];
			$value=$keys[1];
			$key =~ s/"//g;
			$value =~ s/"//g;
			$final{$key}=$value;
		}
		#identifying if catalog has ref and alt
		if(@args>6){
			#print "@args\n";
			#die "$ref $alt $final{$idx[2]}\n";
			if($ref eq $final{$idx[2]} & $alt eq $final{$idx[3]})
			{
				for($m=0;$m<@idx;$m++){
					if(exists($final{$idx[$m]})){
						$value=$final{$idx[$m]};
					}else{
						$value="NA";
					}
					if($final_res eq ""){
						$final_res=$value;
					}else{
						$final_res=$final_res."\t".$value;
					}
				}
				$i=@lines;
			}
		}else{
			for($m=0;$m<@idx;$m++){
				if(exists($final{$idx[$m]})){
					$value=$final{$idx[$m]};
				}else{
					$value="NA";
				}
				if($final_res eq ""){
					$final_res=$value;
				}else{
					$final_res=$final_res."\t".$value;
				}
			}
			$i=@lines;
		}
		undef %final;
	}
	
	if($final_res eq ""){
		for($m=0;$m<@idx;$m++){
			$value="NA";
			if($final_res eq ""){
				$final_res=$value;
			}else{
				$final_res=$final_res."\t".$value;
			}
		}	
	}
	#die $final_res."\n";
	return($final_res);
}

$tabix2="/research/bsi/development/pipelines/PanMutsRx/1.1.1/tools/HTSDIR/htslib-1.9/bin/bin/tabix";
$tabix1="/research/bsi/tools/biotools/tabix/0.2.5/tabix";
open(BUFF,$input) or die "no input file found $input\n";
open(WRBUFF,">$output") or die "no output file found $output\n";
while(<BUFF>){
	if($_ =~ m/^##/)
	{
		print WRBUFF $_;
	}
	elsif($_ =~ m/^#/)
	{
		chomp($_);
		print WRBUFF $_;
		for($i=0;$i<@index;$i++){
			@temp=split("\t",$index[$i]);
			for($j=0;$j<@temp;$j++){
				print WRBUFF "\t".$tag[$i].'.'.$temp[$j];
			}
			undef @temp;
		}
		print WRBUFF "\n";
	}
	else
	{
		chomp($_);
		$final_line=$_;
		@a=split("\t",$_);
		$chr=$a[0];
		$pos=$a[1];
		$ref=$a[3];
		$alt=$a[4];
		$chr=~ s/chr//g;
		$start=$pos;
		
		for($num=0;$num<@index;$num++){
			@temp=split("\t",$index[$num]);
			$tab=$tabix1;
			$stop=$start;
			
			if($tag[$num] =~ m/^WGSA/){
				$tab=$tabix2;
				$stop=$start+1;	
			}
			$tab=$tab.','.$chr.','.$start.','.$stop.','.$catalog[$num].','.$index[$num];
			if($tag[$num] !~ m/^LINSIGHT/){
				$tab=$tab.','.$ref.','.$alt;	
			}
			#print "$num\t$tag[$num]\t$tab\n";
			$ret=annotate($tab);
			$final_line=$final_line."\t".$ret;
			#print @index." $num $tab\n$ret\n";			
		}
		#
		print WRBUFF $final_line."\n";
		#die "suces\n";
	}
}
close(BUFF);
close(WRBUFF);

#!/usr/bin/perl
#RecipeConverter.pl v 1.0
#Converts recipes written in a standard human readable form into LaTEX code that can then be converted to a PDF or image

#Get the name of the file
$input=$ARGV[0];
print "INPUT:$input\n";
if (!$input){$input='chocolatecake.txt';}

open RECIPE, "<$input";

$inStep=0;#if 0, we're awaiting a label line; otherwise a list of ingredients

#Read it line by line, and add line to $notes or %instructions
while (<RECIPE>){
	$line=$_; 
	($line, $junk) = split(/\s*#/, $line);
	chomp $line; 
	
	if ($line=~ s/^\*//g){ #if it starts with a hash, it's a note
		$notes=$notes . $line . "\\\\";
	}
	
	
	elsif($line =~ /\:/ && $inStep==0){ #if it contains a colon, and follows a newline, it's a label & instruction
	    $unrecordedData=1; #record that we've started reading actual instructions
		($step, $instruction)=split(':', $line); 
		chomp $instruction; 
		
		@instructionLines=split('//', $instruction); #Convert `//` to newlines that will work in the table
		if ($instructions>1) { $instruction = "\\begin{tabular}{l}" . join('//', @instructionLines) . "\\end{tabular}}" }
		
		$inStep=1;
	}
	
	
	elsif( !($line =~ /\S/) ){ #if it's just whitespace, a step has ended or we haven't yet started
	
		if($unrecordedData==1){
			
			#Collapse what we've previously read one line of LaTEX	
			$markedup{$step}='\left. \begin{array}{ll} ';
			foreach (@ingredients) {$markedup{$step} .= " \\mbox{" . $_ . "} \\\\ ";}
			$markedup{$step} =  substr $markedup{$step}, 0, -3; #rip off the terminal newline, as we don't need it
			$markedup{$step} .= "& \\\\ \\end{array}\\right\\} \\begin{tabular}{l}" . $instruction . '\end{tabular}}';
					
			#clear variables ready for the next step
			$inStep=0;
			@ingredients=();
			$unrecordedData=0; 
			
		}	
		
	}
	
	else{ #otherwise, its an ingredient
		push @ingredients, $line;
	}
	
	
}
close INPUTFILE;


#Smoosh each step together; look through ech entry in %markedup, replacing and symbols with their marked-up expansions
#we want to replace every instance of '\mbox{<A>}' with $markedup{A}, where A is an alphanumerical string


 while ( $complete != 1){
	$complete=1;
	
	while(($key, $value) = each(%markedup)) {
		if( $markedup{$key} =~ /\\mbox\{\<(\w)\>\}/){
			$complete=0;
	
			($before, $after)=split('\mbox{<' . $1 . ">}", $markedup{$key});
			$before =  substr $before, 0, -1;
	 		$markedup{$key} = $before . $markedup{$1} . $after;
	
			delete($markedup{$1}); #we no longer need the inserted markup, as each step can only be directly referenced once			
		}
	}

}

#We print out the note as a title
chomp($notes);
print "\\textbf{$notes}\\vspace{0.4cm}\n\n" if $notes;



#and the actual instructions:
print values %markedup;	

#!/usr/bin/perl

$content = 0;
$dateok = 0;
print STDERR "---\n";
print STDERR "layout: post\n";
while(<STDIN>){
	if ($content && /class="meta"/) {
		$content = 0;
	}
	print if ($content && ! /class="submitted"/ && !/class="clear-block clear"/) ;
	if (!$content && /id="node-/) {
		$content = 1;	
	}
	if (/class="submitted">..., (\d+)\/(\d+)\/(\d+) - (\d+):(\d+)/ && !$dateok) {
	    print STDERR "date:   $3-$1-$2 $4:$5:00\n";
	    $dateok = 1;
	}
	if (/<title>(.*) \| .*<\/title>/) {
	    print STDERR 'title:  "'.$1."\"\n";
	}
	if (/ class="terms">/) {
	    $categ = '';
	    for (/title="" class="taxonomy_term_\d+">([^<]*)<\/a>/g) {
		$categ .= "$1\t";
	    }
#	    print STDERR "categories: $categ\n";
	}
}
print STDERR "---\n";

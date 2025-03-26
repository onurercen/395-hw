use strict;
use warnings;


my %variables;

#functions to evaluate expresisons
sub evaluate {
    my ($expr) = @_;
    
    #replace var
    $expr =~ s/([a-zA-Z_][a-zA-Z0-9_]*)/exists $variables{$1} ? $variables{$1} : 0/ge;
    
    #evaluate the expression
    my $result = eval $expr;
    
    if ($@) {
        print "Error: Invalid expression\n";
        return 0;
    }
    return $result;
}

# Main loop
while (1) {
    print "Enter a command (or 'exit' to quit): ";
    chomp(my $input = <STDIN>);
    
    last if $input eq 'exit';
    
    # Check for variable assignment (e.g., x = 5)
    if ($input =~ /^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*(.+)$/) {
        my $var = $1;
        my $expr = $2;
        
        
        $variables{$var} = evaluate($expr);
        print "$var = $variables{$var}\n";
    }
    else {
        # result of the artihmetic expression
        my $result = evaluate($input);
        print "Result: $result\n";
    }
}
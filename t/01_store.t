use lib '../allegro/lib';

use Test::More 'no_plan';
use Test::Exception;

use Data::Dumper;

use_ok( 'RDF::Trine::Store::AllegroGraph' );

use constant DONE => 0;

my $AG4_SERVER = $ENV{AG4_SERVER};

unless ($AG4_SERVER) {
    ok (1, 'Tests skipped. Use "export AG4_SERVER=http://my.server:port" before running the test suite. See README for details.');
    exit;
}

if (1||DONE) {
    use RDF::Trine::Store::AllegroGraph;
    my $trine = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/scratch/catlitter" );
    isa_ok ($trine, 'RDF::Trine::Store::AllegroGraph', 'catlitter trine created');
# test internals    
    isa_ok ($trine->{model}, 'RDF::AllegroGraph::Repository4', 'and it is an AGv4 repo');

    use RDF::AllegroGraph::Easy;
    my $storage = new RDF::AllegroGraph::Easy ($AG4_SERVER);
    use Fcntl;
    my $model = $storage->model ('/scratch/catlitter', mode => O_CREAT);
    $trine = RDF::Trine::Store->new_with_object ($model);
    isa_ok ($trine, 'RDF::Trine::Store::AllegroGraph', 'catlitter trine created');
    isa_ok ($trine->{model}, 'RDF::AllegroGraph::Repository4', 'and it is an AGv4 repo');

    $trine = RDF::Trine::Store->new_with_config ({
	storetype  => 'AllegroGraph',
	server     => $AG4_SERVER,
	catalog    => '/scratch',
	repository => '/catlitter',
    });
    isa_ok ($trine, 'RDF::Trine::Store::AllegroGraph', 'catlitter trine created');
    isa_ok ($trine->{model}, 'RDF::AllegroGraph::Repository4', 'and it is an AGv4 repo');
}

if (DONE) {
    use RDF::Trine::Store::AllegroGraph;
    my $trine = RDF::Trine::Store->new_with_string( "AllegroGraph;$AG4_SERVER/scratch/catlitter" );

#    my $ex = RDF::Trine::Namespace->new('http://example.com/');
#    warn  Dumper $ex->aaaa()->as_string;

    my $p1          = RDF::Trine::Node::Resource->new('http://example.org/alice');
    my $p2          = RDF::Trine::Node::Resource->new('http://example.org/eve');
    my $p3          = RDF::Trine::Node::Resource->new('http://example.org/bob');
    my $type        = RDF::Trine::Node::Resource->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
    my $person      = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/person');


    my $st          = RDF::Trine::Statement->new( $p1, $type, $person );
    my $st2         = RDF::Trine::Statement->new( $p1, $type, $person );
    my $st3         = RDF::Trine::Statement->new( $p3, $type, $person );

    is ($trine->count_statements( $st->nodes ), 0, 'no such statement');

    $trine->add_statement ($st);
    is ($trine->count_statements( $st->nodes ), 1, 'one such statement');

    $trine->add_statement ($st);
    is ($trine->count_statements( $st->nodes ), 1, 'one such statement, still');

    $trine->add_statement ($st2);
    is ($trine->count_statements( $st->nodes ), 1, 'one such statement, still');

    $trine->add_statement ($st3);

    my $stm = RDF::Trine::Statement->new (RDF::Trine::Node::Variable->new ('rumsti'), $type, $person);
    my $i = $trine->get_statements ($stm->nodes);
    my %expects = map { "http://example.org/".$_ => 1 } qw(alice bob);
    while (my $stm4 = $i->next) {
	is ($stm4->predicate->as_string, '<http://www.w3.org/1999/02/22-rdf-syntax-ns#type>', 'predicates are type');
	is ($stm4->object->as_string,    '<http://xmlns.com/foaf/0.1/person>',                'objects are person');
	delete $expects{$stm4->subject->uri_value};
    }
    ok (keys %expects == 0, 'no more expected');

    is ($trine->size, 2, 'size of store');

    $trine->remove_statement ($st);
    is ($trine->size, 1, 'size of store, after deletion');
    $trine->remove_statement ($st2);
    is ($trine->size, 1, 'size of store, after deletion, same');
    $trine->remove_statement ($st3);
    is ($trine->size, 0, 'size of store, after deletion');

    $trine->add_statement ($st);
    $trine->add_statement ($st3);

    is ($trine->size, 2, 'size of store, after insertion');
    $trine->remove_statements ($stm->nodes);
    is ($trine->size, 0, 'size of store, after pattern deletion');

    $trine->_nuke;
}


__END__

use RDF::AllegroGraph::Easy;
my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
use Fcntl;
my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

if (1||DONE) {
    is ((scalar $model->geotypes), 0, 'initially no geotypes');
}
__END__




if (DONE) {
    is ((scalar $model->geotypes), 0, 'initially no geotypes');

    my $c1 = $model->cartesian ("100x100", 10);
#    warn $c1;
    like ($c1, qr/franz\.com/, 'cartesian coord system');

    my $c2 = $model->cartesian ("100x100+50+50", 100);
#    warn $c2;
    like ($c2, qr/franz\.com/, 'cartesian coord system');

    my $c3 = $model->cartesian (50, 50, 150, 150, 100);
#    warn $c3;
    is ($c2, $c3, 'same cartesian coord system');

    ok( eq_set([$c1, $c2],
	       [ $model->geotypes ] ), 'geotypes changed' );


    use RDF::AllegroGraph::Utils qw(coord2literal);
    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:location>', coord2literal ($c1, 30, 30)],
		 ['<urn:x-me:catbert>',     '<urn:x-me:location>', coord2literal ($c1, 40, 40)],
		 ['<urn:x-me:tomcat>',      '<urn:x-me:location>', coord2literal ($c1, 60, 60)]);
    my @ss = $model->match ([undef, '<urn:x-me:location>', undef]);
    is ((scalar @ss), 3, 'adding location information');

    @ss = $model->inBox ($c1, '<urn:x-me:location>', 0, 0, 35, 35);
    is ((scalar @ss), 1, 'inBox 1');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 35, 35, 65, 65);
    is ((scalar @ss), 2, 'inBox 2');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 65, 65, 75, 75);
    is ((scalar @ss), 0, 'inBox 0');
    @ss = $model->inBox ($c1, '<urn:x-me:location>', 35, 35, 65, 65, { limit => 1 });
    is ((scalar @ss), 1, 'inBox limit 2->1');
    
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 30, 30, 1);
    is ((scalar @ss), 1, 'inCircle 1');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 30, 30, 15);
    is ((scalar @ss), 2, 'inCircle 2');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 40, 40, 40);
    is ((scalar @ss), 3, 'inCircle 3');
    @ss = $model->inCircle ($c1, '<urn:x-me:location>', 40, 40, 40, { limit => 2 });
    is ((scalar @ss), 2, 'inCircle 3->2');


#    warn Dumper \@ss;

#"30x30+20+20"
    
}

if (0&&DONE) {
    $model->spherical ({ scale => 5, unit => 'degree' });
    $model->add (['<urn:x-me:vienna>', '<urn:x-me:location>', $model->coordinate (45, 15) ]);
    $model->rectangle (25, 50, 0, 50);
}

#$model->disband;

END {
    $model->disband if $model;
}

__END__

if (DONE) {
#    my $storage = new RDF::AllegroGraph::Easy;
#    isa_ok ($storage, 'RDF::AllegroGraph::Server');

    my $storage;

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('xyz');
    } qr/ADDRESS/, 'invalid server address';

    throws_ok {
	$storage = new RDF::AllegroGraph::Easy ('http://localhost:1111', TEST => 1 );
    } qr/connect to localhost:1111/, 'non-working server address';

    lives_ok {
	$storage = new RDF::AllegroGraph::Easy ('http://localhost:1111', TEST => 0 );
    } 'no testing of connectivity'; 

    lives_ok {
	$storage = new RDF::AllegroGraph::Easy ($AG_SERVER, TEST => 1 );
    } 'testing of connectivity';

    
#    lives_ok {
#	$storage = new RDF::AllegroGraph::Easy (undef, TEST => 1 );
#    } 'testing of connectivity (default)';
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my %models = $storage->models;
    is (scalar keys %models, 0, 'no model to begin with');

    throws_ok {
	my $model = $storage->model ('/scratch/catlitter');
    } qr/cannot/, 'at start no catlitter';

    use Fcntl;
    my $model = $storage->model ('/scratch/catlitter', mode => O_CREAT);
    isa_ok ($model, 'RDF::AllegroGraph::Repository', 'catlitter created');

    $model->disband;

    throws_ok {
	my $model = $storage->model ('/scratch/catlitter');
    } qr/cannot/, 'at end no catlitter';


# TODO wrong path /xxx
# TODO create several and delete
}

if (DONE) {
   my $server = new RDF::AllegroGraph::Server (ADDRESS => $AG_SERVER);
   my $vienna = new RDF::AllegroGraph::Catalog (NAME => '/scratch', SERVER => $server);

   like ($vienna->version, qr/^3\./, 'version');
}



    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 1, 'added: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:rho>']);
    is ($model->size, 2, 'added: model of 2');
    
    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 1, 'replaced: model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:ketty>'],
	);
    is ($model->size, 4, 'replaced/added: model of 4');

    $model->delete (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>']);
    is ($model->size, 3, 'deleted (fact): model of 3');

    $model->delete ([undef, '<urn:x-me:hates>', undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->delete (['<urn:x-me:rumsti>', undef, undef]);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
		    [undef, undef, '<urn:x-me:kitty>' ]	);
    is ($model->size, 1, 'deleted (wildcard): model of 1');

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);
    $model->delete ([undef, '<urn:x-me:loves>', undef ],
                    ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>' ] );
    is ($model->size, 2, 'deleted (wildcard): model of 2');

    $model->disband;
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->replace (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		     ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	             );

    my @ss = $model->match ([undef, undef, '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found kitty');
    map { is ($_->[2], '<urn:x-me:kitty>', 'kitty!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', undef, undef]);
    is (scalar @ss, 4, 'match found sacklpicker');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sacklpicker!') } @ss;

    @ss = $model->match (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>']);
    is (scalar @ss, 2, 'match found exactly two identical');

    @ss = $model->match ([undef, '<urn:x-me:hates>', undef],
			 [undef, '<urn:x-me:loves>', undef]);
    is (scalar @ss, 4, 'match found love and hate');

    $model->disband;
}

if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:tomcat> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 1, 'added N3: 1');

    $model->add ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kitty> .
                  <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:katty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 3, 'added N3: 3');

    $model->replace ('<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
                      <urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .');
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'replaced N3: 2');

    $model->disband;

}

my $file;
END { $AG_SERVER && unlink $file; }

if (DONE) {
    use POSIX qw(tmpnam);
    use IO::File;
    do { $file = tmpnam().".n3";  } until IO::File->new ($file, O_RDWR|O_CREAT|O_EXCL);
    my $fh = IO::File->new ("> $file") || die "so what?";
    print $fh "
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:ketty> .
<urn:x-me:sacklpicker> <urn:x-me:hates> <urn:x-me:kotty> .
";
    $fh->close;

    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER);
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add ('file://'. $file);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2, 'added N3 file: 2');

    $model->replace (('file://'. $file ) x 3);
    is (scalar $model->match (['<urn:x-me:sacklpicker>', undef, undef]), 2*3, 'added N3 file: 2*3');

    $model->disband;
}



if (DONE) {
    my $storage = new RDF::AllegroGraph::Easy ($AG_SERVER); #, AUTHENTICATION => 'sacklpicker:catbert');
    my $model   = $storage->model ('/scratch/catlitter', mode => O_CREAT);

    $model->add (['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:tomcat>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:loves>', '<urn:x-me:katty>'],
		 ['<urn:x-me:sacklpicker>', '<urn:x-me:hates>', '<urn:x-me:kitty>'],
	);

    my @ss = $model->sparql ('SELECT ?s ?p ?o WHERE {?s ?p ?o .}' );
#    warn Dumper \@ss;
    is (scalar @ss, 4, 'query: all triples');
    map { is ($_->[0], '<urn:x-me:sacklpicker>', 'sackelpicker everywhere') } @ss;
    map { is (scalar @$_, 3,                     'triple everywhere')       } @ss;

    @ss = $model->sparql ('SELECT ?thing WHERE { ?cat <urn:x-me:hates> ?thing . }' );
    is (scalar @ss, 2, 'query: all that hate');
    map {  like ($_->[0], qr/<urn:x-me:(kitty|tomcat)>/, 'tomcat/litty everywhere') } @ss;
    map { is (scalar @$_, 1,                 'singleton everywhere')        } @ss;

    $model->disband;
}

# TODO with and w/o authentication


__END__

# prefixes

PREFIXES resolve local/remote
         locally use, smaller uri, let remote resolve

$storage->version

    $model = $storage->model ('name', .... POSIX) NAMESPACES {}



$model->add (s, p, o) # NAMESPACES
$model->add (s, s, s, s, ...)
$model->add (N3);
$model->add (RDF/XML);

$model->text ('rumsti')        # freetext

$model->reindex


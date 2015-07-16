use strict;
use warnings;

use Net::SNMP;
use Data::Dumper;
use Time::Piece;
use JSON;
use LWP::UserAgent;

#################################################################
sub snmpGet{

my $hostip=$_[0];
my $community=$_[1];
my $oid=$_[2];

#snmpGet returns the result of an snmpget of the snmpInformant sysuptime oid
(my $session, my $error) = Net::SNMP->session(Hostname=>$hostip, Community => $community);

	die "session error: $error" unless ($session);

	my $result = $session->get_request($oid);
	
		if(defined $result){
			my %href=%$result;

  			if (defined $href{"$oid"}){
    				unless($href{"$oid"}=~/No Such Object/){
        			my $tmpVar = $href{"$oid"};
 				}
			}
  			else{
         			return ("Uptime unavailable");
			    }
		}	
		else{
			return ("SNMP Polling Timeout");
		    }
		}
####################################
sub timestamp{

my $t=localtime;
my $epoch = $t->epoch;
return $epoch;

}
####################################
sub tsdbPrep{

my $metric = $_[0];
my $timestamp = $_[1];
my $value = $_[2];
my $hostname = $_[3];

my $taghash = {
	host => $hostname
	};

my $json_hash = {
	'metric' => $metric,
	'timestamp' => $timestamp,
	'value' => $value,
	'tags' => $taghash
	};
print Dumper $json_hash;
return $json_hash;
}

##############################
sub tsdbPut{

my $jsonstring= $_[0];
my $endpoint = "\/api\/put";

my $ua = LWP::UserAgent->new;
my $server_endpoint="http://localhost:4242" . $endpoint;

#http request headers 
#
my $req = HTTP::Request->new(POST => $server_endpoint);
$req->header('content-type'=>'application/json');
$req->content($jsonstring);
my $resp = $ua->request($req);
if($resp->is_success){
	my $message = $resp->decoded_content;
	print "Received reply: $message\n";
}
else{
	print "HTTP POST error code: ",$resp->code, "\n";
	print "HTTP POST error message: ", $resp->message, "\n";
}

}

sub getWinCpuProcTime{
#Gets cpu % processor time usage for Windows Servers running SNMP Informant
my $ip= $_[0];
my $hostname=$_[1];
my $community=$_[2];
my $oid='.1.3.6.1.4.1.9600.1.1.5.1.5.6.95.84.111.116.97.108';

my $result=snmpGet($ip,$community,$oid);

my $JSON=tsdbPrep('sys.cpu.percentProcTime',timestamp(),$result,$hostname);

return $JSON;
} 
################################################
#Gets time in seconds since system boot (Requires SNMP Informant)
sub getWinUpTime{

my $ip= $_[0];
my $hostname=$_[1];
my $community=$_[2];
my $oid='.1.3.6.1.4.1.9600.1.1.6.1.0';

my $result=snmpGet($ip,$community,$oid);

my $JSON=tsdbPrep('sys.info.upTime',timestamp(),$result/86400,$hostname);

return $JSON;

}

#####################################################
sub getWinFreeMemKB{

my $ip=$_[0];
my $hostname=$_[1];
my $community=$_[2];
my $oid='.1.3.6.1.4.1.9600.1.1.2.2.0';

my $result=snmpGet($ip,$community,$oid);
my $JSON=tsdbPrep('sys.memory.KBFree',timestamp(),$result,$hostname);

return $JSON;
}
######################################################
sub getWinMemPaging{

my $ip=$_[0];
my $hostname=$_[1];
my $community=$_[2];
my $oid='.1.3.6.1.4.1.9600.1.1.2.10.0';

my $result=snmpGet($ip,$community,$oid);
my $JSON=tsdbPrep('sys.memory.Paging',timestamp(),$result,$hostname);

return $JSON;
}

############################
sub jsonify{


foreach my $ii (@_){


my $JSON=encode_json \%$jsonhash;

}


tsdbPut(jsonify(getWinMemPaging('<ip>','<hostname>','SNMP Community')));


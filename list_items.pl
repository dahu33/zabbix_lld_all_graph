#!/usr/bin/perl
use JSON;


# send json and get result (jsonstr):jsonstr
sub sendjson
{
    #jsonstr
    $jsonstr = $_[0];
    
    # send json to zabbix and get result
    $res = `curl -s -i -X POST -H $header -d '$data' $url`;
    # find start of json
    $i = index($res, "{");
    # get json only
    $res_out = substr($res, $i);
    
    #return
    return $res_out;    
}


# authenticate with zabbix, returns the auth token
sub authenticate
{
    # load auth json
    $data = '{ "jsonrpc": "2.0", "method": "user.authenticate", "params": { "user": "'.$user.'", "password": "'.$password.'" }, "id": 0, "auth": null }';
    # send json
    $res = sendjson($data);    
    
    # decode json
    $dec = decode_json($res);
    # get auth key
    $auth_out = $dec->{"result"};

    #return
    return $auth_out;
}


# get hostgroups from zabbix (auth)
sub gethostgroups
{
    #auth
    $auth_in = $_[0];
    
    # load hostgroups json
    $data = '{ "jsonrpc": "2.0", "method": "hostgroup.get", "params": { "output": "extend", "sortfield": "name" }, "id": 1, "auth": "" }';
    # decode json
    $dec = decode_json($data);
    # set auth
    $dec->{"auth"} = $auth_in;
    # encode back to data
    $data = encode_json($dec);
    
    # send json
    $res = sendjson($data);            
    # decode json
    $dec_out = decode_json($res);    
    
    #return
    return $dec_out
}



# get hosts from zabbix (auth, groupid)
sub gethosts
{
    #auth
    $auth_in = $_[0];
    #groupid
    $groupid_in = $_[1];
    
    # load items json
    $data = '{ "jsonrpc": "2.0", "method": "host.get", "params": { "output": "extend", "sortfield": "name", "selectParentTemplates": "extend", "groupids": [ "" ] }, "id": 2, "auth": "" }';
    # decode json
    $dec = decode_json($data);
    # set auth
    $dec->{"auth"} = $auth_in;
    # set groupid filter (outside filter)
    $dec->{"params"}->{"groupids"}[0] = $groupid_in;
    # encode back to data
    $data = encode_json($dec);

#    print $data."\n\n";

    # send json
    $res = sendjson($data);            
    # decode json
    $dec_out = decode_json($res);    
    
#    print $res."\n\n";
    
    #return
    return $dec_out;
}



# get items from zabbix (auth, hostid)
sub getitems
{
    #auth
    $auth_in = $_[0];
    #hostid
    $hostid_in = $_[1];
    
    # load items json
    $data = '{ "jsonrpc": "2.0", "method": "item.get", "params": { "output": "extend", "sortfield": "name", "filter": { "hostid": "" } }, "id": 1, "auth": "" }';

    # decode json
    $dec = decode_json($data);
    # set auth
    $dec->{"auth"} = $auth_in;
    # set hostid filter
    $dec->{"params"}->{"filter"}->{"hostid"} = $hostid_in;
    # encode back to data
    $data = encode_json($dec);

#    print $dec."\n\n";

    # send json
    $res = sendjson($data);            
    # decode json
    $dec_out = decode_json($res);    
    
#    print $res."\n\n";
    
    #return
    return $dec_out
}


#########
# modify these values accordingly
#########
# only add graphs to hosts linked to this template
$template = "WIN Windows";
# internal
$header = "Content-Type:application/json";
# intenal zabbix url
$url = "http://127.0.0.1/api_jsonrpc.php";
# user
$user = "Admin";
# password
$password = "zabbix";


print "\n";

# authenticate with zabbix
$auth = authenticate();

# get hostgroup list
$hostgroups = gethostgroups($auth);

# each hostgroup in list
foreach $hostgroup(@{$hostgroups->{result}}) {
    # get groupid and name
    $groupid = $hostgroup->{groupid};
    $name = $hostgroup->{name};
        
    # not templates or discovered hosts
    if ((lc($name) ne "templates") && (lc($name) ne "discovered hosts")) {        
	
	# get hosts list
	$hosts = gethosts($auth, $groupid);
	
	# each host in list
	foreach $host(@{$hosts->{result}}) {
	    # get parent templates
	    $templates = $host->{parentTemplates};
	    # match results
	    $templatematch = 0;	    
	    	    
	    # each template in list
	    # filter hosts that do not belong to our template
	    foreach $templatei(@{$templates}) {
		# template name match
		if (lc($templatei->{name}) eq lc($template)) { $templatematch = 1; }
	    }	    
	    
	    # template match
	    if ($templatematch == 1) {
		# get host id and name
		$name = $host->{name};
		$hostid = $host->{hostid};
		
    		# get item list
		$items = getitems($auth, $hostid);
		
		# each item in list
		foreach $item(@{$items->{result}}) {
    		    # get item name
    		    $item_name = $item->{name};
    		    #get item id
    		    $item_id = $item->{itemid};
    		    #get item key
    		    $item_key = $item->{key_};
    		    
    		    #print $item_key."\n";
    		    
    		    if ($item_key !~ /.*{#.*}/) 
    		    {   	
	    		print $item_name." (".$item_id.")"."\n";     		    
	    	    }
	    	    
	    	    
		}
	    }
	}
    }
}

print "\n";

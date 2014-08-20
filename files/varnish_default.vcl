# Redirect to Nginx Backend if not in cache
backend www_back {
    .host = "127.0.0.1";
    .port = "8080";
}
 
backend test_back {
    .host = "127.0.0.1";
    .port = "8090";
}

acl purge {
    "127.0.0.1";
}
 
# vcl_recv is called whenever a request is received 
sub vcl_recv {

# set right backend based on http.host
    set req.http.host = req.http.X-Forwarded-Host;

    if (req.http.host ~ "www.example.com") {set req.backend = www_back;}
    else if (req.http.host ~ "test.example.com") {set req.backend = test_back;}
    else {error 404;}

    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
                req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
 
    if (req.http.X-Real-IP) { 
        set req.http.X-Forwarded-For = req.http.X-Real-IP;
    } else {
        set req.http.X-Forwarded-For = client.ip;
    }
 
# Serve objects up to 2 minutes past their expiry if the backend
# is slow to respond.
    set req.grace = 120s;
 
    if (!req.http.X-Forwarded-Proto) {
        set req.http.X-Forwarded-Proto = "http";
        set req.http.X-Forwarded-Port = "80";
        set req.http.X-Forwarded-Host = req.http.host;
    }
 
 
# This uses the ACL action called "purge". Basically if a request to
# PURGE the cache comes from anywhere other than localhost, ignore it.
    if (req.request == "PURGE") 
    {if (!client.ip ~ purge)
        {error 405 "Not allowed.";}
        return(lookup);}
 
# Pass any requests that Varnish does not understand straight to the backend.
    if (req.request != "GET" && req.request != "HEAD" &&
            req.request != "PUT" && req.request != "POST" &&
            req.request != "TRACE" && req.request != "OPTIONS" &&
            req.request != "DELETE") 
    {return(pipe);}     /* Non-RFC2616 or CONNECT which is weird. */
 
# Pass anything other than GET and HEAD directly.
    if (req.request != "GET" && req.request != "HEAD")
    {return(pass);}      /* We only deal with GET and HEAD by default */
 
# Pass requests from logged-in users directly.
    if (req.http.Authorization || req.http.Cookie)
    {return(pass);}      /* Not cacheable by default */
 
# Pass any requests with the "If-None-Match" header directly.
    if (req.http.If-None-Match)
    {return(pass);}
 
# Force lookup if the request is a no-cache request from the client.
    if (req.http.Cache-Control ~ "no-cache")
    {ban_url(req.url);}
    return(lookup);
}
 
sub vcl_pipe {
# This is otherwise not necessary if you do not do any request rewriting.
    set req.http.connection = "close";
}
 
# Called if the cache has a copy of the page.
sub vcl_hit {
    if (req.request == "PURGE") 
    {ban_url(req.url);
        error 200 "Purged";}
 
    if (!obj.ttl > 0s)
    {return(pass);}
}
 
# Called if the cache does not have a copy of the page.
sub vcl_miss {
    if (req.request == "PURGE") 
    {error 200 "Not in cache";}
}
 
# Called after a document has been successfully retrieved from the backend.
sub vcl_fetch {
    set beresp.grace = 120s;
 
    if (beresp.ttl < 48h) {
        set beresp.ttl = 48h;}
 
    if (!beresp.ttl > 0s) 
    {return(hit_for_pass);}
 
    if (beresp.http.Set-Cookie) 
    {return(hit_for_pass);}
 
    if (req.http.Authorization && !beresp.http.Cache-Control ~ "public") 
    {return(hit_for_pass);}
}
 
sub vcl_pass {
    return (pass);
}
 
sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (hash);
}
 
sub vcl_deliver {
    # Debug
    remove resp.http.Via;
    remove resp.http.X-Varnish;
    # Add a header to indicate a cache HIT/MISS
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
        set resp.http.X-Age = resp.http.Age;
        remove resp.http.Age;
    } else {
        set resp.http.X-Cache = "MISS";
    }
    return (deliver);
}
 
sub vcl_error {
    set obj.http.Content-Type = "text/html; charset=utf-8";
    set obj.http.Retry-After = "5";
    synthetic {"
        <?xml version="1.0" encoding="utf-8"?>
            <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
            "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
            <html>
            <head>
            <title>"} + obj.status + " " + obj.response + {"</title>
            </head>
            <body>
            <h1>Error "} + obj.status + " " + obj.response + {"</h1>
            <p>"} + obj.response + {"</p>
            <h3>Guru Meditation:</h3>
            <p>XID: "} + req.xid + {"</p>
            <hr>
            <p>Varnish cache server</p>
            </body>
            </html>
            "};
    return (deliver);
}
 
sub vcl_init {
    return (ok);
}
 
sub vcl_fini {
    return (ok);
}

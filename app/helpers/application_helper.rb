module ApplicationHelper

def access_url_first_filtered(args)
    access_url = access_url_first(args)
    if access_url.present?
        access_url.sub!('http://proxy.library.cornell.edu/login?url=','')
        access_url.sub!('http://encompass.library.cornell.edu/cgi-bin/checkIP.cgi?access=gateway_standard%26url=','')
        return access_url
    end
    nil
end

end

require 'xenapi-ruby'

module Lab
module Controllers
module XenApiController

  # Get vm UUIDs and pull info hashes
  def self.vm_list_all(user,host,pass,running_only=false)
    s = self.get_xapi_session(user,host,pass)
    vms = []
    s.VM.get_all.map do |vref|
      vm = s.VM.get_record(vref)
      next if vm['is_a_template'] or vm['s_a_snapshot'] or vm['name_label'].match(/^Control domain/)
      vms << vm.merge('vmid' => vref)
    end

    return running_only ? vms.keep_if {|v| v['power_state'] == 'Running'} : vms
  end

  # Get SR UUIDs and pull info hashes
  def self.sr_list_all(user,host,pass)
    s = self.get_xapi_session(user,host,pass)
    return s.SR.get_all.map {|srid| s.SR.get_record(srid)}
  end

  # Compat method wrappers

  def self.running_list(user,host,pass)
    self.vm_list_all(user,host,pass,true)
  end

  def self.config_list
  end

  def self.storage_list
  end

  def self.hosts_list
  end

  def self.dir_list
  end

  private

  def self.get_xapi_session(user,host,pass,port=443)
    begin
      # Try SSL with port
      s = XenAPI::Session.new("https://#{host}:#{port}")
      s.login_with_password(user,pass)
    rescue
      # Miserable HTTP on 80 faildown
      s = XenAPI::Session.new("http://#{host}")
      s.login_with_password(user,pass)
      return s
    end
    # If this is somehow nil we will get upstream errors
    return s
  end

end
end
end

# Lets fix XenAPI's inability to deal with self-signed certs
# Its actually an XMLRPC problem, not gem specific.

class ::XenAPI::Session
    def login_with_password(username, password, timeout = 1200,ssl_verify=false)
      begin
        @client = XMLRPC::Client.new2(@uri, nil, timeout)
	if not ssl_verify
	        @client.instance_variable_get(:@http).instance_variable_set(:@verify_mode, OpenSSL::SSL::VERIFY_NONE)
	end
        @session = @client.proxy("session")

        response = @session.login_with_password(username, password)
        raise XenAPI::ErrorFactory.create(*response['ErrorDescription']) unless response['Status'] == 'Success'

        @key = response["Value"]

        #Let's check if it is a working master. It's a small pog due to xen not working as we would like
        self.pool.get_all

        self
      rescue Exception => exc 
        error = XenAPI::ErrorFactory.wrap(exc)
        if @block
          # returns a new session
          @block.call(error)
        else
          raise error
        end 
      end 
    end
end

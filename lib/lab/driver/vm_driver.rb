##
## $Id$
##

#
#   !!WARNING!! - All drivers are expected to filter input before running
#  anything based on it. This is particularly important in the case
#  of the drivers which wrap a command line to provide functionality.
#

module Lab
module Drivers
class VmDriver

  attr_accessor :vmid
  attr_accessor :location
  attr_accessor :os
  attr_accessor :tools
  attr_accessor :credentials

  def initialize(config)

    @vmid = filter_command(config["vmid"].to_s)
    @location = filter_command(config["location"])
    @credentials = config["credentials"] || []
    @tools = filter_input(config["tools"])
    @arch = filter_input(config["arch"])
    @os = filter_input(config["os"])
    @hostname = filter_input(config["hostname"]) || filter_input(config["vmid"].to_s)

    # Currently only implemented for the first set
    if @credentials.count > 0
      @vm_user = filter_input(@credentials[0]['user'])
      @vm_pass = filter_input(@credentials[0]['pass'])
      @vm_keyfile = filter_input(@credentials[0]['keyfile'])
    end
  end

  ## This interface must be implemented in a child driver class
  ## #########################################################

  def register
    raise "Command not Implemented"
  end

  def unregister
    raise "Command not Implemented"
  end

  def start
    raise "Command not Implemented"
  end

  def stop
    raise "Command not Implemented"
  end

  def suspend
    raise "Command not Implemented"
  end

  def pause
    raise "Command not Implemented"
  end

  def resume
    raise "Command not Implemented"
  end

  def reset
    raise "Command not Implemented"
  end

  def create_snapshot(snapshot)
    raise "Command not Implemented"
  end

  def revert_snapshot(snapshot)
    raise "Command not Implemented"
  end

  def delete_snapshot(snapshot)
    raise "Command not Implemented"
  end

  def run_command(command)
    raise "Command not Implemented"
  end

  def copy_from(from, to)
    raise "Command not Implemented"
  end

  def copy_to(from, to)
    raise "Command not Implemented"
  end

  def check_file_exists(file)
    raise "Command not Implemented"
  end

  def create_directory(directory)
    raise "Command not Implemented"
  end

  def cleanup
    raise "Command not Implemented"
  end

  ## End Interface
  ## #########################################################

private

  # The only reason we don't filter here is because we need
  # the ability to still run clean (controlled entirely by us)
  # command lines.
  def system_command(command)
    puts "DEBUG: system command #{command}"
    system(command)
  end

  def remote_system_command(command)
    puts "DEBUG: remote system command #{command} running with user #{@user}@#{@host}"
    system_command("ssh #{@user}@#{@host} \"#{command}\"")
  end

  def scp_to(local,remote)
    if @vm_keyfile
      #puts "DEBUG: authenticating to #{@hostname} as #{@vm_user} with key #{@vm_keyfile}"
      Net::SCP.start(@hostname, @vm_user, :keys => [@vm_keyfile]) do |scp|
        puts "DEBUG: uploading #{local} to #{remote}"
        scp.upload!(local,remote)
      end
    else
      Net::SCP.start(@hostname, @vm_user, :password => @vm_pass, :auth_methods => ["password"]) do |scp|
        puts "DEBUG: uploading #{local} to #{remote}"
        scp.upload!(local,remote)
      end
    end
  end

  def scp_from(remote, local)
    # download a file from a remote server
    if @vm_keyfile
      #puts "DEBUG: authenticating to #{@hostname} as #{@vm_user} with key #{@vm_keyfile}"
      Net::SCP.start(@hostname, @vm_user, :keys => [@vm_keyfile]) do |scp|
        puts "DEBUG: downloading #{remote} to #{local}"
        scp.download!(remote,local)
      end
    else
      Net::SCP.start(@hostname, @vm_user, :password => @vm_pass, :auth_methods => ["password"]) do |scp|
        puts "DEBUG: downloading #{remote} to #{local}"
        scp.download!(remote,local)
      end
    end
  end

  def ssh_exec(command)
    if @vm_keyfile
      #puts "DEBUG: authenticating to #{@hostname} as #{@vm_user} with key #{@vm_keyfile}"
      Net::SSH.start(@hostname, @vm_user, :keys => [@vm_keyfile]) do |ssh|
        puts "DEBUG: running command: #{command}"
        ssh.exec!(command)
      end
    else
      Net::SSH.start(@hostname, @vm_user, :password => @vm_pass, :auth_methods => ["password"]) do |ssh|
        result = ssh.exec!(command)
      end
    end
  end

  def filter_input(string)
    return "" unless string # nil becomes empty string
    return unless string.class == String # Allow other types unmodified

    unless /^[\:\d\w\s\[\]\{\}\/\\\.\-\"\(\):!]*$/.match string
      raise "WARNING! Invalid character in: #{string}"
    end
  string
  end

  def filter_command(string)
    return "" unless string # nil becomes empty string
    return unless string.class == String # Allow other types unmodified

    unless /^[\:\d\w\s\[\]\{\}\/\\\.\-\"\(\)]*$/.match string
      raise "WARNING! Invalid character in: #{string}"
    end
  string
  end

end
end
end

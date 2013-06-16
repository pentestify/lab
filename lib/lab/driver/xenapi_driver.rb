require 'vm_driver'

##
## $Id$
##

# This driver was built against:
# XenServer 6.1 and 6.0.2

module Lab
module Drivers

class XenApiDriver < VmDriver


	def initialize(config)
		unless config['user'] then raise ArgumentError, "Must provide a username" end
		unless config['host'] then raise ArgumentError, "Must provide a hostname" end
		unless config['pass'] then raise ArgumentError, "Must provide a password" end
		super(config)

    # Load XenAPI
    begin
      require 'xenapi-ruby'
    rescue LoadError
      raise "WARNING: Library xenapi-ruby not found. Could not create driver!"
    end

		@user = filter_command(config['user'])
		@host = filter_command(config['host'])
    @pass = config['pass']
    @port = filter_input(config['port']) || nil

		@vm = ensure_xen_session.VM.get_record(@vmid) or fail "VM not found"
	end

	def start
		ensure_xen_session.VM.start @vmid
	end

	def stop
		ensure_xen_session.VM.stop @vmid
	end

	def suspend
		ensure_xen_session.VM.susupend @vmid
	end

	def pause
		ensure_xen_session.VM.pause @vmid
	end

	def resume
		ensure_xen_session.VM.resume @vmid
	end

	def reset
		ensure_xen_session.VM.power_state_reset @vmid
	end

	def create_snapshot(snapshot)
		snapshot = filter_input(snapshot)
		begin
			snap_res = ensure_xen_session.VM.snapshot_with_quiesce(@vmid,snapshot)
		rescue
			snap_res = ensure_xen_session.VM.snapshot(@vmid,snapshot)
		end
		return snap_res
	end

	def revert_snapshot(snapshot)
		snapshot = filter_input(snapshot)
		ensure_xen_session.VM.revert(snapshot)
	end

	def delete_snapshot(snapshot, remove_children=false)
		raise "Unimplemented"
		# If we got here, the snapshot didn't exist
		raise "Invalid Snapshot Name"
	end

	def delete_all_snapshots
		raise "Unimplemented"
	end

	def run_command(command)
		raise "Unimplemented"
	end

	def copy_from(from, to)
		if @os == "linux"
			scp_from(from, to)
		else
			raise "Unimplemented"
		end
	end

	def copy_to(from, to)
		if @os == "linux"
			scp_to(from, to)
		else
			raise "Unimplemented"
		end
	end

	def check_file_exists(file)
		raise "Unimplemented"
	end

	def create_directory(directory)
		raise "Unimplemented"
	end

	def cleanup
		raise "Unimplemented"
	end

	def running?
		raise "Unimplemented"
	end

  def xen_info_hash
    @vm
  end

	def ensure_xen_session
		# HTTP/HTTPS XMLRPC session and auth
		# This block ensures the session lives and we dont keep starting new ones
		begin
			@xen_session.VM.get_all
		rescue
			@xen_session = Lab::Controllers::XenApiController.get_xapi_session(
        @user,
        @host,
        @pass,
        @port
      )
		end
		@xen_session
	end

	# Pass VM.get_all to test
	def raw_api_call(sttring)
		eval "ensure_xen_session.#{string}"
	end

end

end
end

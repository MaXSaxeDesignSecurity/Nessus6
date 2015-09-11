# The Nessus6 module is used to interact with Nessus version 6 servers.
module Nessus6
  # The Scans class is for interacting with Nessus6 scans.
  # https://localhost:8834/api#/resources/scans
  class Scan
    include Nessus6::Verification

    public

    def initialize(client)
      @client = client
    end

    # Copies the given scan. Requires can configure scan permissions
    #
    # @param scan_id [String, Fixnum] The id of the scan to export.
    # @param query_params [Hash] Includes:
    #   :folder_id [String, Fixnum] - The id of the destination folder.
    #   :history [TrueClass, FalseClass, String] - If true, the history for
    #     the scan will be copied
    #   :name [String] - The name of the copied scan
    # @return [Hash]
    def copy(scan_id, query_params = nil)
      if query_params.is_a? Hash
        response = @client.post "scans/#{scan_id}/copy", query_params
      else
        response = @client.post "scans/#{scan_id}/copy"
      end

      verify response,
             not_found: 'Scan does not exist.',
             internal_server_error: 'An error occurred while copying.'
    end

    # Deletes a scan. NOTE: Scans in running, paused or stopping states can not
    # be deleted. This request requires can configure scan permissions
    #
    # @param scan_id [String, Fixnum] The id of the scan to delete.
    # @return [Hash] The scan UUID or throws an error
    def delete(scan_id)
      response = @client.delete "scans/#{scan_id}"
      verify response,
             internal_server_error: 'Failed to delete the scan. This may be ' \
                                    'because the scan is currently running'
    end

    # Deletes historical results from a scan. This request requires can
    # configure scan permissions.
    #
    # @param scan_id [String, Fixnum] The id of the scan.
    # @param query_params [Hash] Includes:
    #   :history_id [String, Fixnum] - The id of the results to delete.
    # @return [Hash] The scan UUID or throws an error
    def delete_history(scan_id, query_params = nil)
      response = @client.delete "scans/#{scan_id}"
      verify response,
             not_found: 'Results were not found.',
             internal_server_error: 'Failed to delete the results.'
    end

    # Returns details for the given scan. This request requires can view
    # scan permissions
    #
    # @param scan_id [String, Fixnum] The id of the scan to retrieve
    # @param history_id [String, Fixnum] The history_id of the historical data
    #   that should be returned.
    # @return [Hash] The scan details
    def details(scan_id, history_id = nil)
      if history_id.nil?
        response = @client.get("scans/#{scan_id}")
      else
        response = @client.get("scans/#{scan_id}", history_id: history_id)
      end
      JSON.parse response.body
    end

    # Launches a scan.
    #
    # @param scan_id [String, Fixnum] The id of the scan to launch.
    # @param alt_targets [Array] If specified, these targets will be scanned
    #   instead of the default. Value can be an array where each index is a
    #   target, or an array with a single index of comma separated targets.
    # @return [Hash] The scan UUID or throws an error
    def launch(scan_id, alt_targets = nil)
      if alt_targets.is_a? Array
        response = @client.post "scans/#{scan_id}/launch",
                                alt_targets: alt_targets
      else
        response = @client.post "scans/#{scan_id}/launch"
      end

      verify response,
             forbidden: 'This scan is disabled.',
             not_found: 'Scan does not exist.',
             internal_server_error: 'Failed to launch scan. This is usually '\
                                    'due to the scan already running.'
    end

    # Returns the scan list.
    #
    # @return [Hash] Returns the scan list.
    def list
      response = @client.get 'scans'
      JSON.parse response.body
    end

    # Pauses a scan.
    #
    # @param scan_id [String, Fixnum] The id of the scan to pause.
    # @return [Hash] The scan UUID or throws an error
    def pause(scan_id)
      response = @client.post "scans/#{scan_id}/pause"
      verify response,
             forbidden: 'This scan is disabled.',
             conflict: 'Scan is not active.'
    end

    # Returns the output for a given plugin
    #
    # @param scan_id [String, Integer] The id of the scan to retrieve
    # @param host_id [String, Integer] The id of the host to retrieve
    # @param plugin_id [String, Integer] The id of the plugin to retrieve
    # @param history_id [String, Integer] The history_id of the historical data
    #   that should be returned
    # @return [Hash] Plugin information object
    def plugin_output(scan_id, host_id, plugin_id, history_id = nil)
      response = @client.get "scans/#{scan_id}/hosts/#{host_id}/plugins/"\
                             "#{plugin_id}", history_id: history_id
      verify response,
             internal_server_error: 'Internal server error'
    end

    # Changes the status of a scan
    #
    # @param scan_id [String, Fixnum] The id of the scan to change
    # @param read [String, Trueclass, Falseclass] If true, the scan has been
    #   read
    # @return [Hash]
    def read_status(scan_id, read)
      response = @client.put "scans/#{scan_id}/status", read: read
      verify response,
             not_found: 'A scan with that ID could not be located.'
    end

    # Resumes a scan
    #
    # @param scan_id [String, Fixnum] The id of the scan to resume
    # @return [Hash]
    def resume(scan_id)
      response = @client.post "scans/#{scan_id}/resume"
      verify response,
             not_found: 'A scan with that ID could not be located',
             conflict: "The scan is not active and / or couldn't be resumed"
    end

    # Enables or disables a scan schedule
    #
    # @param scan_id [String, Fixnum] The id of the scan
    # @param enabled [String, Trueclass, Falseclass] Enables or disables the
    #   scan schedule
    # @return [Hash] With enabled, control, rules, starttime, and timezone
    def schedule(scan_id, enabled)
      response = client.put "scans/#{scan_id}/schedule", enabled: enabled
      verify response,
             not_found: 'A scan with that ID could not be located',
             internal_server_error: 'The scan does not have a schedule enabled'
    end

    # Stops a scan.
    #
    # @param scan_id [String, Fixnum] The id of the scan to stop.
    # @return [Hash] The scan UUID or throws an error
    def stop(scan_id)
      response = @client.post "scans/#{scan_id}/stop"
      verify response,
             not_found: 'Scan does not exist.',
             conflict: 'Scan is not active.'
    end

    # Returns the timezone list for creating a scan.
    #
    # @return [Hash] The timezone resource
    def timezones
      response = @client.get 'scans/timezones'
      verify response,
             unauthorized: 'You do not have permission to view timezones',
             internal_server_error: 'Internal server error occurred'
    end
  end
end

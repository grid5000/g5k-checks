class JobManager
  attr_reader :default_options

  def initialize
    @default_options={
      :job_retry_interval => 10,
      :nodes => 1,
      :job_timeout => 60*3,
      :walltime => "00:30:00"
    }
  end

  def add_parser_options(option_parser, options)
    option_parser.separator ""
    option_parser.separator "* Options for the reservation"
    option_parser.on("-t TIMEOUT", "--oar-timeout TIMEOUT", "Time in seconds before considering it is not possible to get the resources needed by this script") do |v|
      options["oar-timeout"] = v.to_i
    end
    option_parser.on("-c MANDATORY", "--cluster MANDATORY", "Cluster to use. Supports a compact notation <site>-<cluster> that is very usefull when run from Jenkins in matrix tests") do |c|
      uncompact=c.split("-")
      if uncompact.size > 1
        options[:site] = uncompact[0]
        options[:cluster] = uncompact[1]
      else
        options[:cluster] = uncompact[0]
      end
    end
    option_parser.on("-s MANDATORY", "--site MANDATORY", "Site to use") do |v|
      options[:site] = v
    end
    option_parser.on("-w MANDATORY", "--walltime MANDATORY", "Time in HH:MM:SS format or in seconds for which resources should by required for the execution of this script") do |v|
      options[:walltime] = v
    end
    option_parser.on("--command MANDATORY", "Command to run when reservation starts. If unspecified, sleep will be run") do |v|
      options[:command] = v
    end
    option_parser.on("-n MANDATORY", "--nodes MANDATORY", Float, "Number of nodes to use") do |v|
      options[:nodes] = v.to_i
    end
    option_parser.on("--job-types ARRAY", Array, "types to use") do |v|
      options[:types] = v
    end
    option_parser.separator ""
    return options
  end

  def get_job(root, logger, options)

    raise "No site to request a job from" if options[:site] == nil

    job_name="Jenkins_Task"
#    if ENV["JOB_NAME"]
#      job_name+=" for job#{ENV["JOB_NAME"]}"
#    end

    walltime=options[:walltime].split(":")
    if walltime.size>1
      if walltime.size>2
        sleep_time=(walltime[0].to_i*60+walltime[1].to_i)*60+walltime[2].to_i
      else
        sleep_time=walltime[0].to_i*60+walltime[1].to_i
      end
    else
      sleep_time=walltime
    end

    job_description={:name => job_name}
    job_description[:command] = "sleep #{sleep_time}"
    job_description[:command] = options[:command] if options[:command] != nil
    job_description[:types] = options[:types] if options[:types] != nil
    job_description[:resources]=["nodes=#{options[:nodes]}", "walltime=#{options[:walltime]}"].join(",")
    job_description[:properties]="cluster='#{options[:cluster]}'" if options[:cluster] != nil

    job = root.sites[:"#{options[:site]}"].jobs.submit(job_description)

    if job.nil?
      logger.error "Cannot submit job described with #{options}"
    else
      job.reload
      logger.info "[#{options[:site]}] Got the following job: #{job.inspect}"
      logger.info "[#{options[:site]}] Waiting for state=running for job ##{job['uid']}..."

      begin
        Timeout.timeout(options["oar-timeout"]) do
          while job.reload['state'] != 'running'
            logger.info "Waiting Reservation for job ##{job['uid']}"
            sleep 10
          end
        end

        logger.info "[#{options[:site]}] Job is running: #{job.inspect}"
      rescue Timeout::Error => e
        retval = 0
        job.delete
        logger.warn "[#{options[:site]}] Reservation Timed Out. Received exception #{e.class.name} : #{e.message}"
        exit retval
      end
    end
    return job
  end

  def delete_job (job)
    #depending on options, job could be kept at the end of the calling script for debugging purposes
    job.delete
  end
end

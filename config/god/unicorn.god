# http://unicorn.bogomips.org/SIGNALS.html
 
rails_env = ENV['RAILS_ENV'] || 'production'
rails_root = ENV['RAILS_ROOT'] or raise "no ENV['RAILS_ROOT'] given"
uid = ENV['UID'] or raise "no ENV['UID'] given"
 
God.watch do |w|
  w.name     = "unicorn_redmine"
  w.group    = "redmine"
  w.uid      = uid

  w.dir      = "#{rails_root}"
  w.interval = 30.seconds
  w.env      = { "RAILS_ENV" => rails_env, "RAILS_ROOT" => rails_root }

  w.pid_file = "#{rails_root}/tmp/pids/unicorn.pid"
  w.log      = "#{rails_root}/log/unicorn.log"
  #w.behavior(:clean_pid_file)

  w.start = "bundle exec unicorn -c #{rails_root}/config/unicorn.conf.rb -E production -D"
  w.stop = "kill -QUIT `cat #{w.pid_file}`"
  w.restart = "kill -USR2 `cat #{w.pid_file}`"
 
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
 
  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end
 
    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end

  w.start_if do |on|
    on.condition(:file_touched) do |c|
      c.path = File.join(ENV['RAILS_ROOT'], 'tmp', 'start.touch')
    end
  end

  w.stop_if do |on|
    on.condition(:file_touched) do |c|
      c.path = File.join(ENV['RAILS_ROOT'], 'tmp', 'stop.touch')
    end
  end
 
  w.transition(:up, :restart) do |on|
    on.condition(:file_touched) do |c|
      c.path = File.join(ENV['RAILS_ROOT'], 'tmp', 'restart.touch')
    end
  end
 
  # lifecycle
  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end


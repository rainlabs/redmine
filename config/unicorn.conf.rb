# Taken from https://gist.github.com/534668
#
# Our own variable where we deploy this app to
require 'bundler'

rails_env = ENV['RAILS_ENV'] || 'production'
current_path = ENV['RAILS_ROOT'] || File.expand_path(File.join(File.dirname(__FILE__), '..'))
shared_bundler_gems_path = Bundler.bundle_path.to_s

# See http://unicorn.bogomips.org/Sandbox.html
# Helps ensure the correct unicorn_rails is used when upgrading with USR2
Unicorn::HttpServer::START_CTX[0] = "#{shared_bundler_gems_path}/bin/unicorn_rails"

# Use at least one worker per core if you're on a dedicated server,
# more will usually help for _short_ waits on databases/caches.
worker_processes 1

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory current_path

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
#listen 3000, :tcp_nopush => true
#listen "#{current_path}/tmp/sockets/unicorn.sock", :backlog => 64
listen "/tmp/redmine.sock", :backlog => 64

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
pid "#{current_path}/tmp/pids/unicorn.pid"

# By default, the Unicorn logger will write to stderr.
# Additionally, some applications/frameworks log to stderr or stdout,
# so prevent them from going to /dev/null when daemonized here:
stderr_path "log/unicorn.stderr.log"
stdout_path "log/unicorn.stdout.log"

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true
GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!

  # The following is only recommended for memory/DB-constrained
  # installations.  It is not needed if your system can house
  # twice as many worker_processes as you have configured.
  #
  # # This allows a new master process to incrementally
  # # phase out the old master process with SIGTTOU to avoid a
  # # thundering herd (especially in the "preload_app false" case)
  # # when doing a transparent upgrade.  The last worker spawned
  # # will then kill off the old master process with a SIGQUIT.
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end

  # # *optionally* throttle the master from forking too quickly by sleeping
  #sleep 1

  #log_env(:before_fork, server)
end

after_fork do |server, worker|
  # worker.user('deployer', 'deployer') if Process.euid == 0

  # per-process listener ports for debugging/admin/migrations
  # addr = "127.0.0.1:#{9293 + worker.nr}"
  # server.listen(addr, :tries => -1, :delay => 5, :tcp_nopush => true)

  # the following is *required* for Rails + "preload_app true",
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)

  # Reconnect memcached
  #Rails.cache.reset
end

before_exec do |server|
  paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR) 
  paths.unshift "#{shared_bundler_gems_path}/bin"
  ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

  ENV['GEM_HOME'] = ENV['GEM_PATH'] = shared_bundler_gems_path
  ENV['BUNDLE_GEMFILE'] = "#{current_path}/Gemfile"
end


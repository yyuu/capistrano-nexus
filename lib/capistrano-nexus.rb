require "capistrano-nexus/version"
require 'uri'

module Capistrano
  module SonatypeNexus
    def self.extended(configuration)
      configuration.load {
        namespace(:deploy) {
          desc("Start Sonatype Nexus.")
          task(:start, :roles => :app, :except => { :no_release => true }) {
            find_and_execute_task("nexus:start")
          }

          desc("Stop Sonatype Nexus.")
          task(:stop, :roles => :app, :except => { :no_release => true }) {
            find_and_execute_task("nexus:stop")
          }

          desc("Restart Sonatype Nexus.")
          task(:restart, :roles => :app, :except => { :no_release => true }) {
            find_and_execute_task("nexus:restart")
          }
        }

        namespace(:nexus) {
          _cset(:nexus_version, "2.2-01")
          _cset(:nexus_archive_uri) { "http://www.sonatype.org/downloads/nexus-#{nexus_version}-bundle.tar.gz" }
          _cset(:nexus_archive_file) { File.join(shared_path, 'tools', 'nexus', File.basename(nexus_archive_uri)) }
          _cset(:nexus_archive_nexus_path) { File.join(shared_path, 'tools', 'nexus', nexus_version, "nexus-#{nexus_version}") }
          _cset(:nexus_archive_sonatype_work_path) { File.join(shared_path, 'tools', 'nexus', nexus_version, "sonatype-work") }
          _cset(:nexus_current_path) { current_path }
          _cset(:nexus_release_path) { release_path }
          _cset(:nexus_release_children, %w(bin conf lib nexus))
          _cset(:nexus_sonatype_work_path) { File.join(shared_path, 'sonatype-work') }

          desc("Setup Sonatype Nexus.")
          task(:setup, :roles => :app, :except => { :no_release => true }) {
            transaction {
              install
            }
          }
          after 'deploy:setup', 'nexus:setup'

          task(:install, :roles => :app, :except => { :no_release => true }) {
            execute = []
            dirs = [ File.dirname(nexus_archive_file), File.dirname(nexus_archive_nexus_path) ].uniq
            execute << "mkdir -p #{dirs.join(' ')}"
            execute << "( test -f #{nexus_archive_file} || wget --no-verbose -O #{nexus_archive_file} #{nexus_archive_uri} )"
            execute << "( test -d #{nexus_archive_nexus_path} || tar xf #{nexus_archive_file} -C #{File.dirname(nexus_archive_nexus_path)} )"
            run(execute.join(' && '))
          }

          desc("Deploy Sonatype Nexus.")
          task(:update, :roles => :app, :except => { :no_release => true }) {
            transaction {
              install
              update_nexus
              update_sonatype_work
            }
          }
          after 'deploy:finalize_update', 'nexus:update'

          task(:update_nexus, :roles => :app, :except => { :no_release => true }) {
            execute = []
            dirs = [ File.dirname(nexus_release_path) ]
            dirs += nexus_release_children.map { |dir| File.join(nexus_release_path, dir) }
            execute << "mkdir -p #{dirs.join(' ')}"

            nexus_release_children.each do |dir|
              execute << "rsync -lrpt #{File.join(nexus_archive_nexus_path, dir)}/* #{File.join(nexus_release_path, dir)}"
            end

            # update log directory
            execute << "rm -rf #{nexus_release_path}/log #{nexus_release_path}/logs"
            execute << "ln -sf #{shared_path}/log #{release_path}/logs"

            run(execute.join(' && '))
          }

          task(:update_sonatype_work, :roles => :app, :except => { :no_release => true }) {
            execute = []
            sonatype_work = File.expand_path("#{nexus_release_path}/../sonatype-work")
            dirs = [ nexus_sonatype_work_path, File.dirname(sonatype_work) ]
            execute << "mkdir -p #{dirs.join(' ')}"
            execute << (<<-EOS).gsub(/\s+/, ' ').strip
              if [ ! -e #{sonatype_work} ] || [ `readlink #{sonatype_work}` != #{nexus_sonatype_work_path} ]; then
                rm -f #{sonatype_work} && ln -sf #{nexus_sonatype_work_path} #{sonatype_work};
              fi
            EOS
            if fetch(:group_writable, true)
              execute << "chmod -R g+w #{nexus_release_path}/bin/jsw" # Nexus writes pid file under ${NEXUS_HOME}/bin/jsw
              execute << "chmod g+w #{nexus_sonatype_work_path}"
            end
            run(execute.join(' && '))
          }

          # original try_runner does not work expectedly with capistrano-2.13.4
          def _try_runner(cmd, options={})
            if fetch(:runner, nil)
              run("#{sudo} -u #{runner} #{cmd}", options)
            else
              run(cmd, options)
            end
          end
  
          desc("Start Sonatype Nexus.")
          task(:start, :roles => :app, :except => { :no_release => true }) {
            _try_runner("sh #{nexus_current_path}/bin/nexus start")
          }
   
          desc("Stop Sonatype Nexus.")
          task(:stop, :roles => :app, :except => { :no_release => true }) {
            _try_runner("sh #{nexus_current_path}/bin/nexus stop")
          }
   
          desc("Restart Sonatype Nexus.")
          task(:restart, :roles => :app, :except => { :no_release => true }) {
            _try_runner("sh #{nexus_current_path}/bin/nexus restart")
          }
        }
      }
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend(Capistrano::SonatypeNexus)
end

# vim:set ft=ruby ts=2 sw=2 :

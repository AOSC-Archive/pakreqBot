task default: %w[run]

task :run do
  Dir.chdir('.') do
    sh "sh start.sh"
  end
end

task :mkconfig do
  Dir.chdir('scripts') do
    ruby "mkconfig.rb"
  end
end

namespace :test do
  task :db do
    Dir.chdir('scripts') do
      ruby "test.rb"
    end
  end
end

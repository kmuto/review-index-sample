desc 'run hook webindex'
task :webindex do
  system('./hook_afterbackmatter-web.rb')
end

# 呼び出しルール追加
CLEAN.include('_RVIDX_*', '_rv_index*')
Rake::Task[WEBROOT].enhance() do
  Rake::Task[:webindex].invoke
end

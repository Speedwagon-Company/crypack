require "yaml"
require "process"

commands_map = {
  "i" => -> handle_install,
  "install" => -> handle_install
} of String => Proc(Nil)

def handle_install()
  content = File.read("shard.yml").split("\n")
  dependencies = ARGV[1..ARGV.size]
  dependencies.each do |dep|
    add_dependency(content,dep.split("/")[1], dep)
  end
  launch_streaming_proccess("shards", ["install"])

  return true
end

def launch_streaming_proccess(command, args, output = :pipe)
  Process.run("shards", args: ["install"], output: :pipe) do |process|
    buffer = Bytes.new(1024)
    while (n = process.output.read(buffer)) > 0
      chunk = String.new(buffer[0, n])
      STDOUT << chunk.gsub('\r', '\n')
      STDOUT.flush
    end
    
  end
end

def add_dependency_header(file_path)
  content = File.read("shard.yml")
  content = content.split("\n") << "dependencies:"
  File.write("shard.yml", content.join("\n"))
end

def add_dependency(content, dep_name, git_name)


  dependency_i = content.index {|str| str == "dependencies:"}
  add_dependency_header("shard.yml") if dependency_i.nil?

  return if dependency_i.nil?

  content.insert(dependency_i+1, "  #{dep_name.sub("crystal-", "")}:") 
  content.insert(dependency_i+2, "    github: #{git_name}")

  File.write("shard.yml", content.join("\n"))
end

module Cpm
  VERSION = "0.1.0"

  ARGV.each_with_index do |arg, index|
    continue = commands_map[arg].call()
    break if !continue
  end
end

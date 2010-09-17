class Dep
  class Dependency
    attr :name
    attr :version
    attr :url

    def initialize(name, version = nil, url = nil)
      @name = name
      @version = version if version && !version.empty?
      @url = url
    end

    def require
      require_vendor || require_gem
    end

    def to_s
      [name, version].compact.join(" ")
    end

  private
    def version_number
      version[/([\d\.]+)$/, 1]
    end

    def vendor_name
      version ? "#{name}-#{version_number}" : name
    end

    def vendor_path
      Dir[lib(vendor_name), lib("#{vendor_name}*"), lib(name)].first
    end

    def require_vendor
      $:.unshift(File.expand_path(vendor_path)) if vendor_path
    end

    def require_gem
      return unless defined?(Gem)

      begin
        gem(*[name, version].compact)
        true
      rescue Gem::LoadError => e
        false
      end
    end

    def lib(name)
      File.join('vendor', name, 'lib')
    end
  end

  include Enumerable

  attr :dependencies

  def initialize(dependencies)
    @dependencies = []
    @missing = []

    dependencies.each_line do |line|
      next unless line =~ /^([\w\-_]+) ?([<~=> \w\.]+)?(?: ([a-z]+:\/\/.+?))?$/
      @dependencies << Dependency.new($1, $2, $3)
    end
  end

  def require
    @dependencies.each do |dep|
      @missing << dep unless dep.require
    end

    if !@missing.empty?
      $stderr.puts "\nMissing dependencies:\n\n"

      @missing.each do |dep|
        $stderr.puts "  #{dep}"
      end

      $stderr.puts "\nRun `dep list` to view missing dependencies or `dep vendor --all` if you want to vendor them.\n\n"
      exit(1)
    end

    $:.unshift File.expand_path("lib")
  end

  def each(&block)
    @dependencies.each(&block)
  end
end

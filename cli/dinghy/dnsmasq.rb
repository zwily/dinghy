require 'tempfile'

require 'dinghy/plist'

class Dnsmasq
  include Plist
  RESOLVER_DIR = Pathname("/etc/resolver")
  RESOLVER_FILE = RESOLVER_DIR.join("docker")

  def up
    unless resolver_configured?
      configure_resolver!
    end
    super
  end

  def plist_name
    "dinghy.dnsmasq.plist"
  end

  def name
    "DNS"
  end

  def status
    if `pgrep dnsmasq`.strip.to_i > 0
      "running"
    else
      "not running"
    end
  end

  def configure_resolver!
    puts "setting up DNS resolution, this will require sudo"
    unless RESOLVER_DIR.directory?
      system!("creating #{RESOLVER_DIR}", "sudo", "mkdir", "-p", RESOLVER_DIR)
    end
    Tempfile.open('dinghy-dnsmasq') do |f|
      f.write(resolver_contents)
      f.close
      system!("creating #{RESOLVER_FILE}", "sudo", "cp", f.path, RESOLVER_FILE)
      system!("creating #{RESOLVER_FILE}", "sudo", "chmod", "644", RESOLVER_FILE)
    end
  end

  def resolver_configured?
    RESOLVER_FILE.exist? && File.read(RESOLVER_FILE) == resolver_contents
  end

  def resolver_contents; <<-EOS.gsub(/^    /, '')
    # Generated by dinghy
    nameserver #{HOST_IP}
    port 19322
    EOS
  end
end

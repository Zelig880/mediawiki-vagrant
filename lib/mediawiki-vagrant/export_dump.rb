module MediaWikiVagrant
  class ExportDump < Vagrant.plugin(2, :command)
    def self.synopsis
      'exports MediaWiki content as an XML dump'
    end

    def execute
      if ['-h', '--help'].include? @argv.first
        @env.ui.info 'Usage: vagrant export-dump [-h]'
        return 0
      end
      opts = { extra_args: @argv.unshift('export-mediawiki-dump') }
      with_target_vms(nil, single_target: true) do |vm|
        vm.action :ssh, ssh_opts: opts
      end
    end
  end
end

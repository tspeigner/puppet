require 'puppet/external/nagios'
require 'puppet/external/nagios/base'
require 'puppet/provider/naginator'

module Puppet::Util::NagiosMaker
    # Create a new nagios type, using all of the parameters
    # from the parser.
    def self.create_nagios_type(name)
        name = name.to_sym
        full_name = ("nagios_" + name.to_s).to_sym

        raise(Puppet::DevError, "No nagios type for %s" % name) unless nagtype = Nagios::Base.type(name)

        type = Puppet::Type.newtype(full_name) {}

        type.ensurable

        type.newparam(nagtype.namevar, :namevar => true) do
            desc "The name parameter for Nagios type %s" % nagtype.name
        end

        # We deduplicate the parameters because it makes sense to allow Naginator to have dupes.
        nagtype.parameters.uniq.each do |param|
            next if param == nagtype.namevar

            # We can't turn these parameter names into constants, so at least for now they aren't
            # supported.
            next if param.to_s =~ /^[0-9]/

            type.newproperty(param) do
                desc "Nagios configuration file parameter."
            end
        end

        type.newproperty(:target) do
            desc 'target'

            defaultto do
                resource.class.defaultprovider.default_target
            end
        end

        provider = type.provide(:naginator, :parent => Puppet::Provider::Naginator, :default_target => "/etc/nagios/#{full_name.to_s}.cfg") {}

        type.desc "The Nagios type #{name.to_s}.  This resource type is autogenerated using the
            model developed in Naginator_, and all of the Nagios types are generated using the
            same code and the same library.

            This type generates Nagios configuration statements in Nagios-parseable configuration
            files.  By default, the statements will be added to ``#{provider.default_target}``, but
            you can send them to a different file by setting their ``target`` attribute.

            .. _naginator: http://reductivelabs.com/trac/naginator
        "
    end
end

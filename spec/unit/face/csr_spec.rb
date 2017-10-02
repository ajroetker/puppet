require 'spec_helper'
require 'puppet_spec/files'

require 'puppet/face'

describe Puppet::Face[:csr, '0.1.0'] do
  include PuppetSpec::Files

  let(:csr) { Puppet::Face[:csr, '0.1.0'] }
  let(:certificate) { Puppet::Face[:certificate, '0.0.1'] }
  let(:hostname) { Puppet[:certname] }
  let(:options) { {:ca_location => 'local'} }
  let(:different_hostname) { hostname + 'different' }

  before :each do
    Puppet::SSL::Host.reset
    Puppet[:confdir] = tmpdir('conf')
    Puppet::SSL::CertificateAuthority.stubs(:ca?).returns true

    Puppet::SSL::Host.ca_location = :local

    # We can't cache the CA between tests, because each one has its own SSL dir.
    ca = Puppet::SSL::CertificateAuthority.new
    Puppet::SSL::CertificateAuthority.stubs(:new).returns ca
    Puppet::SSL::CertificateAuthority.stubs(:instance).returns ca
  end

  context "csr" do
    it "initializes agent key pair and saves a CSR" do
      # Because we're the CA, calling `puppet csr generate` will autosign the
      # certificate request
      expect { csr.generate()  }.to_not raise_error
      expect { csr.verify()  }.to_not raise_error
    end
  end

  context "verify" do
    it "verifies an agent has a signed cert" do
      certificate.generate(hostname, options)
      certificate.sign(hostname, options)
      expect { csr.verify() }.to_not raise_error
    end
  end

  context "purge" do
    it "purges correctly" do
      certificate.generate(different_hostname, options)
      certificate.sign(different_hostname, options)
      expect { csr.verify() }.to raise_error(SystemExit)

      expect { csr.purge() }.to_not raise_error

      certificate.generate(hostname, options)
      certificate.sign(hostname, options)
      expect { csr.verify() }.to_not raise_error
    end
  end
end

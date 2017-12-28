require 'spec_helper'
require 'mediawiki-vagrant/environment'

module MediaWikiVagrant
  describe Environment do
    include SpecHelpers::MockEnvironment

    let(:environment) { Environment.new(directory) }
    let(:directory) { '/example' }

    let(:hiera_path) { environment.path('puppet/hieradata/vagrant-managed.yaml') }

    describe '#commit', :fakefs do
      subject { environment.commit }

      context 'where .git/refs/heads/master does not exist' do
        it { is_expected.to be(nil) }
      end

      context 'where .git/refs/heads/master exists' do
        before { mock_files_in(directory, '.git/refs/heads/master' => '123456789abc') }

        it 'should be the first 9 characters of the master ref' do
          expect(subject).to eq('123456789')
        end
      end
    end

    describe '#cancel_reload', :fakefs do
      subject { environment.cancel_reload }

      before { mock_file(environment.path('tmp/RELOAD')) }

      it 'removes the reload trigger' do
        subject
        expect(environment.reload?).to be(false)
      end
    end

    describe '#configure_settings' do
      subject { environment.configure_settings(&block) }

      let(:block) { proc {} }
      let(:settings_path) { Pathname.new('/example/.settings.yaml') }

      it 'delegates to `Settings.configure` with the right path' do
        expect(Settings).to receive(:configure).with(settings_path)
        subject
      end
    end

    describe '#load_settings', :fakefs do
      subject { environment.load_settings(roles) }

      let(:roles) { double(Array) }

      let(:role_settings) { {} }
      let(:settings_path) { Pathname.new('/example/.settings.yaml') }
      let(:settings) { double(Settings) }

      before do
        expect(Settings).to receive(:new).and_return(settings)
        expect(environment).to receive(:role_settings).with(roles).and_return(role_settings)

        allow(settings).to receive(:load).with(settings_path)
        allow(settings).to receive(:combine)
      end

      context 'when the settings file does not exist' do
        it 'returns the settings' do
          expect(subject).to be(settings)
        end
      end

      context 'when the settings file exists' do
        before { mock_file(settings_path) }

        it 'loads it and returns the settings' do
          expect(settings).to receive(:load).with(settings_path)
          expect(subject).to be(settings)
        end

        context 'given roles' do
          let(:role_settings) { { 'foo' => foo_settings, 'bar' => bar_settings } }

          let(:foo_settings) { double(Hash) }
          let(:bar_settings) { double(Hash) }

          it 'combines all role settings with core settings' do
            expect(settings).to receive(:load).with(settings_path).ordered
            expect(settings).to receive(:combine).with(foo_settings).ordered
            expect(settings).to receive(:combine).with(bar_settings).ordered
            expect(subject).to be(settings)
          end
        end
      end
    end

    describe '#hiera_delete', :fakefs do
      subject { environment.hiera_delete(key) }

      let(:key) { 'foo' }

      before do
        mock_file(hiera_path, content: align(<<-end))
          ---
          foo: bar
          baz: qux
        end
      end

      it 'deletes the given hiera entry' do
        subject
        expect(hiera_path.read).to eq(align(<<-end))
          ---
          baz: qux
        end
      end
    end

    describe '#hiera_get', :fakefs do
      subject { environment.hiera_get(key) }

      let(:key) { 'foo' }

      before do
        mock_file(hiera_path, content: align(<<-end))
          ---
          foo: bar
          baz: qux
        end
      end

      it 'should be the value of the given hiera entry' do
        expect(subject).to eq('bar')
      end
    end

    describe '#hiera_set', :fakefs do
      subject { environment.hiera_set(key, value) }

      let(:key) { 'foo' }
      let(:value) { 'quux' }

      before do
        mock_file(hiera_path, content: align(<<-end))
          ---
          foo: bar
          baz: qux
        end
      end

      it 'should set the given hiera entry' do
        subject
        expect(hiera_path.read).to eq(align(<<-end))
          ---
          foo: quux
          baz: qux
        end
      end
    end

    describe '#path' do
      subject { environment.path('sub/path') }

      it { is_expected.to be_a(Pathname) }
      it { is_expected.to eq(Pathname.new('/example/sub/path')) }
    end

    describe '#prune_roles' do
      subject { environment.prune_roles }

      it 'removes any configuration for enabled roles that are no longer available' do
        expect(environment).to receive(:roles_available).and_return(['foo', 'bar'])
        expect(environment).to receive(:roles_enabled).and_return(['foo', 'baz'])
        expect(environment).to receive(:update_roles).with(['foo'])
        subject
      end
    end

    describe '#purge_puppet_created_files', :fakefs do
      subject { environment.purge_puppet_created_files }

      before do
        mock_empty_files_in(
          directory,
          'settings.d/puppet-managed/foo.php',
          'settings.d/puppet-managed/bar.php',
          'settings.d/multiwiki/foo.php',
          'settings.d/wikis/foo/bar.php',
          'vagrant.d/foo.yaml',
          'mediawiki/LocalSettings.php'
        )
      end

      it 'deletes the global puppet managed PHP files' do
        subject
        expect(environment.path('settings.d/puppet-managed')).to exist
        expect(environment.path('settings.d/puppet-managed/foo.php')).to_not exist
        expect(environment.path('settings.d/puppet-managed/bar.php')).to_not exist
      end

      it 'deletes the entire directory of multiwiki settings' do
        subject
        expect(environment.path('settings.d/multiwiki')).to_not exist
      end

      it 'deletes the entire directory of wiki settings' do
        subject
        expect(environment.path('vagrant.d')).to_not exist
      end

      it 'deletes the entire directory of vagrant settings' do
        subject
        expect(environment.path('vagrant.d')).to_not exist
      end

      it 'deletes the MediaWiki LocalSettings.php' do
        subject
        expect(environment.path('mediawiki/LocalSettings.php')).to_not exist
      end
    end

    describe '#reload?', :fakefs do
      subject { environment.reload? }

      context 'where the reload flag file does not exist' do
        it { is_expected.to be(false) }
      end

      context 'where the reload flag file exists' do
        before { mock_file(environment.path('tmp/RELOAD')) }

        it { is_expected.to be(true) }
      end
    end

    describe '#roles_available', :fakefs do
      subject { environment.roles_available }

      before do
        mock_files_in(
          environment.path('puppet/modules/role/manifests'),
          'generic.pp' => 'class role::generic {}',
          'mediawiki.pp' => 'class role::mediawiki {}',
          'labs_initial_content.pp' => 'class role::labs_initial_content {}',
          'foo.pp' => 'class role::foo {}',
          'bar.pp' => 'class role::bar {}',
          'baz.pp' => 'class role::bar {}',
          'blek.pp' => 'class blek {}'
        )
      end

      it 'should be a sorted array of unique and properly defined roles' do
        expect(subject).to eq(['bar', 'foo'])
      end
    end

    describe '#roles_enabled', :fakefs do
      subject { environment.roles_enabled }

      before do
        mock_file(hiera_path, content: align(<<-end))
          ---
          classes:
          - role::foo
          - role::bar
        end
      end

      it 'should be a sorted array of available roles' do
        expect(subject).to eq(['bar', 'foo'])
      end

      context 'when a legacy roles file exists' do
        let(:legacy_path) { environment.path('puppet/manifests/manifests.d/vagrant-managed.pp') }

        before do
          mock_file(legacy_path, content: align(<<-end))
            include role::baz
            include role::qux
          end
        end

        it 'migrates the legacy settings' do
          expect(subject).to eq(['baz', 'qux'])
        end

        it 'removes the legacy file' do
          subject
          expect(legacy_path).to_not exist
        end
      end
    end

    describe '#role_docstring', :fakefs do
      subject { environment.role_docstring(role) }

      let(:role) { 'foo' }
      let(:role_path) { environment.path('puppet/modules/role/manifests/foo.pp') }

      context 'when the role file does not exist' do
        it { is_expected.to be(nil) }
      end

      context 'when the role file exists' do
        before do
          mock_file(role_path, content: align(<<-end))
            # == Class: role::foo
            # Provides some foo
            #
            # A Note.
            #
            class role::foo($bar) {}
          end
        end

        it { is_expected.to be_a(String) }

        it 'should be the comment header without the leading #s' do
          expect(subject).to eq(align(<<-end))
            == Class: role::foo
            Provides some foo

            A Note.

          end
        end
      end
    end

    describe '#role_settings', :fakefs do
      subject { environment.role_settings(roles) }

      before do
        mock_files_in(
          environment.path('puppet/modules/role/settings'),
          'foo.yaml' => align(<<-end),
            ---
            vagrant_ram: 200
          end
          'bar.yaml' => align(<<-end)
            ---
            vagrant_ram: 50
          end
        )
      end

      context 'given no roles' do
        subject { environment.role_settings }

        before do
          expect(environment).to receive(:roles_enabled).and_return(['foo'])
        end

        it 'returns settings for the enabled roles' do
          expect(subject).to eq('foo' => { 'vagrant_ram' => 200 })
        end
      end

      context 'given roles' do
        let(:roles) { ['foo', 'bar'] }

        it 'returns settings for the given roles' do
          expect(subject).to eq(
            'foo' => { 'vagrant_ram' => 200 },
            'bar' => { 'vagrant_ram' => 50 }
          )
        end
      end

      context 'given roles that has no settings' do
        let(:roles) { ['baz'] }

        it 'returns an empty hash' do
          expect(subject).to eq('baz' => {})
        end
      end
    end

    describe '#trigger_reload' do
      subject { environment.trigger_reload }
    end

    describe '#update_roles', :fakefs do
      subject { environment.update_roles(roles) }

      let(:roles) { ['foo', 'bar'] }

      before do
        mock_file(hiera_path, content: align(<<-end))
          ---
          classes:
          - role::baz
          - role::qux
        end
      end

      it 'overwrites the hiera classes with the sorted roles' do
        subject
        expect(hiera_path.read).to eq(align(<<-end))
          ---
          classes:
          - role::bar
          - role::foo
        end
      end
    end

    describe '#trigger_reload', :fakefs do
      subject { environment.trigger_reload }

      before { mock_directory(environment.path) }

      it 'triggers a reload' do
        subject
        expect(environment.reload?).to be(true)
      end
    end

    describe '#update', :fakefs do
      subject { environment.update }

      let(:head_path) { environment.path('.git/FETCH_HEAD') }
      let(:stale) { Time.now - (60 * 60 * 24 * 7) - 1 }

      context 'when HEAD is stale' do
        before do
          mock_file(head_path, mtime: stale)
        end

        it 'performs a `git fetch origin` in the environment directory' do
          expect(environment).to receive(:system).with('git fetch origin', chdir: directory)
          subject
        end

        context 'but the MWV_NO_UPDATE flag is set' do
          before do
            stub_const('ENV', 'MWV_NO_UPDATE' => '1')
          end

          it 'does nothing' do
            expect(environment).to_not receive(:system)
            subject
          end
        end

        context 'but a no-update file exists in the environment directory' do
          before do
            mock_file(environment.path('no-update'))
          end

          it 'does nothing' do
            expect(environment).to_not receive(:system)
            subject
          end
        end
      end

      context 'when HEAD is not stale' do
        before do
          mock_file(head_path, mtime: Time.now)
        end

        it 'does nothing' do
          expect(environment).to_not receive(:system)
          subject
        end
      end
    end

    describe '#valid?' do
      subject { environment.valid? }

      context 'when the environment directory is the project directory' do
        let(:environment) { Environment.new(File.expand_path('../../../../', __FILE__)) }

        it { is_expected.to be(true) }
      end

      context 'when the environment directory is elsewhere' do
        let(:environment) { Environment.new('/') }

        it { is_expected.to be(false) }
      end
    end
  end
end
